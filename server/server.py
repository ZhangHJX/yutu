#!/usr/bin/env python3
"""语图 AI 生图桥接服务 — FastAPI

POST /api/ai/generate
    — 真实 AI 生图（Hugging Face Inference API）
    — 支持匿名调用（HF 官方允许，有频率限制）
    — 失败时如实返回错误，不自动 fallback 到 mock

GET /{path:path}
    — 静态文件服务（前端 SPA，含 .html 自动补全）
"""

import os
import sys
import json
import uuid
import time
import hashlib
import random
import asyncio
import base64
import tempfile
from pathlib import Path
from typing import Optional

import uvicorn
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse, FileResponse
from pydantic import BaseModel
import httpx

# ── 路径 ──────────────────────────────────────────────
ROOT = Path(__file__).resolve().parent.parent  # project root
OUT_DIR = ROOT / "out"
GEN_DIR = OUT_DIR / "generated"
GEN_DIR.mkdir(parents=True, exist_ok=True)

# ── FastAPI ────────────────────────────────────────────
app = FastAPI(title="语图 AI 生图服务")
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_methods=["*"], allow_headers=["*"])

# ── 请求 / 响应 ──────────────────────────────────────
class GenerateRequest(BaseModel):
    prompt: str
    scene: str = "poster"
    style: str = "modern"
    width: int = 390
    height: int = 600

class GenerateResponse(BaseModel):
    ok: bool
    document: Optional[dict] = None
    image_url: Optional[str] = None
    error: Optional[str] = None
    questions: Optional[list[str]] = None
    provider: Optional[str] = None  # "responses-api" | "huggingface"
    debug: Optional[dict] = None


class TemplateGenerateRequest(BaseModel):
    title: str = "支持点歌 // 学歌 // 歌单未完待续"
    songs: list[str] = []
    style: str = "dreamy pastel pink aesthetic, hyper-cute girly style"
    template_id: str = "playlist-poster-111"
    assets: Optional[dict[str, str]] = None
    regenerate_slot: Optional[str] = None


class LayoutMapRequest(BaseModel):
    category: str = "playlist"
    style: str = ""
    title: str = ""
    songs: list[str] = []
    description: str = ""
    followup_round: int = 0
    use_default_layout: bool = True


class LayoutMapResponse(BaseModel):
    ok: bool
    layout_map: Optional[dict] = None
    questions: Optional[list[str]] = None
    error: Optional[str] = None
    provider: Optional[str] = None


class GenerateComponentsRequest(BaseModel):
    layout_map: dict
    style_brief: str = ""


class GenerateComponentsResponse(BaseModel):
    ok: bool
    assets: Optional[dict[str, str]] = None
    error: Optional[str] = None
    provider: Optional[str] = None
    debug: Optional[dict] = None


class AssembleLayoutRequest(BaseModel):
    layout_map: dict
    assets: dict[str, str]
    title: str = ""
    songs: list[str] = []
    description: str = ""


class AssembleLayoutResponse(BaseModel):
    ok: bool
    document: Optional[dict] = None
    preview_url: Optional[str] = None
    error: Optional[str] = None
    provider: Optional[str] = None


class CategoryGenerateRequest(BaseModel):
    category: str = "playlist"
    style: str = ""
    title: str = ""
    songs: list[str] = []
    description: str = ""
    use_default_layout: bool = True
    followup_round: int = 0

# ── OCR 拆分 ──────────────────────────────────────────
class SplitTextRequest(BaseModel):
    image_url: str
    canvas_width: Optional[int] = None
    canvas_height: Optional[int] = None

class SplitTextResponse(BaseModel):
    ok: bool
    text_layers: Optional[list] = None
    error: Optional[str] = None

# ── 视觉平面拆分 ──────────────────────────────────────
class DecomposeAssetsRequest(BaseModel):
    image_url: str
    canvas_width: Optional[int] = None
    canvas_height: Optional[int] = None

class DecomposeAssetsResponse(BaseModel):
    ok: bool
    source: Optional[dict] = None
    layers: Optional[list] = None
    text_candidates: Optional[list] = None
    error: Optional[str] = None

LAYERS_DIR = GEN_DIR / "layers"

_ocr_instance = None

def get_ocr():
    """延迟初始化 PaddleOCR（首次调用时下载模型）"""
    global _ocr_instance
    if _ocr_instance is None:
        from paddleocr import PaddleOCR
        print("[OCR] 首次加载 PaddleOCR 模型...")
        _ocr_instance = PaddleOCR(lang='ch')
        print("[OCR] 模型加载完成")
    return _ocr_instance

# ── .env 加载 ──────────────────────────────────────────
_env_path = Path(__file__).resolve().parent / ".env"
if _env_path.is_file():
    with open(_env_path) as _f:
        for _line in _f:
            _line = _line.strip()
            if _line and not _line.startswith("#") and "=" in _line:
                _k, _v = _line.split("=", 1)
                os.environ.setdefault(_k.strip(), _v.strip())

# ── Provider 配置 ──────────────────────────────────────
# 优先级：Responses API (gpt-image-2 / image_generation tool) > Hugging Face

# Responses API（通过中转站 co.yes.vg / 自定义 base_url）
GPT_IMAGE_API_KEY = os.environ.get("GPT_IMAGE_API_KEY", "")
OPENAI_BASE_URL = os.environ.get("OPENAI_BASE_URL", "https://co.yes.vg/v1")
GPT_MAIN_MODEL = os.environ.get("GPT_MAIN_MODEL", "gpt-5.3-codex")  # 能调 image_generation tool 的主模型
GPT_IMAGE_EDIT_MAX_SIDE = int(os.environ.get("GPT_IMAGE_EDIT_MAX_SIDE", "768"))
ENABLE_MODEL_BACKGROUND_FILL = os.environ.get("ENABLE_MODEL_BACKGROUND_FILL", "1") != "0"


async def try_gpt_image_generate(prompt: str, w: int, h: int, raise_on_error: bool = False) -> Optional[bytes]:
    """Generate image through Responses API image_generation tool."""
    image_bytes, report = await _try_gpt_image_generate_report(prompt, w, h)
    if image_bytes is not None:
        return image_bytes
    if raise_on_error:
        raise RuntimeError(report.get("errorMessage") or "Image generation failed")
    return None


async def _try_gpt_image_generate_report(prompt: str, w: int, h: int) -> tuple[Optional[bytes], dict]:
    started = time.time()
    report = {
        "status": "failed",
        "model": GPT_MAIN_MODEL,
        "width": w,
        "height": h,
        "promptPreview": prompt[:160],
    }
    if not GPT_IMAGE_API_KEY:
        report.update({"errorType": "MissingKey", "errorMessage": "GPT_IMAGE_API_KEY is not set"})
        print("[GPT-Image] Missing GPT_IMAGE_API_KEY")
        return None, report

    url = f"{OPENAI_BASE_URL.rstrip('/')}/responses"
    payload = {
        "model": GPT_MAIN_MODEL,
        "input": prompt,
        "tools": [{"type": "image_generation"}],
        "tool_choice": {"type": "image_generation"},
        "stream": True,
    }
    print(f"[GPT-Image] Request: prompt={prompt[:40]}, url={url}, model={GPT_MAIN_MODEL}")

    try:
        b64, stream_report = await _responses_image_stream(
            url,
            payload,
            {
                "Authorization": f"Bearer {GPT_IMAGE_API_KEY}",
                "Content-Type": "application/json",
            },
        )
        report.update(stream_report)
        report["elapsedMs"] = int((time.time() - started) * 1000)
        if not b64:
            message = f"Missing final image_generation_call: {stream_report}"
            report.update({"errorType": "MissingImageResult", "errorMessage": message})
            print(f"[GPT-Image] {message}")
            return None, report
        print(f"[GPT-Image] Success ({len(b64)} chars base64, events={stream_report.get('eventCount')})")
        report.update({"status": "success"})
        return base64.b64decode(b64), report
    except Exception as e:
        report.update({
            "errorType": type(e).__name__,
            "errorMessage": str(e),
            "elapsedMs": int((time.time() - started) * 1000),
        })
        print(f"[GPT-Image] Exception: {e}")
        return None, report


async def _generate_template_image(slot: str, prompt: str, fallback_color: str, w: int, h: int) -> str:
    image_bytes = await try_gpt_image_generate(prompt, w, h)
    if image_bytes is None:
        from PIL import Image, ImageDraw

        img = Image.new("RGB", (w, h), fallback_color)
        draw = ImageDraw.Draw(img)
        draw.rounded_rectangle((4, 4, w - 5, h - 5), radius=18, outline="#ffffff", width=3)
        image_bytes = _pil_to_png_bytes(img)

    file_id = f"tpl-{slot}-{uuid.uuid4().hex[:8]}"
    path = GEN_DIR / f"{file_id}.png"
    path.write_bytes(image_bytes)
    return f"/generated/{path.name}"


def _pil_to_png_bytes(img) -> bytes:
    import io

    buf = io.BytesIO()
    img.save(buf, format="PNG")
    return buf.getvalue()


TEMPLATE_DIR = ROOT / "templates"
DEFAULT_SONGS = [
    "公主病", "半情歌", "他的猫", "不将就", "月牙湾", "记事本", "小美满", "眉间雪",
    "闹够了没有", "勇气大爆发", "回忆的沙漏", "别找我麻烦", "彩虹的微笑", "但愿人长久",
    "离别开出花", "可惜没如果", "词不达意", "明天你好", "玫瑰窃贼", "天命风流",
    "漠河舞厅", "我好想你", "专属味道", "依然爱你",
]


def _load_template(template_id: str) -> dict:
    path = TEMPLATE_DIR / f"{template_id}.json"
    if not path.is_file():
        raise HTTPException(404, "template not found")
    return json.loads(path.read_text(encoding="utf-8"))


def _slot(template: dict, slot_id: str) -> dict:
    return next(slot for slot in template["slots"] if slot["id"] == slot_id)


def _image_component(run_id: str, slot: dict, content: str, editable: bool = True) -> dict:
    return {
        "id": f"tpl-{slot['id']}-{run_id}",
        "type": "image",
        "x": slot["x"],
        "y": slot["y"],
        "width": slot["w"],
        "height": slot["h"],
        "content": content,
        "editable": editable,
        "editableProperties": [],
        "slot": slot["id"],
        "style": {"assetType": "background" if slot["id"] == "background" else slot["id"], "zIndex": slot["zIndex"]},
    }


def _text_component(run_id: str, slot_id: str, x: int, y: int, w: int, h: int, content: str, style: dict) -> dict:
    return {
        "id": f"tpl-{slot_id}-{run_id}-{uuid.uuid4().hex[:4]}",
        "type": "text",
        "x": x,
        "y": y,
        "width": w,
        "height": h,
        "content": content,
        "editable": True,
        "editableProperties": ["content", "style"],
        "slot": slot_id,
        "style": style,
    }


def _shape_component(run_id: str, slot_id: str, x: int, y: int, w: int, h: int, style: dict) -> dict:
    return {
        "id": f"tpl-{slot_id}-{run_id}-{uuid.uuid4().hex[:4]}",
        "type": "shape",
        "x": x,
        "y": y,
        "width": w,
        "height": h,
        "content": "",
        "editable": True,
        "editableProperties": ["style"],
        "slot": slot_id,
        "style": style,
    }


def _song_columns(songs: list[str]) -> list[str]:
    items = (songs or DEFAULT_SONGS)[:32]
    while len(items) < 24:
        items.extend(DEFAULT_SONGS[: 24 - len(items)])
    columns = [items[i::3] for i in range(3)]
    return [
        "\n".join(f"♡{i * 3 + idx + 1:02d} {song}" for idx, song in enumerate(column))
        for i, column in enumerate(columns)
    ]


def _user_song_columns(songs: list[str]) -> list[str]:
    items = [song.strip() for song in songs if song.strip()][:32]
    columns = [items[i::3] for i in range(3)]
    return [
        "\n".join(f"♡{i * 3 + idx + 1:02d} {song}" for idx, song in enumerate(column))
        for i, column in enumerate(columns)
    ]


def _template_prompts(style: str) -> dict[str, str]:
    style_brief = (
        f"{style}. Dreamy pastel pink, warm cozy light, soft-focus creamy texture, "
        "high saturation cute AI illustration style. "
        "Do not generate readable text, labels, logos, letters, numbers, or a complete poster. "
        "The asset must fit inside its slot."
    )
    return {
        "background": (
            f"{style_brief} Generate only the full poster background: warm pink bedroom, "
            "soft glowing light, sparkling stars and heart-shaped bokeh, pink balloons and ribbons. "
            "Include cute bottom decorations: plush rabbit, heart pillow, heart-shaped mug, vintage heart radio, "
            "fresh strawberries and pink petals on a checkered tablecloth. Leave clean space for text and cards."
        ),
        "girl": (
            f"{style_brief} Generate a rectangular left-side character illustration: beautiful young East Asian girl, "
            "long wavy dark brown hair, pink bow headband, pink heart headphones, pink blush, pink off-shoulder knit top, "
            "resting chin on hand, sweet gentle smile. No text. Simple pastel background."
        ),
        "player": (
            f"{style_brief} Generate only a cute rounded-corner pink music player UI skin/backplate. "
            "Include blank cover art area, pink progress bar track, heart slider, blank button circles, soft highlights. "
            "No readable text, no song title, no time numbers."
        ),
        "playlist": (
            f"{style_brief} Generate only a white rounded-corner playlist panel skin/backplate with pink border. "
            "Include subtle three-column guides and small pink heart bullet decorations. "
            "No readable text, no song names, no numbers."
        ),
    }


def _compose_template_preview(template: dict, components: list[dict], run_id: str) -> str:
    from PIL import Image, ImageDraw, ImageFont

    canvas = template["canvas"]
    img = Image.new("RGB", (canvas["width"], canvas["height"]), canvas["background"])
    draw = ImageDraw.Draw(img)

    for comp in sorted(components, key=lambda c: int(c.get("style", {}).get("zIndex", 0))):
        if comp["type"] == "image" and comp["content"].startswith("/generated/"):
            src_path = GEN_DIR / Path(comp["content"]).name
            if src_path.is_file():
                src = Image.open(src_path).convert("RGBA").resize((int(comp["width"]), int(comp["height"])))
                img.paste(src, (int(comp["x"]), int(comp["y"])), src)
        elif comp["type"] == "shape":
            style = comp["style"]
            fill = style.get("fill", "#ff8dbd")
            radius = int(style.get("borderRadius", 10))
            draw.rounded_rectangle(
                (comp["x"], comp["y"], comp["x"] + comp["width"], comp["y"] + comp["height"]),
                radius=radius,
                fill=fill,
            )
        elif comp["type"] == "text":
            font_size = int(comp["style"].get("fontSize", 12))
            color = comp["style"].get("color", "#d95b9f")
            try:
                font = ImageFont.truetype("arial.ttf", font_size)
            except Exception:
                font = ImageFont.load_default()
            draw.multiline_text((comp["x"], comp["y"]), comp["content"], fill=color, font=font, spacing=2)

    filename = f"tpl-preview-{run_id}.png"
    path = GEN_DIR / filename
    img.save(path)
    return f"/generated/{filename}"


PLAYLIST_CONTEXT_PATH = ROOT / "docs" / "prd-workspace" / "template-composition" / "playlist-category-context.md"


def _read_playlist_context() -> str:
    return PLAYLIST_CONTEXT_PATH.read_text(encoding="utf-8")


def _extract_json_object(text: str) -> dict:
    stripped = text.strip()
    if stripped.startswith("```"):
        stripped = stripped.strip("`")
        if stripped.startswith("json"):
            stripped = stripped[4:].strip()
    start = stripped.find("{")
    end = stripped.rfind("}")
    if start < 0 or end < start:
        raise ValueError("layout map response did not contain a JSON object")
    return json.loads(stripped[start:end + 1])


def _response_text(data: dict) -> str:
    if data.get("output_text"):
        return str(data["output_text"])
    parts = []
    for item in data.get("output", []):
        for content in item.get("content", []):
            if isinstance(content, dict):
                text = content.get("text")
                if text:
                    parts.append(text)
    return "\n".join(parts)


async def _responses_text(prompt: str) -> str:
    if not GPT_IMAGE_API_KEY:
        raise RuntimeError("GPT_IMAGE_API_KEY is not set")

    url = f"{OPENAI_BASE_URL.rstrip('/')}/responses"
    payload = {
        "model": GPT_MAIN_MODEL,
        "input": prompt,
    }
    headers = {
        "Authorization": f"Bearer {GPT_IMAGE_API_KEY}",
        "Content-Type": "application/json",
    }
    async with httpx.AsyncClient(timeout=90.0) as client:
        resp = await client.post(url, json=payload, headers=headers)
    if resp.status_code != 200:
        raise RuntimeError(f"HTTP {resp.status_code}: {resp.text[:300]}")
    text = _response_text(resp.json())
    if not text.strip():
        raise RuntimeError("Responses API returned empty text")
    return text


def _layout_prompt(req: LayoutMapRequest, context: str) -> str:
    title_len = len(req.title.strip())
    song_count = len([song for song in req.songs if song.strip()])
    description = req.description.strip() or "No extra description."
    style = req.style.strip() or "model decides a suitable visual style from the playlist category."
    return f"""
You are designing an editable image-material layout map for a design software.

Category knowledge base:
{context}

User request summary:
- category: {req.category}
- style: {style}
- title_length: {title_len}
- song_count: {song_count}
- has_description: {bool(req.description.strip())}
- description: {description}
- use_default_layout: {req.use_default_layout}

Return only valid JSON. Do not include markdown.

Rules:
1. Demo category is playlist only.
2. Generate a dynamic layout map, not a fixed template.
3. Use a 390x600 canvas unless the category strongly requires another size.
4. User text must not be placed in image prompts. Text layers use contentSource such as user.title, user.songs, user.description.
5. Image component prompts must ask for clean blank/readable areas where text layers will be placed.
6. Text layers must include full editable style: fontFamily, fontSize, fontWeight, color, textAlign, lineHeight, letterSpacing, rotation, opacity.
7. Use no Fabric fallback; image components are real generated assets.
8. If the input is underspecified and use_default_layout is true, choose a conservative playlist layout yourself.

Required JSON shape:
{{
  "category": "playlist",
  "canvas": {{"width": 390, "height": 600, "background": "#hex"}},
  "layoutPattern": "title-visual-list | split | floating-card | collage",
  "components": [
    {{
      "id": "background",
      "type": "image",
      "x": 0,
      "y": 0,
      "width": 390,
      "height": 600,
      "zIndex": 0,
      "prompt": "component visual prompt without user text"
    }}
  ],
  "textLayers": [
    {{
      "id": "playlist-title",
      "role": "title",
      "contentSource": "user.title",
      "x": 24,
      "y": 32,
      "width": 342,
      "height": 48,
      "zIndex": 50,
      "style": {{
        "fontFamily": "system",
        "fontSize": 30,
        "fontWeight": "bold",
        "color": "#ffffff",
        "textAlign": "center",
        "lineHeight": 1.1,
        "letterSpacing": 0,
        "rotation": 0,
        "opacity": 1
      }}
    }}
  ]
}}
""".strip()


def _validate_layout_map(layout_map: dict) -> list[str]:
    errors = []
    canvas = layout_map.get("canvas")
    if not isinstance(canvas, dict):
        errors.append("canvas_missing")
        return errors
    canvas_w = canvas.get("width")
    canvas_h = canvas.get("height")
    if not isinstance(canvas_w, int) or not isinstance(canvas_h, int) or canvas_w <= 0 or canvas_h <= 0:
        errors.append("canvas_size_invalid")
        return errors

    for collection_name in ("components", "textLayers"):
        items = layout_map.get(collection_name)
        if not isinstance(items, list) or not items:
            errors.append(f"{collection_name}_missing")
            continue
        for index, item in enumerate(items):
            prefix = f"{collection_name}[{index}]"
            for field in ("id", "x", "y", "width", "height", "zIndex"):
                if field not in item:
                    errors.append(f"{prefix}.{field}_missing")
            if all(field in item for field in ("x", "y", "width", "height")):
                x, y, w, h = item["x"], item["y"], item["width"], item["height"]
                if not all(isinstance(v, (int, float)) for v in (x, y, w, h)) or w <= 0 or h <= 0:
                    errors.append(f"{prefix}.bounds_invalid")
                elif x < 0 or y < 0 or x + w > canvas_w or y + h > canvas_h:
                    errors.append(f"{prefix}.bounds_out_of_canvas")
            if collection_name == "components" and not item.get("prompt"):
                errors.append(f"{prefix}.prompt_missing")
            if collection_name == "textLayers":
                style = item.get("style")
                if not isinstance(style, dict):
                    errors.append(f"{prefix}.style_missing")
                    continue
                for field in ("fontFamily", "fontSize", "fontWeight", "color", "textAlign", "lineHeight", "letterSpacing", "rotation", "opacity"):
                    if field not in style:
                        errors.append(f"{prefix}.style.{field}_missing")
                if not item.get("contentSource"):
                    errors.append(f"{prefix}.contentSource_missing")
    return errors


def _layout_component_prompt(component: dict, style_brief: str) -> str:
    base_prompt = str(component["prompt"]).strip()
    style = style_brief.strip() or "Use the visual style implied by the component prompt."
    return (
        f"{style}\n"
        f"Generate only one image asset for component `{component['id']}`.\n"
        f"Slot size: {int(component['width'])}x{int(component['height'])} pixels.\n"
        f"Component prompt: {base_prompt}\n"
        "Hard constraints: do not generate a complete poster, do not add readable text, "
        "letters, numbers, labels, logos, watermarks, captions, or user-provided words. "
        "Leave clean blank areas for later editable text layers when the prompt mentions text space. "
        "The asset must fit inside its slot and should not include extra borders outside the requested design."
    )


class ComponentGenerationError(RuntimeError):
    def __init__(self, component_id: str, attempts: list[dict]):
        self.component_id = component_id
        self.attempts = attempts
        last = attempts[-1] if attempts else {}
        reason = last.get("errorMessage") or last.get("errorType") or "unknown error"
        super().__init__(f"{component_id} generation failed: {reason}")


def _validate_generated_image(path: Path) -> dict:
    from PIL import Image

    if not path.is_file():
        return {"ok": False, "errorType": "MissingFile", "errorMessage": f"Generated file does not exist: {path.name}"}
    try:
        with Image.open(path) as img:
            img.verify()
            width, height = img.size
        if width <= 0 or height <= 0:
            return {"ok": False, "errorType": "InvalidSize", "errorMessage": f"Invalid image size: {width}x{height}"}
        return {"ok": True, "width": width, "height": height}
    except Exception as e:
        return {"ok": False, "errorType": type(e).__name__, "errorMessage": str(e)}


def _category_attempt_log(component_id: str, attempt: dict):
    print(
        "[CategoryGenerate] "
        f"component={component_id} "
        f"attempt={attempt.get('attempt')} "
        f"status={attempt.get('status')} "
        f"model={attempt.get('model')} "
        f"elapsedMs={attempt.get('elapsedMs')} "
        f"errorType={attempt.get('errorType')} "
        f"error={str(attempt.get('errorMessage') or '')[:500]}",
        flush=True,
    )


async def _generate_layout_component_with_retry(component: dict, style_brief: str) -> tuple[str, list[dict]]:
    component_id = str(component["id"])
    w = int(component["width"])
    h = int(component["height"])
    prompt = _layout_component_prompt(component, style_brief)
    attempts = []

    for attempt_no in (1, 2):
        image_bytes, report = await _try_gpt_image_generate_report(prompt, w, h)
        attempt = {"componentId": component_id, "attempt": attempt_no, **report}

        if image_bytes is not None:
            safe_id = "".join(ch if ch.isalnum() or ch in "-_" else "-" for ch in component_id).strip("-") or "component"
            path = GEN_DIR / f"layout-{safe_id}-{uuid.uuid4().hex[:8]}.png"
            path.write_bytes(image_bytes)
            validation = _validate_generated_image(path)
            attempt["fileValidation"] = validation
            if validation.get("ok"):
                attempt.update({"status": "success", "outputPath": f"/generated/{path.name}"})
                attempts.append(attempt)
                _category_attempt_log(component_id, attempt)
                return f"/generated/{path.name}", attempts
            attempt.update({
                "status": "failed",
                "errorType": validation.get("errorType"),
                "errorMessage": validation.get("errorMessage"),
                "outputPath": f"/generated/{path.name}",
            })

        attempts.append(attempt)
        _category_attempt_log(component_id, attempt)
        if attempt_no == 1:
            await asyncio.sleep(1)

    raise ComponentGenerationError(component_id, attempts)


async def _generate_layout_components(layout_map: dict, style_brief: str = "") -> dict[str, str]:
    errors = _validate_layout_map(layout_map)
    if errors:
        raise RuntimeError("Invalid layout map: " + "; ".join(errors))

    image_components = [item for item in layout_map["components"] if item.get("type") == "image"]
    assets = {}
    for index, component in enumerate(image_components, start=1):
        component_id = str(component["id"])
        print(f"[LayoutComponents] generating component {index}/{len(image_components)}: {component_id}", flush=True)
        asset_url, _attempts = await _generate_layout_component_with_retry(component, style_brief)
        assets[component_id] = asset_url
        if index < len(image_components):
            await asyncio.sleep(2)
    return assets


def _text_style_with_z(layer: dict) -> dict:
    style = dict(layer["style"])
    style["zIndex"] = layer["zIndex"]
    return style


def _layout_image_component(run_id: str, item: dict, content: str) -> dict:
    style = {"assetType": "background" if item["id"] == "background" else item["id"], "zIndex": item["zIndex"]}
    return {
        "id": f"layout-{item['id']}-{run_id}",
        "type": "image",
        "x": item["x"],
        "y": item["y"],
        "width": item["width"],
        "height": item["height"],
        "content": content,
        "editable": True,
        "editableProperties": [],
        "slot": item["id"],
        "style": style,
    }


def _layout_text_component(run_id: str, item: dict, content: str, suffix: str = "") -> dict:
    style = _text_style_with_z(item)
    component = {
        "id": f"layout-{item['id']}{suffix}-{run_id}",
        "type": "text",
        "x": item["x"],
        "y": item["y"],
        "width": item["width"],
        "height": item["height"],
        "content": content,
        "editable": True,
        "editableProperties": ["content", "style"],
        "slot": item["id"],
        "rotation": style["rotation"],
        "opacity": style["opacity"],
        "style": style,
    }
    return component


def _text_components_from_layer(run_id: str, layer: dict, user_inputs: dict) -> list[dict]:
    source = layer["contentSource"]
    if source == "user.title":
        return [_layout_text_component(run_id, layer, user_inputs.get("title", ""))]
    if source == "user.description":
        return [_layout_text_component(run_id, layer, user_inputs.get("description", ""))]
    if source == "user.songs":
        columns = _user_song_columns(user_inputs.get("songs", []))
        if not columns:
            return [_layout_text_component(run_id, layer, "")]
        gap = 6
        col_w = (layer["width"] - gap * 2) / 3
        components = []
        for index, content in enumerate(columns):
            col_layer = dict(layer)
            col_layer["id"] = f"{layer['id']}-col-{index + 1}"
            col_layer["x"] = layer["x"] + index * (col_w + gap)
            col_layer["width"] = col_w
            components.append(_layout_text_component(run_id, col_layer, content))
        return components
    return [_layout_text_component(run_id, layer, "")]


def _assemble_design_document(layout_map: dict, assets: dict[str, str], user_inputs: dict) -> dict:
    errors = _validate_layout_map(layout_map)
    if errors:
        raise RuntimeError("Invalid layout map: " + "; ".join(errors))

    run_id = uuid.uuid4().hex[:10]
    components = []
    for item in layout_map["components"]:
        if item.get("type") != "image":
            continue
        component_id = str(item["id"])
        if not assets.get(component_id):
            raise RuntimeError(f"Missing generated asset for component: {component_id}")
        components.append(_layout_image_component(run_id, item, assets[component_id]))

    max_image_z = max((int(comp.get("style", {}).get("zIndex", 0)) for comp in components), default=0)
    text_z = max_image_z + 100
    for layer in layout_map["textLayers"]:
        text_components = _text_components_from_layer(run_id, layer, user_inputs)
        for comp in text_components:
            comp["style"]["zIndex"] = text_z
            text_z += 1
        components.extend(text_components)

    components.sort(key=lambda comp: int(comp.get("style", {}).get("zIndex", 0)))
    return {
        "version": 1,
        "canvas": layout_map["canvas"],
        "components": components,
        "meta": {
            "name": f"Layout: {layout_map.get('category', 'custom')}",
            "scene": "custom",
            "tags": ["ai", "layout-map", str(layout_map.get("category", "custom"))],
            "createdAt": time.strftime("%Y-%m-%dT%H:%M:%S.000Z", time.gmtime()),
            "skipAutoSplit": True,
        },
    }


def _find_cjk_font(size: int):
    from PIL import ImageFont

    candidates = [
        r"C:\Windows\Fonts\msyh.ttc",
        r"C:\Windows\Fonts\simhei.ttf",
        "/System/Library/Fonts/PingFang.ttc",
        "/System/Library/Fonts/STHeiti Light.ttc",
        "/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc",
        "/usr/share/fonts/truetype/noto/NotoSansCJK-Regular.ttc",
    ]
    for path in candidates:
        if Path(path).is_file():
            return ImageFont.truetype(path, size)
    return ImageFont.load_default()


def _draw_preview_text(base, comp: dict):
    from PIL import Image, ImageDraw

    style = comp["style"]
    font_size = int(style.get("fontSize", 12))
    line_height = float(style.get("lineHeight", 1.2))
    opacity = float(style.get("opacity", 1))
    font = _find_cjk_font(font_size)
    text_layer = Image.new("RGBA", (int(comp["width"]), int(comp["height"])), (255, 255, 255, 0))
    draw = ImageDraw.Draw(text_layer)
    align = style.get("textAlign", "left")
    y = 0
    for line in comp["content"].splitlines() or [""]:
        bbox = draw.textbbox((0, 0), line, font=font)
        line_w = bbox[2] - bbox[0]
        if align == "center":
            x = max(0, (int(comp["width"]) - line_w) / 2)
        elif align == "right":
            x = max(0, int(comp["width"]) - line_w)
        else:
            x = 0
        draw.text((x, y), line, fill=style.get("color", "#000000"), font=font)
        y += max(font_size, int(font_size * line_height))
    if opacity < 1:
        alpha = text_layer.getchannel("A").point(lambda p: int(p * opacity))
        text_layer.putalpha(alpha)
    rotation = float(comp.get("rotation") or 0)
    if rotation:
        text_layer = text_layer.rotate(-rotation, expand=True, resample=Image.Resampling.BICUBIC)
    base.paste(text_layer, (int(comp["x"]), int(comp["y"])), text_layer)


def _compose_layout_preview(document: dict) -> str:
    from PIL import Image

    canvas = document["canvas"]
    img = Image.new("RGB", (int(canvas["width"]), int(canvas["height"])), canvas.get("background", "#ffffff"))
    for comp in sorted(document["components"], key=lambda c: int(c.get("style", {}).get("zIndex", 0))):
        if comp["type"] == "image" and comp["content"].startswith("/generated/"):
            src_path = GEN_DIR / Path(comp["content"]).name
            if src_path.is_file():
                src = Image.open(src_path).convert("RGBA").resize((int(comp["width"]), int(comp["height"])))
                img.paste(src, (int(comp["x"]), int(comp["y"])), src)
        elif comp["type"] == "text":
            _draw_preview_text(img, comp)

    filename = f"layout-preview-{uuid.uuid4().hex[:10]}.png"
    path = GEN_DIR / filename
    img.save(path)
    return f"/generated/{filename}"

# Hugging Face（备选）
HF_TOKEN = os.environ.get("HF_TOKEN", "")
HF_MODELS = [
    "stabilityai/stable-diffusion-xl-base-1.0",
    "black-forest-labs/FLUX.1-schnell",
    "runwayml/stable-diffusion-v1-5",
]

async def try_hf_generate(prompt: str, w: int, h: int) -> Optional[bytes]:
    """调用 HF Inference API 生图，依次尝试多个模型"""
    headers = {"Content-Type": "application/json"}
    if HF_TOKEN:
        headers["Authorization"] = f"Bearer {HF_TOKEN}"

    # 匿名访问时使用更短的超时
    request_timeout = 30.0 if HF_TOKEN else 15.0

    for model in HF_MODELS:
        url = f"https://api-inference.huggingface.co/models/{model}"
        payload = {"inputs": prompt}
        if "schnell" in model:
            payload["parameters"] = {"num_inference_steps": 4}

        try:
            async with httpx.AsyncClient(timeout=request_timeout) as client:
                resp = await client.post(url, json=payload, headers=headers)

            if resp.status_code == 200:
                print(f"[HF] {model} 成功 ({len(resp.content)} bytes)")
                return resp.content
            elif resp.status_code == 503:
                print(f"[HF] {model} 模型加载中 (503)，尝试下一个...")
                continue
            elif resp.status_code == 401 or resp.status_code == 403:
                print(f"[HF] {model} 需要有效 token (收到 {resp.status_code})")
                continue
            else:
                print(f"[HF] {model} 返回错误 {resp.status_code}: {resp.text[:200]}")
                continue
        except httpx.TimeoutException:
            print(f"[HF] {model} 超时 ({request_timeout}s)，尝试下一个...")
            continue
        except Exception as e:
            print(f"[HF] {model} 异常: {e}")
            continue

    return None


# ── 场景组件模板 ──────────────────────────────────────
def _normalize_scene(scene: str) -> str:
    """统一场景名称，支持前端简写"""
    mapping = {"live": "live_decoration"}
    return mapping.get(scene, scene)


def make_components(scene: str, w: int, h: int, prompt: str) -> list:
    """根据场景返回可编辑组件列表（同后端一致）"""
    seed = hashlib.md5(prompt.encode()).hexdigest()
    random.seed(int(seed[:8], 16))

    scene = _normalize_scene(scene)

    if scene == "avatar":
        return [
            {"id": f"av-name-{uuid.uuid4().hex[:6]}", "type": "text", "x": 20, "y": h - 100, "width": w - 40, "height": 30,
             "content": "用户名", "style": {"fontSize": 22, "color": "#FFFFFF", "fontWeight": "bold", "textAlign": "center"}},
            {"id": f"av-bio-{uuid.uuid4().hex[:6]}", "type": "text", "x": 20, "y": h - 65, "width": w - 40, "height": 20,
             "content": "创意设计师", "style": {"fontSize": 13, "color": "#A29BFE", "textAlign": "center"}},
            {"id": f"av-tag-{uuid.uuid4().hex[:6]}", "type": "shape", "x": w//2 - 50, "y": h - 130, "width": 100, "height": 26,
             "style": {"shapeType": "rounded-rect", "fill": "#6C5CE7", "borderRadius": 13}},
            {"id": f"av-tagtxt-{uuid.uuid4().hex[:6]}", "type": "text", "x": w//2 - 40, "y": h - 127, "width": 80, "height": 20,
             "content": "AI 生成", "style": {"fontSize": 11, "color": "#FFFFFF", "textAlign": "center"}},
        ]
    elif scene == "background":
        return [
            {"id": f"bg-title-{uuid.uuid4().hex[:6]}", "type": "text", "x": 30, "y": h//2 - 50, "width": w - 60, "height": 50,
             "content": prompt[:20] if len(prompt) > 20 else prompt, "style": {"fontSize": 24, "color": "#FFFFFF", "fontWeight": "200", "textAlign": "center"}},
            {"id": f"bg-sub-{uuid.uuid4().hex[:6]}", "type": "text", "x": 30, "y": h//2 + 10, "width": w - 60, "height": 20,
             "content": "语图 AI 生成", "style": {"fontSize": 12, "color": "#A29BFE", "textAlign": "center"}},
        ]
    elif scene == "live_decoration":
        return [
            {"id": f"lv-name-{uuid.uuid4().hex[:6]}", "type": "text", "x": 20, "y": 50, "width": w - 40, "height": 40,
             "content": prompt[:15] if len(prompt) > 15 else "直播间", "style": {"fontSize": 26, "color": "#FFFFFF", "fontWeight": "bold", "textAlign": "center"}},
            {"id": f"lv-host-{uuid.uuid4().hex[:6]}", "type": "text", "x": 20, "y": 95, "width": w - 40, "height": 20,
             "content": "主播昵称 · 正在直播", "style": {"fontSize": 13, "color": "#A29BFE", "textAlign": "center"}},
            {"id": f"lv-badge-{uuid.uuid4().hex[:6]}", "type": "shape", "x": w//2 - 45, "y": 140, "width": 90, "height": 24,
             "style": {"shapeType": "rounded-rect", "fill": "#FD79A8", "borderRadius": 12}},
            {"id": f"lv-badgetxt-{uuid.uuid4().hex[:6]}", "type": "text", "x": w//2 - 40, "y": 143, "width": 80, "height": 18,
             "content": "LIVE", "style": {"fontSize": 11, "color": "#FFFFFF", "fontWeight": "bold", "textAlign": "center"}},
        ]
    else:  # poster / default
        return [
            {"id": f"po-title-{uuid.uuid4().hex[:6]}", "type": "text", "x": 30, "y": 80, "width": w - 60, "height": 60,
             "content": prompt[:20] if len(prompt) > 20 else "AI 生成海报", "style": {"fontSize": 32, "color": "#FFFFFF", "fontWeight": "bold", "textAlign": "center"}},
            {"id": f"po-sub-{uuid.uuid4().hex[:6]}", "type": "text", "x": 30, "y": 145, "width": w - 60, "height": 22,
             "content": "输入描述，AI 自动生成", "style": {"fontSize": 14, "color": "#A29BFE", "textAlign": "center"}},
            {"id": f"po-line-{uuid.uuid4().hex[:6]}", "type": "shape", "x": 50, "y": 185, "width": w - 100, "height": 2,
             "style": {"shapeType": "line", "fill": "#6C5CE7"}},
            {"id": f"po-body-{uuid.uuid4().hex[:6]}", "type": "text", "x": 30, "y": 210, "width": w - 60, "height": 100,
             "content": "语图（YuTu）让每个人都能轻松创作精美的设计。AI 生成可编辑的设计稿，直接修改文字、调整颜色。", "style": {"fontSize": 13, "color": "#DFE6E9", "lineHeight": 1.6}},
            {"id": f"po-btn-{uuid.uuid4().hex[:6]}", "type": "shape", "x": w//2 - 70, "y": h - 120, "width": 140, "height": 42,
             "style": {"shapeType": "rounded-rect", "fill": "#6C5CE7", "borderRadius": 21}},
            {"id": f"po-btn-txt-{uuid.uuid4().hex[:6]}", "type": "text", "x": w//2 - 60, "y": h - 112, "width": 120, "height": 24,
             "content": "开始创作", "style": {"fontSize": 14, "color": "#FFFFFF", "fontWeight": "bold", "textAlign": "center"}},
        ]


# ── 主生成接口 ──────────────────────────────────────
def _build_doc(file_id: str, img_url: str, prompt: str, scene: str, w: int, h: int) -> dict:
    """构建干净的 DesignDocument（仅图片组件，无场景文字/形状覆盖）"""
    return {
        "version": 1,
        "canvas": {"width": w, "height": h, "background": "#1a1a2e"},
        "components": [
            {
                "id": f"ai-bg-{file_id}",
                "type": "image",
                "x": 0, "y": 0,
                "width": w, "height": h,
                "content": img_url,
                "editable": True,
                "editableProperties": [],
                "slot": None,
                "style": {},
            },
        ],
        "meta": {
            "name": f"AI: {prompt[:24]}",
            "scene": _normalize_scene(scene),
            "tags": ["ai"],
            "createdAt": time.strftime("%Y-%m-%dT%H:%M:%S.000Z", time.gmtime()),
        },
    }


@app.post("/api/ai/generate", response_model=GenerateResponse)
async def generate(req: GenerateRequest):
    prompt = req.prompt.strip()
    if not prompt:
        raise HTTPException(400, "prompt 不能为空")

    w, h = req.width, req.height

    # 0) 调试测试：prompt == "111" → 直接用本地素材图
    if prompt == "111":
        test_path = GEN_DIR / "source-poster.png"
        if not test_path.is_file():
            return GenerateResponse(ok=False, error="测试素材图 source-poster.png 不存在")
        file_id = "source-poster"
        img_url = f"/generated/{file_id}.png"
        doc = _build_doc(file_id, img_url, "测试素材", req.scene, w, h)
        return GenerateResponse(ok=True, document=doc, image_url=img_url, provider="local")

    image_bytes: Optional[bytes] = None
    provider: Optional[str] = None

    # 1) gpt-image-2（首选）
    if GPT_IMAGE_API_KEY:
        print("[GPT-Image] 开始生成...")
        image_bytes = await try_gpt_image_generate(prompt, w, h)
        if image_bytes:
            provider = "responses-api"
            print(f"[OK] gpt-image-2 生图成功 ({len(image_bytes)} bytes)")
        else:
            print("[GPT-Image] 生成失败")

    # 2) Hugging Face（备选）
    if image_bytes is None and HF_TOKEN:
        print("[HF] 开始生成...")
        image_bytes = await try_hf_generate(prompt, w, h)
        if image_bytes:
            provider = "huggingface"
            print(f"[OK] HF 生图成功 ({len(image_bytes)} bytes)")
        else:
            print("[HF] HF 生成失败")

    # 3) 全部失败
    if image_bytes is None:
        parts = []
        if not GPT_IMAGE_API_KEY and not HF_TOKEN:
            parts.append("未配置任何 API Key（需设置 GPT_IMAGE_API_KEY 或 HF_TOKEN）")
        else:
            if GPT_IMAGE_API_KEY:
                parts.append("gpt-image-2 生成失败")
            if HF_TOKEN:
                parts.append("Hugging Face 生成失败")
            else:
                parts.append("未设置 HF_TOKEN 作为备选")
        return GenerateResponse(ok=False, error="AI 生成失败：" + "；".join(parts) + "。")

    # 保存图片
    file_id = uuid.uuid4().hex[:12]
    filename = f"{file_id}.png"
    filepath = GEN_DIR / filename
    with open(filepath, "wb") as f:
        f.write(image_bytes)

    img_url = f"/generated/{filename}"

    # 构建干净的 DesignDocument（仅 AI 图片，不叠加场景文字/形状组件）
    doc = _build_doc(file_id, img_url, prompt, req.scene, w, h)

    return GenerateResponse(
        ok=True,
        document=doc,
        image_url=img_url,
        provider=provider,
    )


@app.post("/api/ai/generate-template", response_model=GenerateResponse)
async def generate_template(req: TemplateGenerateRequest):
    template = _load_template(req.template_id)
    run_id = uuid.uuid4().hex[:10]
    title = req.title.strip() or "支持点歌 // 学歌 // 歌单未完待续"
    songs = [song.strip() for song in req.songs if song.strip()]
    prompts = _template_prompts(req.style.strip() or "dreamy pastel pink aesthetic")
    existing_assets = req.assets or {}

    slots = {slot["id"]: slot for slot in template["slots"]}
    image_specs = {
        "background": "#ffd6e8",
        "girl": "#ffe1ed",
        "player": "#ffc3dc",
        "playlist": "#fff5fb",
    }
    image_urls = {}
    for slot_id, fallback_color in image_specs.items():
        if existing_assets.get(slot_id) and req.regenerate_slot != slot_id:
            image_urls[slot_id] = existing_assets[slot_id]
            continue
        image_urls[slot_id] = await _generate_template_image(
            slot_id, prompts[slot_id], fallback_color, slots[slot_id]["w"], slots[slot_id]["h"]
        )
    background_url = image_urls["background"]
    girl_url = image_urls["girl"]
    player_url = image_urls["player"]
    playlist_url = image_urls["playlist"]

    components = [
        _image_component(run_id, slots["background"], background_url, editable=False),
        _image_component(run_id, slots["girl"], girl_url),
        _image_component(run_id, slots["player"], player_url),
        _image_component(run_id, slots["playlist"], playlist_url),
    ]

    title_slot = slots["title"]
    components.append(_text_component(run_id, "title", title_slot["x"], title_slot["y"], title_slot["w"], title_slot["h"], title, {
        "fontSize": 20,
        "color": "#ff63a8",
        "fontWeight": "bold",
        "textAlign": "center",
        "lineHeight": 1.05,
        "zIndex": title_slot["zIndex"],
    }))

    components.extend([
        _shape_component(run_id, "player-cover", 212, 74, 44, 44, {
            "shapeType": "rounded-rect", "fill": "#ffe2ef", "borderRadius": 12, "zIndex": 35,
        }),
        _text_component(run_id, "player-cover-heart", 222, 83, 24, 20, "♡", {
            "fontSize": 21, "color": "#ff77b5", "textAlign": "center", "zIndex": 36,
        }),
        _text_component(run_id, "player-title", 266, 82, 86, 28, songs[0] if songs else "公主病", {
            "fontSize": 18, "color": "#ff5fa6", "fontWeight": "bold", "textAlign": "left", "zIndex": 36,
        }),
        _shape_component(run_id, "player-progress", 216, 130, 132, 5, {
            "shapeType": "rounded-rect", "fill": "#ffd1e4", "borderRadius": 3, "zIndex": 35,
        }),
        _shape_component(run_id, "player-progress-active", 216, 130, 52, 5, {
            "shapeType": "rounded-rect", "fill": "#ff7bb9", "borderRadius": 3, "zIndex": 36,
        }),
        _text_component(run_id, "player-times", 214, 139, 138, 12, "01:28                         04:18", {
            "fontSize": 8, "color": "#ff76b2", "textAlign": "left", "zIndex": 36,
        }),
        _text_component(run_id, "player-buttons", 232, 156, 106, 20, "♡   ◀   ▶   ▶   ♡", {
            "fontSize": 13, "color": "#ff68ab", "textAlign": "center", "zIndex": 36,
        }),
    ])

    for index, column in enumerate(_song_columns(songs)):
        components.append(_text_component(run_id, f"playlist-col-{index + 1}", 208 + index * 58, 216, 54, 280, column, {
            "fontSize": 7,
            "color": "#e35f9f",
            "fontWeight": "bold",
            "lineHeight": 1.28,
            "textAlign": "left",
            "zIndex": 36,
        }))

    components.sort(key=lambda comp: int(comp.get("style", {}).get("zIndex", 0)))
    preview_url = _compose_template_preview(template, components, run_id)
    doc = {
        "version": 1,
        "canvas": template["canvas"],
        "components": components,
        "meta": {
            "name": f"Template: {title[:18]}",
            "scene": "poster",
            "tags": ["ai", "template", req.template_id],
            "createdAt": time.strftime("%Y-%m-%dT%H:%M:%S.000Z", time.gmtime()),
            "thumbnail": preview_url,
            "templateRunId": run_id,
            "templateAssets": image_urls,
        },
    }

    return GenerateResponse(ok=True, document=doc, image_url=preview_url, provider="template-composition")


def _playlist_followup_questions(req: LayoutMapRequest) -> list[str]:
    questions = []
    if not req.style.strip():
        questions.append("希望歌单整体是什么风格或情绪？")
    if not req.title.strip():
        questions.append("歌单标题是什么？")
    if not [song for song in req.songs if song.strip()]:
        questions.append("歌单里至少包含哪些歌曲？")
    return questions[:3]


@app.post("/api/ai/generate-layout-map", response_model=LayoutMapResponse)
async def generate_layout_map(req: LayoutMapRequest):
    category = req.category.strip().lower()
    if category != "playlist":
        return LayoutMapResponse(ok=False, error="Only playlist category is enabled in this demo.")

    questions = _playlist_followup_questions(req)
    if questions and not req.use_default_layout and req.followup_round < 3:
        return LayoutMapResponse(ok=True, questions=questions, provider="layout-followup")

    try:
        context = _read_playlist_context()
        prompt = _layout_prompt(req, context)
        text = await _responses_text(prompt)
        layout_map = _extract_json_object(text)
        errors = _validate_layout_map(layout_map)
        if errors:
            return LayoutMapResponse(ok=False, error="Invalid layout map: " + "; ".join(errors), provider="responses-api")
        return LayoutMapResponse(ok=True, layout_map=layout_map, provider="responses-api")
    except Exception as e:
        return LayoutMapResponse(ok=False, error=str(e), provider="responses-api")


@app.post("/api/ai/generate-components", response_model=GenerateComponentsResponse)
async def generate_components(req: GenerateComponentsRequest):
    try:
        assets = await _generate_layout_components(req.layout_map, req.style_brief)
        return GenerateComponentsResponse(ok=True, assets=assets, provider="responses-image-generation")
    except ComponentGenerationError as e:
        return GenerateComponentsResponse(
            ok=False,
            error=f"Component generation failed: {e.component_id}",
            provider="responses-image-generation",
            debug={"failedComponent": e.component_id, "attempts": e.attempts},
        )
    except Exception as e:
        return GenerateComponentsResponse(ok=False, error=str(e), provider="responses-image-generation")


@app.post("/api/ai/assemble-layout", response_model=AssembleLayoutResponse)
async def assemble_layout(req: AssembleLayoutRequest):
    try:
        user_inputs = {"title": req.title, "songs": req.songs, "description": req.description}
        document = _assemble_design_document(req.layout_map, req.assets, user_inputs)
        preview_url = _compose_layout_preview(document)
        document["meta"]["thumbnail"] = preview_url
        return AssembleLayoutResponse(ok=True, document=document, preview_url=preview_url, provider="layout-assembler")
    except Exception as e:
        return AssembleLayoutResponse(ok=False, error=str(e), provider="layout-assembler")


@app.post("/api/ai/generate-category", response_model=GenerateResponse)
async def generate_category(req: CategoryGenerateRequest):
    stage = "init"
    map_req = LayoutMapRequest(
        category=req.category,
        style=req.style,
        title=req.title,
        songs=req.songs,
        description=req.description,
        use_default_layout=req.use_default_layout,
        followup_round=req.followup_round,
    )
    try:
        category = map_req.category.strip().lower()
        if category != "playlist":
            return GenerateResponse(ok=False, error="当前 demo 只支持歌单分类")

        questions = _playlist_followup_questions(map_req)
        if questions and not map_req.use_default_layout and map_req.followup_round < 3:
            return GenerateResponse(ok=True, questions=questions, provider="layout-followup")

        stage = "layout"
        context = _read_playlist_context()
        layout_text = await _responses_text(_layout_prompt(map_req, context))
        layout_map = _extract_json_object(layout_text)
        errors = _validate_layout_map(layout_map)
        if errors:
            return GenerateResponse(ok=False, error="Layout map invalid: " + "; ".join(errors))

        stage = "components"
        assets = await _generate_layout_components(layout_map, req.style)
        stage = "assemble"
        user_inputs = {"title": req.title, "songs": req.songs, "description": req.description}
        document = _assemble_design_document(layout_map, assets, user_inputs)
        preview_url = _compose_layout_preview(document)
        document["meta"]["thumbnail"] = preview_url
        return GenerateResponse(ok=True, document=document, image_url=preview_url, provider="category-composition")
    except ComponentGenerationError as e:
        return GenerateResponse(
            ok=False,
            error=f"{stage}: Component generation failed: {e.component_id}",
            provider="category-composition",
            debug={"stage": stage, "failedComponent": e.component_id, "attempts": e.attempts},
        )
    except Exception as e:
        return GenerateResponse(ok=False, error=f"{stage}: {e}", provider="category-composition")


# ── OCR 文字拆分 ──────────────────────────────────────
@app.post("/api/ai/split-text", response_model=SplitTextResponse)
async def split_text(req: SplitTextRequest):
    """AI 图片文字拆分：输入图片 URL，返回文字区域列表 [{id, text, bbox, confidence}]"""
    image_url = req.image_url.strip()
    canvas_w = req.canvas_width
    canvas_h = req.canvas_height
    if not image_url:
        return SplitTextResponse(ok=False, error="image_url 不能为空")

    # 下载图片到临时文件
    tmp = tempfile.NamedTemporaryFile(delete=False, suffix=".png")
    tmp_path = tmp.name
    try:
        async with httpx.AsyncClient(timeout=30.0, follow_redirects=True) as client:
            resp = await client.get(image_url)
            if resp.status_code != 200:
                return SplitTextResponse(ok=False, error=f"下载图片失败: HTTP {resp.status_code}")
            tmp.write(resp.content)
        tmp.close()
        print(f"[OCR] 图片已下载: {len(resp.content)} bytes → {tmp_path}")

        # 获取原图尺寸，计算坐标缩放比
        orig_w = orig_h = 1
        if canvas_w and canvas_h:
            try:
                from PIL import Image
                with Image.open(tmp_path) as img:
                    orig_w, orig_h = img.size
                print(f"[OCR] 原图尺寸: {orig_w}x{orig_h}, 目标画布: {canvas_w}x{canvas_h}")
            except Exception:
                print(f"[OCR] 无法读取原图尺寸，跳过缩放")
                canvas_w = canvas_h = None

        # 统一缩放比 + letterbox 偏移（匹配前端 object-fit: contain）
        img_aspect = orig_w / orig_h
        container_aspect = canvas_w / canvas_h
        if img_aspect >= container_aspect:
            # 图片更宽：水平撑满，上下留白
            scale = canvas_w / orig_w
            offset_x = 0
            offset_y = (canvas_h - orig_h * scale) / 2
        else:
            # 图片更高：垂直撑满，左右留白
            scale = canvas_h / orig_h
            offset_x = (canvas_w - orig_w * scale) / 2
            offset_y = 0

        # OCR 识别（PaddleOCR 3.5 返回 PaddleX OCRResult 对象）
        loop = asyncio.get_event_loop()
        ocr = get_ocr()
        result = await loop.run_in_executor(None, ocr.ocr, tmp_path)
        print(f"[OCR] 识别完成")

        # 打开原图用于颜色采样
        src_img = None
        if canvas_w and canvas_h:
            try:
                from PIL import Image
                src_img = Image.open(tmp_path).convert("RGB")
            except Exception:
                pass

        text_layers = []
        if result and len(result) > 0:
            ocr_result = result[0]  # PaddleX OCRResult (dict-like)
            texts = ocr_result.get('rec_texts', []) or []
            scores = ocr_result.get('rec_scores', []) or []
            boxes = ocr_result.get('rec_boxes')

            if texts and boxes is not None:
                for idx in range(len(texts)):
                    text = texts[idx]
                    score = scores[idx] if idx < len(scores) else 0.0
                    box = boxes[idx]  # [x1, y1, x2, y2]

                    # 过滤：低置信度跳过
                    if score < 0.8:
                        continue
                    # 过滤：空文本或纯标点符号
                    clean = text.strip()
                    if not clean or len(clean) < 1:
                        continue

                    # 缩放坐标到画布尺寸（统一缩放 + letterbox 偏移）
                    x = round(offset_x + float(box[0]) * scale, 1)
                    y = round(offset_y + float(box[1]) * scale, 1)
                    w = round((float(box[2]) - float(box[0])) * scale, 1)
                    h = round((float(box[3]) - float(box[1])) * scale, 1)

                    # 颜色采样：用 Otsu 阈值分离前景（文字）和背景像素
                    text_color = "#FFFFFF"  # default: 白色
                    if src_img:
                        try:
                            bx1 = max(0, int(float(box[0])))
                            by1 = max(0, int(float(box[1])))
                            bx2 = min(src_img.width, int(float(box[2])))
                            by2 = min(src_img.height, int(float(box[3])))
                            if bx2 > bx1 and by2 > by1:
                                crop = src_img.crop((bx1, by1, bx2, by2))
                                import numpy as np
                                arr = np.array(crop, dtype=np.uint8)
                                gray = np.mean(arr, axis=2).astype(np.uint8)

                                # Otsu 阈值计算
                                hist = np.bincount(gray.ravel(), minlength=256)
                                total = gray.size
                                sum_total = np.dot(np.arange(256), hist.astype(np.float64))
                                sum_b, w_b = 0.0, 0.0
                                var_max, threshold = 0.0, 0
                                for t in range(256):
                                    w_b += hist[t]
                                    if w_b == 0:
                                        continue
                                    w_f = total - w_b
                                    if w_f == 0:
                                        break
                                    sum_b += t * hist[t]
                                    mean_b = sum_b / w_b
                                    mean_f = (sum_total - sum_b) / w_f
                                    var_between = w_b * w_f * (mean_b - mean_f) ** 2
                                    if var_between > var_max:
                                        var_max = var_between
                                        threshold = t

                                # 分离亮/暗像素
                                light = gray > threshold
                                n_light = int(np.sum(light))
                                n_dark = total - n_light

                                # 文字通常是面积较小的那一簇
                                text_mask = gray <= threshold if n_dark < n_light else light
                                if np.sum(text_mask) > 5:
                                    tr = int(np.mean(arr[text_mask, 0]))
                                    tg = int(np.mean(arr[text_mask, 1]))
                                    tb = int(np.mean(arr[text_mask, 2]))
                                    text_color = f"#{tr:02x}{tg:02x}{tb:02x}"
                        except Exception as e:
                            print(f"[OCR] 颜色采样异常: {e}")
                            pass

                    text_layers.append({
                        "id": f"ocr-{uuid.uuid4().hex[:6]}",
                        "text": clean,
                        "bbox": {"x": x, "y": y, "width": w, "height": h},
                        "confidence": round(float(score), 3),
                        "color": text_color,
                    })

        print(f"[OCR] 共识别 {len(text_layers)} 个文字区域")
        return SplitTextResponse(ok=True, text_layers=text_layers)

    except Exception as e:
        import traceback
        traceback.print_exc()
        return SplitTextResponse(ok=False, error=str(e))
    finally:
        if os.path.exists(tmp_path):
            os.unlink(tmp_path)


# ── 视觉平面拆分（按 PSD 思路拆透明 PNG 层） ────────────

def _merge_into_panels(groups):
    """滑动窗口密度检测：找 y 轴最密集的连续组簇，合并为面板"""
    if len(groups) < 6:
        return groups, []

    items = []
    for g in groups:
        if not g:
            continue
        ys = []
        for r in g:
            b = r.get("bounds_canvas", {})
            ys.append(b.get("y", 0) + b.get("height", 0) / 2)
        if not ys:
            continue
        items.append({"group": g, "cy": sum(ys) / len(ys)})

    if len(items) < 6:
        return groups, []
    items.sort(key=lambda x: x["cy"])

    total_h = items[-1]["cy"] - items[0]["cy"]
    max_span = max(total_h * 0.50, 100)  # 窗口最多覆盖 50% 总高度

    # 滑动窗口找最大稠密段
    best_run, best = [], 0
    cur = []
    for it in items:
        # 把 it 加入当前窗口
        cur.append(it)
        # 移除窗口外元素（超出 max_span）
        while cur and it["cy"] - cur[0]["cy"] > max_span:
            cur.pop(0)
        if len(cur) > best:
            best = len(cur)
            best_run = list(cur)

    if best < 5:
        return groups, []

    # 合并 best_run
    panel_ids = {id(it["group"]) for it in best_run}
    remaining, panel_groups = [], []
    for g in groups:
        if id(g) in panel_ids:
            panel_groups.append(g)
        else:
            remaining.append(g)

    # 计算合并 bounds
    xs, ys = [], []
    for g in panel_groups:
        for r in g:
            b = r["bounds_canvas"]
            xs.extend([b["x"], b["x"] + b["width"]])
            ys.extend([b["y"], b["y"] + b["height"]])
    texts, confs = [], []
    for g in panel_groups:
        for r in g:
            texts.append(r["text"])
            confs.append(r["confidence"])
    avg_conf = sum(confs) / len(confs) if confs else 0

    # 子区域
    sub = []
    for g in panel_groups:
        for r in g:
            b = r["bounds_canvas"]
            sub.append({
                "text": r["text"],
                "bounds": b,
                "color": r["color"],
                "fontSize": r["font_size_est"],
                "confidence": r["confidence"],
            })

    merged = {
        "text": " ".join(texts),
        "confidence": round(avg_conf, 3),
        "color": sub[0]["color"] if sub else "#FFFFFF",
        "bounds_canvas": {
            "x": round(min(xs), 1), "y": round(min(ys), 1),
            "width": round(max(xs) - min(xs), 1),
            "height": round(max(ys) - min(ys), 1),
        },
        "sub_regions": sub,
        "textType": "simple" if avg_conf > 0.9 else "artistic",
    }

    remaining.append(merged)
    print(f"[Decompose] 密度合并: {len(panel_groups)} 组合并为面板 (剩 {len(remaining)} 组)")
    return remaining, [merged]


@app.post("/api/ai/decompose-assets", response_model=DecomposeAssetsResponse)
async def decompose_assets(req: DecomposeAssetsRequest):
    """V1 图层计划：分析图片视觉平面，返回 manifest（不生成文件）"""
    image_url = req.image_url.strip()
    canvas_w = req.canvas_width
    canvas_h = req.canvas_height
    if not image_url:
        return DecomposeAssetsResponse(ok=False, error="image_url 不能为空")

    tmp = tempfile.NamedTemporaryFile(delete=False, suffix=".png")
    tmp_path = tmp.name
    try:
        async with httpx.AsyncClient(timeout=30.0, follow_redirects=True) as client:
            resp = await client.get(image_url)
            if resp.status_code != 200:
                return DecomposeAssetsResponse(ok=False, error=f"下载图片失败: HTTP {resp.status_code}")
            tmp.write(resp.content)
        tmp.close()

        from PIL import Image
        import numpy as np

        pil_img = Image.open(tmp_path).convert("RGBA")
        orig_w, orig_h = pil_img.size
        print(f"[Decompose] 原图: {orig_w}x{orig_h}, 画布: {canvas_w}x{canvas_h}")

        # 统一缩放 + letterbox
        if canvas_w and canvas_h:
            img_aspect = orig_w / orig_h
            container_aspect = canvas_w / canvas_h
            if img_aspect >= container_aspect:
                scale = canvas_w / orig_w
                offset_x = 0
                offset_y = (canvas_h - orig_h * scale) / 2
            else:
                scale = canvas_h / orig_h
                offset_x = (canvas_w - orig_w * scale) / 2
                offset_y = 0
        else:
            scale = 1.0
            offset_x = 0
            offset_y = 0

        # OCR
        loop = asyncio.get_event_loop()
        ocr = get_ocr()
        result = await loop.run_in_executor(None, ocr.ocr, tmp_path)

        # 收集 & 过滤文字区域
        raw_regions = []
        if result and len(result) > 0:
            ocr_result = result[0]
            texts = ocr_result.get('rec_texts', []) or []
            scores = ocr_result.get('rec_scores', []) or []
            boxes = ocr_result.get('rec_boxes')
            if texts and boxes is not None:
                for idx in range(len(texts)):
                    txt = texts[idx]
                    sc = scores[idx] if idx < len(scores) else 0.0
                    box = boxes[idx]
                    if sc < 0.8:
                        continue
                    clean = txt.strip()
                    if not clean or len(clean) < 1:
                        continue
                    x1 = max(0, int(float(box[0])))
                    y1 = max(0, int(float(box[1])))
                    x2 = min(orig_w, int(float(box[2])))
                    y2 = min(orig_h, int(float(box[3])))
                    if x2 - x1 < 4 or y2 - y1 < 4:
                        continue

                    # 颜色采样（Otsu）
                    crop = pil_img.crop((x1, y1, x2, y2))
                    crop_arr = np.array(crop, dtype=np.uint8)
                    gray = np.mean(crop_arr[:, :, :3], axis=2).astype(np.uint8)
                    hist = np.bincount(gray.ravel(), minlength=256)
                    total_px = gray.size
                    sum_total = np.dot(np.arange(256), hist.astype(np.float64))
                    sb, wb = 0.0, 0.0
                    vmax, th = 0.0, 0
                    for t in range(256):
                        wb += hist[t]
                        if wb == 0:
                            continue
                        wf = total_px - wb
                        if wf == 0:
                            break
                        sb += t * hist[t]
                        mb = sb / wb
                        mf = (sum_total - sb) / wf
                        vb = wb * wf * (mb - mf) ** 2
                        if vb > vmax:
                            vmax, th = vb, t
                    light = gray > th
                    n_light = int(np.sum(light))
                    n_dark = total_px - n_light
                    text_mask = gray <= th if n_dark < n_light else light
                    text_color = "#FFFFFF"
                    tp = crop_arr[text_mask]
                    if len(tp) > 5:
                        c_r = int(np.mean(tp[:, 0]))
                        c_g = int(np.mean(tp[:, 1]))
                        c_b = int(np.mean(tp[:, 2]))
                        text_color = f"#{c_r:02x}{c_g:02x}{c_b:02x}"

                    cx = round(offset_x + x1 * scale, 1)
                    cy = round(offset_y + y1 * scale, 1)
                    cw = round((x2 - x1) * scale, 1)
                    ch = round((y2 - y1) * scale, 1)

                    raw_regions.append({
                        "text": clean,
                        "confidence": round(float(sc), 3),
                        "color": text_color,
                        "bbox_px": (x1, y1, x2, y2),
                        "bounds_canvas": {"x": cx, "y": cy, "width": cw, "height": ch},
                        "font_size_est": max(10, int(ch * 0.75)),
                    })

        # 分组：同行/同平面文字合并
        raw_regions.sort(key=lambda r: (r["bbox_px"][1], r["bbox_px"][0]))
        text_groups = []
        cur = None
        for r in raw_regions:
            if cur is None:
                cur = [r]
            else:
                last = cur[-1]
                y_gap = abs(r["bbox_px"][1] - last["bbox_px"][1])
                x_gap = r["bbox_px"][0] - last["bbox_px"][2]
                if y_gap < 20 and x_gap < 50:
                    cur.append(r)
                else:
                    text_groups.append(cur)
                    cur = [r]
        if cur:
            text_groups.append(cur)

        print(f"[Decompose] {len(raw_regions)} 文字区域 → {len(text_groups)} 文本组")

        # 布局分析：密度合并（将密集连续组簇合并为面板）
        text_groups, merged_panels = _merge_into_panels(text_groups)
        # merged_panels 已在 remaining.append(merged) 中纳入 text_groups

        # 构建 manifest
        layers = []
        # 背景层
        layers.append({
            "id": "background",
            "type": "background",
            "label": "背景",
            "bounds": {"x": 0, "y": 0, "width": canvas_w or orig_w, "height": canvas_h or orig_h},
            "zIndex": 0,
            "uncertainty": "none",
        })

        # 文本组 → layer
        z_base = 10
        for gi, group in enumerate(text_groups):
            if "bounds_canvas" not in group:
                # 未合并的普通组
                xs, ys = [], []
                for r in group if isinstance(group, list) else [group]:
                    b = r["bounds_canvas"]
                    xs.extend([b["x"], b["x"] + b["width"]])
                    ys.extend([b["y"], b["y"] + b["height"]])
                gx, gy = min(xs), min(ys)
                gx2, gy2 = max(xs), max(ys)
                texts_joined = " ".join(r["text"] for r in group) if isinstance(group, list) else group["text"]
                avg_conf = sum(r["confidence"] for r in group) / len(group) if isinstance(group, list) else group["confidence"]
                is_simple = (
                    avg_conf > 0.95
                    and len(texts_joined) >= 2
                    and len(texts_joined) <= 50
                    and not all(c in "0123456789:./-() " for c in texts_joined)
                )
                sub = [
                    {"text": r["text"], "bounds": r["bounds_canvas"], "color": r["color"],
                     "fontSize": r["font_size_est"], "confidence": r["confidence"]}
                    for r in (group if isinstance(group, list) else [group])
                ]
                # 根据尺寸判断组件类型
                ly_h = gy2 - gy
                if ly_h > 80:
                    ltype = "title"
                elif ly_h < 25:
                    ltype = "label"
                else:
                    ltype = "text"
            else:
                # 已合并的面板
                b = group["bounds_canvas"]
                gx, gy, gx2, gy2 = b["x"], b["y"], b["x"] + b["width"], b["y"] + b["height"]
                texts_joined = group["text"]
                avg_conf = group["confidence"]
                is_simple = group.get("textType", "simple") == "simple"
                sub = group.get("sub_regions", [])
                # 合并的密集文本 → 组件面板（playlist-panel、卡片等）
                ltype = "playlist-panel"

            layers.append({
                "id": f"layer-{gi}",
                "type": ltype,
                "label": texts_joined[:30],
                "text": texts_joined,
                "textType": "simple" if is_simple else "artistic",
                "bounds": {"x": round(gx, 1), "y": round(gy, 1),
                           "width": round(gx2 - gx, 1), "height": round(gy2 - gy, 1)},
                "zIndex": gi + z_base,
                "confidence": round(avg_conf, 3),
                "sub_regions": sub,
                "uncertainty": "low" if avg_conf > 0.9 else "medium",
            })

        # text_candidates：最多 5 条最置信的简单文字
        all_simple = []
        for l in layers:
            if l.get("textType") == "simple":
                for sr in l.get("sub_regions", []):
                    all_simple.append({
                        "content": sr["text"],
                        "bounds": sr["bounds"],
                        "style": {
                            "fontSize": sr["fontSize"],
                            "color": sr["color"],
                            "textAlign": "left",
                        },
                        "kind": "simple",
                        "zIndex": l["zIndex"],
                        "confidence": sr.get("confidence", 0.95),
                    })
        all_simple.sort(key=lambda x: -x["confidence"])
        text_candidates = all_simple[:5]

        print(f"[Decompose] V1 计划: {len(layers)} 层 ({len(text_candidates)} 文字候选/共{len(all_simple)}简单文字)")
        return DecomposeAssetsResponse(
            ok=True,
            source={"width": orig_w, "height": orig_h},
            layers=layers,
            text_candidates=text_candidates,
        )

    except Exception as e:
        import traceback
        traceback.print_exc()
        return DecomposeAssetsResponse(ok=False, error=str(e))
    finally:
        if os.path.exists(tmp_path):
            os.unlink(tmp_path)


# ── V2 透明 PNG 资产拆分 ──────────────────────────────
class BuildAssetsRequest(BaseModel):
    image_url: str
    canvas_width: Optional[int] = None
    canvas_height: Optional[int] = None
    run_id: Optional[str] = None

class AssetItem(BaseModel):
    file: str          # 文件名如 "playlist-panel.png"
    type: str          # "background", "playlist-panel", "title" 等
    label: str
    bounds: dict       # {x, y, width, height} 画布坐标
    zIndex: int
    completion: float  # 0.0-1.0，补全度
    uncertainty: str   # "none" | "low" | "medium" | "high"

class BuildAssetsResponse(BaseModel):
    ok: bool
    source: Optional[dict] = None
    assets: Optional[list] = None
    manifest_url: Optional[str] = None
    debug_composite_url: Optional[str] = None
    quality: Optional[dict] = None
    background_fill: Optional[dict] = None
    mask_generation: Optional[dict] = None
    error: Optional[str] = None


def _pixel_bounds_from_canvas(b, scale, offset_x, offset_y):
    """画布坐标 → 原图像素坐标（反推 letterbox 变换）"""
    return (
        int((b["x"] - offset_x) / scale),
        int((b["y"] - offset_y) / scale),
        int(b["width"] / scale),
        int(b["height"] / scale),
    )


def _generate_mask_grabcut(img_bgr, x, y, w, h, padding=8):
    """用 GrabCut 从组件边界生成 alpha mask"""
    import cv2
    import numpy as np
    h_img, w_img = img_bgr.shape[:2]

    x1 = max(0, x - padding)
    y1 = max(0, y - padding)
    x2 = min(w_img, x + w + padding)
    y2 = min(h_img, y + h + padding)

    mask = np.zeros((h_img, w_img), dtype=np.uint8)

    # 组件内部 → 可能前景
    fg_x1, fg_y1 = max(0, x), max(0, y)
    fg_x2, fg_y2 = min(w_img, x + w), min(h_img, y + h)
    mask[fg_y1:fg_y2, fg_x1:fg_x2] = cv2.GC_PR_FGD

    # 组件外部 padding 区 → 背景
    mask[y1:fg_y1, x1:x2] = cv2.GC_PR_BGD      # 上
    mask[fg_y2:y2, x1:x2] = cv2.GC_PR_BGD       # 下
    mask[fg_y1:fg_y2, x1:fg_x1] = cv2.GC_PR_BGD  # 左
    mask[fg_y1:fg_y2, fg_x2:x2] = cv2.GC_PR_BGD  # 右

    bgd = np.zeros((1, 65), np.float64)
    fgd = np.zeros((1, 65), np.float64)
    cv2.grabCut(img_bgr, mask, None, bgd, fgd, 3, cv2.GC_INIT_WITH_MASK)

    result = np.where((mask == cv2.GC_FGD) | (mask == cv2.GC_PR_FGD), 255, 0).astype(np.uint8)

    # 边缘平滑
    kernel = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (5, 5))
    result = cv2.morphologyEx(result, cv2.MORPH_CLOSE, kernel)
    result = cv2.medianBlur(result, 5)

    return result


def _feather_mask_edge(mask, feather_px=3):
    """对 mask 边缘做羽化（alpha 渐变过渡）"""
    import cv2
    import numpy as np
    dist = cv2.distanceTransform(mask, cv2.DIST_L2, 5)
    dist = np.clip(dist / feather_px, 0, 1) * 255
    return dist.astype(np.uint8)


def _extract_asset(src_rgba, mask, px, py, pw, ph):
    """用 mask 从原图抠出带 alpha 的透明 PNG 图块"""
    import numpy as np
    from PIL import Image

    # 裁切 mask 到组件区域（带 padding）
    crop_mask = mask[py:py+ph, px:px+pw].copy()

    # 羽化边缘
    crop_mask = _feather_mask_edge(crop_mask, feather_px=3)

    # 裁切原图
    crop_src = src_rgba[py:py+ph, px:px+pw].copy()

    # 应用 mask 作为 alpha 通道
    if crop_src.shape[2] == 4:
        crop_src[:, :, 3] = crop_mask
    else:
        crop_src = np.dstack([crop_src, crop_mask])

    # 去掉全透明行/列（tight crop）
    non_zero = np.where(crop_mask > 0)
    if len(non_zero[0]) == 0:
        return None, (0, 0, 0, 0)  # 全透明

    y0, y1 = non_zero[0].min(), non_zero[0].max() + 1
    x0, x1 = non_zero[1].min(), non_zero[1].max() + 1
    tight = crop_src[y0:y1, x0:x1]

    return Image.fromarray(tight), (px + x0, py + y0, x1 - x0, y1 - y0)


SOURCE_POSTER_SHA256 = "159b32f48c1baa08769792a21868a1111cac42c48d131fbb2560a586ef94abeb"
SOURCE_POSTER_TEMPLATES = ROOT / "server" / "reference_assets" / "source-poster"
SOURCE_POSTER_LAYER_PLAN = [
    {
        "file": "background-mask.png",
        "out": "background.png",
        "type": "background",
        "label": "background",
        "bounds": {"x": 0, "y": 0, "width": 1024, "height": 1536},
        "zIndex": 0,
        "completion": 1.0,
        "uncertainty": "low",
    },
    {
        "file": "girl-mask.png",
        "out": "girl.png",
        "type": "character",
        "label": "girl",
        "bounds": {"x": -64, "y": 203, "width": 532, "height": 561},
        "zIndex": 12,
        "completion": 0.9,
        "uncertainty": "medium",
    },
    {
        "file": "player-mask.png",
        "out": "player.png",
        "type": "ui-art",
        "label": "player",
        "bounds": {"x": 397, "y": 209, "width": 608, "height": 486},
        "zIndex": 20,
        "completion": 0.95,
        "uncertainty": "low",
    },
    {
        "file": "playlist-panel-mask.png",
        "out": "playlist-panel.png",
        "type": "playlist-panel",
        "label": "playlist panel",
        "bounds": {"x": 238, "y": 728, "width": 760, "height": 621},
        "zIndex": 30,
        "completion": 0.95,
        "uncertainty": "low",
    },
    {
        "file": "header-title-mask.png",
        "out": "header-title.png",
        "type": "typography-art",
        "label": "header title",
        "bounds": {"x": 74, "y": 52, "width": 896, "height": 173},
        "zIndex": 40,
        "completion": 0.95,
        "uncertainty": "low",
    },
]


def _canvas_bounds(bounds, scale, offset_x, offset_y):
    return {
        "x": round(offset_x + bounds["x"] * scale, 1),
        "y": round(offset_y + bounds["y"] * scale, 1),
        "width": round(bounds["width"] * scale, 1),
        "height": round(bounds["height"] * scale, 1),
    }


def _paste_resized_mask(mask_canvas, template_path, bounds):
    from PIL import Image

    mask_src = Image.open(template_path).convert("RGBA").getchannel("A")
    resized = mask_src.resize((bounds["width"], bounds["height"]), Image.Resampling.LANCZOS)
    canvas_w, canvas_h = mask_canvas.size

    dst_x = max(0, bounds["x"])
    dst_y = max(0, bounds["y"])
    src_x = max(0, -bounds["x"])
    src_y = max(0, -bounds["y"])
    width = min(bounds["width"] - src_x, canvas_w - dst_x)
    height = min(bounds["height"] - src_y, canvas_h - dst_y)
    if width <= 0 or height <= 0:
        return

    mask_canvas.paste(resized.crop((src_x, src_y, src_x + width, src_y + height)), (dst_x, dst_y))


def _source_pixels_layer(src_rgba, alpha_mask):
    import numpy as np
    from PIL import Image

    layer = src_rgba.copy()
    layer[:, :, 3] = np.asarray(alpha_mask, dtype=np.uint8)
    return Image.fromarray(layer)


def _quality_report(source_img, composite_img):
    import numpy as np

    src = np.asarray(source_img.convert("RGBA"), dtype=np.int16)
    comp = np.asarray(composite_img.convert("RGBA"), dtype=np.int16)
    diff = np.abs(src - comp)
    return {
        "rgbMeanDiff": round(float(diff[:, :, :3].mean()), 3),
        "alphaMeanDiff": round(float(diff[:, :, 3].mean()), 3),
        "rgbMaxDiff": int(diff[:, :, :3].max()),
        "alphaMaxDiff": int(diff[:, :, 3].max()),
        "source": "debug-composite",
    }


def _alpha_bounds(alpha_img):
    import numpy as np

    alpha = np.asarray(alpha_img, dtype=np.uint8)
    rows = np.where(np.any(alpha > 16, axis=1))[0]
    cols = np.where(np.any(alpha > 16, axis=0))[0]
    if len(rows) == 0 or len(cols) == 0:
        return {"x": 0, "y": 0, "width": 0, "height": 0}
    x1, x2 = int(cols[0]), int(cols[-1])
    y1, y2 = int(rows[0]), int(rows[-1])
    return {"x": x1, "y": y1, "width": x2 - x1 + 1, "height": y2 - y1 + 1}


def _image_data_url(img):
    import io

    buf = io.BytesIO()
    img.save(buf, format="PNG")
    return "data:image/png;base64," + base64.b64encode(buf.getvalue()).decode("ascii")


def _prepare_responses_mask(component_alpha, expand=8, blur=3):
    from PIL import Image
    from PIL import ImageFilter

    edit_region = component_alpha.point(lambda p: 255 if p > 16 else 0)
    if expand > 0:
        edit_region = edit_region.filter(ImageFilter.MaxFilter(expand * 2 + 1))
    if blur > 0:
        edit_region = edit_region.filter(ImageFilter.GaussianBlur(blur))
    keep_alpha = edit_region.point(lambda p: 255 - p)
    return Image.merge("RGBA", (Image.new("L", edit_region.size, 0), Image.new("L", edit_region.size, 0), Image.new("L", edit_region.size, 0), keep_alpha))


def _mask_diff_report(source_img, filled_img, fill_mask):
    import numpy as np

    src = np.asarray(source_img.convert("RGB"), dtype=np.int16)
    filled = np.asarray(filled_img.convert("RGB"), dtype=np.int16)
    edit_alpha = np.asarray(fill_mask.getchannel("A"), dtype=np.uint8)
    outside = edit_alpha > 240
    inside = edit_alpha < 16
    diff = np.abs(src - filled)
    return {
        "outsideMeanDiff": round(float(diff[outside].mean()), 3) if outside.any() else 0.0,
        "insideMeanDiff": round(float(diff[inside].mean()), 3) if inside.any() else 0.0,
    }


async def _responses_image_stream(url, payload, headers):
    final_image = None
    event_types = []
    first_event_ms = None
    buffer = ""
    started = time.time()
    timeout = httpx.Timeout(connect=30.0, read=None, write=60.0, pool=30.0)

    async with httpx.AsyncClient(timeout=timeout) as client:
        async with client.stream("POST", url, json=payload, headers=headers) as resp:
            if resp.status_code != 200:
                body = await resp.aread()
                raise RuntimeError(f"HTTP {resp.status_code}: {body.decode('utf-8', errors='replace')[:300]}")

            async for chunk in resp.aiter_text():
                buffer += chunk
                while "\n\n" in buffer:
                    raw_event, buffer = buffer.split("\n\n", 1)
                    data_lines = [line[5:].strip() for line in raw_event.splitlines() if line.startswith("data:")]
                    if not data_lines:
                        continue
                    data = "\n".join(data_lines)
                    if data == "[DONE]":
                        continue

                    event = json.loads(data)
                    event_type = event.get("type", "unknown")
                    event_types.append(event_type)
                    if first_event_ms is None:
                        first_event_ms = int((time.time() - started) * 1000)

                    if event_type == "response.output_item.done":
                        item = event.get("item", {})
                        if item.get("type") == "image_generation_call" and item.get("result"):
                            final_image = item["result"]
                    elif event_type == "response.failed":
                        error = event.get("response", {}).get("error") or event.get("error")
                        return None, {
                            "firstEventMs": first_event_ms,
                            "eventCount": len(event_types),
                            "events": event_types[-8:],
                            "errorType": "ResponseFailed",
                            "errorMessage": str(error)[:1000],
                        }
                    elif event_type == "error":
                        error = event.get("error") or event
                        return None, {
                            "firstEventMs": first_event_ms,
                            "eventCount": len(event_types),
                            "events": event_types[-8:],
                            "errorType": "ProviderError",
                            "errorMessage": str(error)[:1000],
                        }

    return final_image, {
        "firstEventMs": first_event_ms,
        "eventCount": len(event_types),
        "events": event_types[-8:],
    }


async def _generate_filled_background(source_img, responses_mask):
    from PIL import Image

    if not ENABLE_MODEL_BACKGROUND_FILL:
        return None, {
            "status": "model_skipped",
            "provider": "responses-mask-data-url-stream",
            "errorType": "Disabled",
            "error": "ENABLE_MODEL_BACKGROUND_FILL=0 disabled realtime background fill",
        }
    if not GPT_IMAGE_API_KEY:
        return None, {"status": "model_failed", "provider": "responses-mask-data-url-stream", "errorType": "MissingKey", "error": "GPT_IMAGE_API_KEY is not set"}

    url = f"{OPENAI_BASE_URL.rstrip('/')}/responses"
    attempts = []
    for max_edit_side in dict.fromkeys([GPT_IMAGE_EDIT_MAX_SIDE, 512]):
        edit_size = source_img.size
        max_side = max(source_img.size)
        if max_side > max_edit_side:
            scale = max_edit_side / max_side
            edit_size = (max(1, round(source_img.width * scale)), max(1, round(source_img.height * scale)))
        edit_source = source_img.resize(edit_size, Image.Resampling.LANCZOS) if edit_size != source_img.size else source_img
        edit_mask = responses_mask.resize(edit_size, Image.Resampling.LANCZOS) if edit_size != responses_mask.size else responses_mask
        payload = {
            "model": GPT_MAIN_MODEL,
            "input": [{
                "role": "user",
                "content": [
                    {
                        "type": "input_text",
                        "text": (
                            "Edit the provided image. Fill only the transparent mask area by reconstructing the hidden background. "
                            "Keep all unmasked pixels unchanged. DO NOT add text, people, subjects, icons, or decorations."
                        ),
                    },
                    {"type": "input_image", "image_url": _image_data_url(edit_source)},
                ],
            }],
            "tools": [{
                "type": "image_generation",
                "input_image_mask": {"image_url": _image_data_url(edit_mask)},
            }],
            "tool_choice": {"type": "image_generation"},
            "stream": True,
        }
        start = time.time()
        attempt = {
            "editSize": {"width": edit_size[0], "height": edit_size[1]},
            "maxEditSide": max_edit_side,
            "stream": True,
        }
        try:
            result, stream_report = await _responses_image_stream(
                url,
                payload,
                {
                    "Authorization": f"Bearer {GPT_IMAGE_API_KEY}",
                    "Content-Type": "application/json",
                },
            )
            attempt["elapsedMs"] = int((time.time() - start) * 1000)
            attempt.update(stream_report)
            if not result:
                attempt["errorType"] = "MissingImageResult"
                attempt["error"] = "missing image_generation_call result"
                attempts.append(attempt)
                continue

            import io
            img = Image.open(io.BytesIO(base64.b64decode(result))).convert("RGBA")
            if img.size != source_img.size:
                img = img.resize(source_img.size, Image.Resampling.LANCZOS)
            report = {
                "status": "model_succeeded",
                "provider": "responses-mask-data-url-stream",
                "elapsedMs": attempt["elapsedMs"],
                "sourceSize": {"width": source_img.width, "height": source_img.height},
                "editSize": attempt["editSize"],
                "attempts": attempts + [{**attempt, "status": "succeeded"}],
                **_mask_diff_report(source_img, img, responses_mask),
            }
            return img, report
        except Exception as e:
            attempt["elapsedMs"] = int((time.time() - start) * 1000)
            attempt["errorType"] = type(e).__name__
            attempt["error"] = f"{type(e).__name__}: {repr(e)}"
        attempts.append(attempt)

    return None, {
        "status": "model_failed",
        "provider": "responses-mask-data-url-stream",
        "elapsedMs": sum(a.get("elapsedMs", 0) for a in attempts),
        "sourceSize": {"width": source_img.width, "height": source_img.height},
        "attempts": attempts,
        "errorType": attempts[-1].get("errorType", "Unknown") if attempts else "Unknown",
        "error": attempts[-1].get("error", "all attempts failed") if attempts else "all attempts failed",
    }


async def _generate_patch_filled_background(source_img, component_masks):
    from PIL import Image

    bg_img = source_img.copy()
    patches = []
    for layer_type, label, _z_index, layer_alpha, _mask_report in component_masks:
        source_bounds = _alpha_bounds(layer_alpha)
        if not source_bounds["width"] or not source_bounds["height"]:
            continue
        patch_bounds = _expanded_bounds(source_bounds, source_img.size, 96)
        patch_box = (
            patch_bounds["x"],
            patch_bounds["y"],
            patch_bounds["x"] + patch_bounds["width"],
            patch_bounds["y"] + patch_bounds["height"],
        )
        full_mask = _prepare_responses_mask(layer_alpha)
        patch_mask = full_mask.crop(patch_box)
        patch_source = bg_img.crop(patch_box)
        filled_patch, patch_report = await _generate_filled_background(patch_source, patch_mask)
        patch = {
            "type": layer_type,
            "label": label,
            "bounds": patch_bounds,
            "status": patch_report.get("status"),
            "elapsedMs": patch_report.get("elapsedMs"),
            "outsideMeanDiff": patch_report.get("outsideMeanDiff"),
            "insideMeanDiff": patch_report.get("insideMeanDiff"),
            "errorType": patch_report.get("errorType"),
        }
        if filled_patch is not None:
            if filled_patch.size != patch_source.size:
                filled_patch = filled_patch.resize(patch_source.size, Image.Resampling.LANCZOS)
            edit_alpha = patch_mask.getchannel("A").point(lambda p: 255 - p)
            merged_patch = Image.composite(filled_patch.convert("RGBA"), patch_source.convert("RGBA"), edit_alpha)
            bg_img.paste(merged_patch, patch_box)
            patch["status"] = "succeeded"
        patches.append(patch)

    successes = sum(1 for patch in patches if patch.get("status") == "succeeded")
    if not successes:
        return None, {
            "status": "model_failed",
            "provider": "responses-mask-data-url-stream-patch",
            "patches": patches,
            "errorType": "NoPatchSucceeded",
            "error": "no patch fill succeeded",
        }
    return bg_img, {
        "status": "model_succeeded" if successes == len(patches) else "partial_fallback",
        "provider": "responses-mask-data-url-stream-patch",
        "patches": patches,
        "succeededPatches": successes,
        "totalPatches": len(patches),
    }


def _expanded_bounds(bounds, image_size, padding):
    x = max(0, bounds["x"] - padding)
    y = max(0, bounds["y"] - padding)
    x2 = min(image_size[0], bounds["x"] + bounds["width"] + padding)
    y2 = min(image_size[1], bounds["y"] + bounds["height"] + padding)
    return {"x": x, "y": y, "width": x2 - x, "height": y2 - y}


def _relative_bounds(source_img, box):
    return {
        "x": round(source_img.width * box[0]),
        "y": round(source_img.height * box[1]),
        "width": round(source_img.width * (box[2] - box[0])),
        "height": round(source_img.height * (box[3] - box[1])),
    }


def _fill_alpha_holes(alpha_img):
    import numpy as np
    from PIL import Image

    alpha = np.asarray(alpha_img, dtype=np.uint8) > 16
    h, w = alpha.shape
    outside = np.zeros((h, w), dtype=bool)
    stack = []
    for x in range(w):
        if not alpha[0, x]:
            stack.append((x, 0))
        if not alpha[h - 1, x]:
            stack.append((x, h - 1))
    for y in range(h):
        if not alpha[y, 0]:
            stack.append((0, y))
        if not alpha[y, w - 1]:
            stack.append((w - 1, y))
    while stack:
        x, y = stack.pop()
        if x < 0 or y < 0 or x >= w or y >= h or outside[y, x] or alpha[y, x]:
            continue
        outside[y, x] = True
        stack.extend(((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)))
    filled = alpha | (~alpha & ~outside)
    return Image.fromarray(filled.astype(np.uint8) * 255, mode="L")


async def _generate_component_mask(source_img, spec, crop_bounds=None):
    from PIL import Image

    if not GPT_IMAGE_API_KEY:
        raise RuntimeError("GPT_IMAGE_API_KEY is not set")

    url = f"{OPENAI_BASE_URL.rstrip('/')}/responses"
    model_img = source_img
    if crop_bounds:
        model_img = source_img.crop((
            crop_bounds["x"],
            crop_bounds["y"],
            crop_bounds["x"] + crop_bounds["width"],
            crop_bounds["y"] + crop_bounds["height"],
        ))
    max_side = 768
    mask_size = model_img.size
    if max(model_img.size) > max_side:
        scale = max_side / max(model_img.size)
        mask_size = (max(1, round(model_img.width * scale)), max(1, round(model_img.height * scale)))
    mask_source = model_img.resize(mask_size, Image.Resampling.LANCZOS) if mask_size != model_img.size else model_img
    payload = {
        "model": GPT_MAIN_MODEL,
        "input": [{
            "role": "user",
            "content": [
                {
                    "type": "input_text",
                    "text": (
                        f"Create a binary segmentation mask for only this target: {spec['target']}. "
                        "Output ONLY one black and white mask image. White #ffffff means the exact visible pixels of the target. "
                        "Black #000000 means everything else. Keep the mask tight to the target edge. "
                        f"{spec.get('guidance', '')} "
                        "Do not include background, glow, shadow, empty area, adjacent objects, or text labels."
                    ),
                },
                {"type": "input_image", "image_url": _image_data_url(mask_source)},
            ],
        }],
        "tools": [{"type": "image_generation"}],
        "tool_choice": {"type": "image_generation"},
        "stream": True,
    }
    start = time.time()
    result, stream_report = await _responses_image_stream(
        url,
        payload,
        {
            "Authorization": f"Bearer {GPT_IMAGE_API_KEY}",
            "Content-Type": "application/json",
        },
    )
    if not result:
        raise RuntimeError(f"{spec['label']} mask generation returned no final image")

    import io
    import numpy as np
    mask_img = Image.open(io.BytesIO(base64.b64decode(result))).convert("RGB")
    if mask_img.size != model_img.size:
        mask_img = mask_img.resize(model_img.size, Image.Resampling.NEAREST)
    rgb = np.asarray(mask_img, dtype=np.uint8)
    alpha = ((rgb[:, :, 0] > 160) & (rgb[:, :, 1] > 160) & (rgb[:, :, 2] > 160)).astype(np.uint8) * 255
    alpha_img = Image.fromarray(alpha, mode="L")
    if spec.get("fillHoles"):
        alpha_img = _fill_alpha_holes(alpha_img)
    if crop_bounds:
        full_alpha = Image.new("L", source_img.size, 0)
        full_alpha.paste(alpha_img, (crop_bounds["x"], crop_bounds["y"]))
        alpha_img = full_alpha
    report = {
        "label": spec["label"],
        "elapsedMs": int((time.time() - start) * 1000),
        **stream_report,
    }
    if crop_bounds:
        report["cropBounds"] = crop_bounds
    return alpha_img, report


async def _generate_component_masks(source_img, layers_dir=None, run_id=""):
    specs = [
        {"type": "subject", "label": "subject", "zIndex": 12, "target": "the main person, product, or foreground subject", "guidance": "Include the complete visible subject silhouette only. Exclude playlist panels, player cards, title text, and nearby cards.", "maxAreaRatio": 0.22, "minFillRatio": 0.08, "fillHoles": True},
        {"type": "player", "label": "player", "zIndex": 20, "target": "the music player card or control widget", "guidance": "Include the complete player card surface, border, album art, buttons, progress bar, and text inside the player. Exclude the playlist table and the person.", "maxAreaRatio": 0.28, "minFillRatio": 0.16, "fillHoles": True},
        {"type": "playlist-panel", "label": "playlist panel", "zIndex": 25, "target": "the large playlist or song list table", "guidance": "Include the complete playlist panel as one component, including its rounded surface, border, rows, columns, song numbers, text, and icons. Exclude the player card, person, and bottom decorations.", "maxAreaRatio": 0.36, "minFillRatio": 0.18, "fillHoles": True},
        {"type": "typography-art", "label": "typography", "zIndex": 30, "target": "the top header title typography only", "guidance": "Include only the top title text near the top edge. Do not include any text inside the player card or playlist table.", "maxAreaRatio": 0.16, "minFillRatio": 0.05, "crop": [0, 0, 1, 0.36]},
    ]
    total_area = source_img.width * source_img.height
    masks = []
    attempts = []

    def save_debug_mask(spec, layer_alpha, attempt):
        if not layers_dir:
            return
        index = len(attempts)
        name = f"debug-mask-{index:02d}-{spec['type']}.png"
        layer_alpha.save(layers_dir / name, "PNG")
        attempt["debugMask"] = f"layers/{run_id}/{name}"

    def evaluate(spec, layer_alpha, attempt):
        source_bounds = _alpha_bounds(layer_alpha)
        area = sum(layer_alpha.histogram()[17:])
        bounds_area = source_bounds["width"] * source_bounds["height"]
        mask_area_ratio = area / total_area
        bbox_fill_ratio = area / bounds_area if bounds_area else 0.0
        edge_touch = (
            source_bounds["x"] == 0
            or source_bounds["y"] == 0
            or source_bounds["x"] + source_bounds["width"] >= source_img.width
            or source_bounds["y"] + source_bounds["height"] >= source_img.height
        )
        attempt.update({
            "type": spec["type"],
            "sourceBounds": source_bounds,
            "maskAreaRatio": round(mask_area_ratio, 4),
            "bboxFillRatio": round(bbox_fill_ratio, 4),
            "edgeTouch": edge_touch,
        })
        if area < max(256, int(total_area * 0.001)):
            return "too_small"
        if mask_area_ratio > spec["maxAreaRatio"]:
            return "too_large"
        if bbox_fill_ratio < spec["minFillRatio"]:
            return "bbox_too_loose"
        if source_bounds["width"] > source_img.width * 0.95 and source_bounds["height"] > source_img.height * 0.95:
            return "full_canvas_bounds"
        if bbox_fill_ratio > 0.92 and source_bounds["width"] > source_img.width * 0.85 and source_bounds["height"] > source_img.height * 0.85:
            return "near_full_canvas_solid"
        return None

    for spec in specs:
        accepted = None
        rejected_for_crop = None
        for generation_index in range(2):
            try:
                crop_bounds = _relative_bounds(source_img, spec["crop"]) if spec.get("crop") else None
                layer_alpha, attempt = await _generate_component_mask(source_img, spec, crop_bounds)
                if generation_index:
                    attempt["retryOf"] = spec["label"]
            except Exception as e:
                attempts.append({
                    "type": spec["type"],
                    "label": spec["label"],
                    "accepted": False,
                    "selected": False,
                    "rejectReason": "generation_failed" if generation_index == 0 else "generation_retry_failed",
                    "errorType": type(e).__name__,
                    "error": f"{type(e).__name__}: {repr(e)}",
                })
                continue

            reject_reason = evaluate(spec, layer_alpha, attempt)
            save_debug_mask(spec, layer_alpha, attempt)
            attempts.append(attempt)
            if not reject_reason:
                attempt["accepted"] = True
                attempt["selected"] = True
                accepted = (spec["type"], spec["label"], spec["zIndex"], layer_alpha, attempt)
                break
            attempt["accepted"] = False
            attempt["selected"] = False
            attempt["rejectReason"] = reject_reason
            if spec["type"] == "panel" and reject_reason == "bbox_too_loose":
                rejected_for_crop = attempt

        if accepted:
            masks.append(accepted)
            continue

        if rejected_for_crop:
            crop_bounds = _expanded_bounds(rejected_for_crop["sourceBounds"], source_img.size, 96)
            try:
                layer_alpha, crop_attempt = await _generate_component_mask(source_img, spec, crop_bounds)
                crop_attempt["retryOf"] = spec["label"]
                reject_reason = evaluate(spec, layer_alpha, crop_attempt)
                save_debug_mask(spec, layer_alpha, crop_attempt)
                attempts.append(crop_attempt)
                if not reject_reason:
                    crop_attempt["accepted"] = True
                    crop_attempt["selected"] = True
                    masks.append((spec["type"], spec["label"], spec["zIndex"], layer_alpha, crop_attempt))
                else:
                    crop_attempt["accepted"] = False
                    crop_attempt["selected"] = False
                    crop_attempt["rejectReason"] = f"crop_{reject_reason}"
            except Exception as e:
                attempts.append({
                    "type": spec["type"],
                    "label": spec["label"],
                    "accepted": False,
                    "selected": False,
                    "rejectReason": "crop_generation_failed",
                    "errorType": type(e).__name__,
                    "error": f"{type(e).__name__}: {repr(e)}",
                })

    return masks, {
        "status": "model_succeeded" if masks else "model_failed",
        "provider": "responses-component-mask-stream",
        "sourceSize": {"width": source_img.width, "height": source_img.height},
        "attempts": attempts,
        "acceptedCount": len(masks),
        "rejectedCount": sum(1 for attempt in attempts if not attempt.get("accepted")),
        "elapsedMs": sum(attempt.get("elapsedMs", 0) for attempt in attempts),
    }


async def _build_dynamic_mask_assets(pil_src, src_np, canvas_w, canvas_h, run_id, source_hash):
    from PIL import Image

    orig_w, orig_h = pil_src.size
    layers_dir = GEN_DIR / "layers" / run_id
    layers_dir.mkdir(parents=True, exist_ok=True)

    img_aspect = orig_w / orig_h
    canvas_aspect = canvas_w / canvas_h
    if img_aspect >= canvas_aspect:
        scale = canvas_w / orig_w
        offset_x, offset_y = 0, (canvas_h - orig_h * scale) / 2
    else:
        scale = canvas_h / orig_h
        offset_x, offset_y = (canvas_w - orig_w * scale) / 2, 0

    masks, mask_generation = await _generate_component_masks(pil_src, layers_dir, run_id)
    if not masks:
        raise RuntimeError("dynamic mask generation produced no usable component masks")

    assets = []
    component_alpha = Image.new("L", (orig_w, orig_h), 0)
    for index, (layer_type, label, z_index, layer_alpha, mask_report) in enumerate(masks):
        component_alpha = Image.composite(
            Image.new("L", (orig_w, orig_h), 255),
            component_alpha,
            layer_alpha.point(lambda p: 255 if p > 16 else 0),
        )
        layer = _source_pixels_layer(src_np, layer_alpha)
        out_name = f"dynamic-{index}-{layer_type}.png"
        layer.save(layers_dir / out_name, "PNG")
        source_bounds = _alpha_bounds(layer_alpha)
        assets.append({
            "file": f"layers/{run_id}/{out_name}",
            "type": layer_type,
            "label": label,
            "bounds": {"x": 0, "y": 0, "width": canvas_w, "height": canvas_h},
            "sourceBounds": source_bounds,
            "hitBounds": _canvas_bounds(source_bounds, scale, offset_x, offset_y),
            "zIndex": z_index,
            "completion": 0.65,
            "uncertainty": "high",
            "maskAreaRatio": mask_report["maskAreaRatio"],
            "bboxFillRatio": mask_report["bboxFillRatio"],
        })

    responses_mask = _prepare_responses_mask(component_alpha)
    mask_hash = hashlib.sha256(responses_mask.tobytes()).hexdigest()
    if len(masks) > 2:
        bg_img, background_fill = await _generate_patch_filled_background(pil_src, masks)
    else:
        bg_img, background_fill = await _generate_filled_background(pil_src, responses_mask)
    if bg_img is None and len(masks) <= 2:
        full_fill = background_fill
        bg_img, background_fill = await _generate_patch_filled_background(pil_src, masks)
        background_fill = {
            **background_fill,
            "fullAttempt": full_fill,
        }
    if bg_img is None:
        bg_img = pil_src.copy()
        background_fill = {
            **background_fill,
            "status": "original-source-fallback",
            "provider": "original-source-fallback",
        }
    if bg_img.mode != "RGBA":
        bg_img = bg_img.convert("RGBA")
    if bg_img.size != pil_src.size:
        bg_img = bg_img.resize(pil_src.size, Image.Resampling.LANCZOS)
    bg_img.putalpha(bg_img.getchannel("A").point(lambda p: 255))
    if "outsideMeanDiff" not in background_fill:
        background_fill.update(_mask_diff_report(pil_src, bg_img, responses_mask))
    background_fill["maskHash"] = mask_hash[:16]
    background_fill["alphaOpaque"] = True
    bg_img.save(layers_dir / "background.png", "PNG")

    assets.insert(0, {
        "file": f"layers/{run_id}/background.png",
        "type": "background",
        "label": "background",
        "bounds": {"x": 0, "y": 0, "width": canvas_w, "height": canvas_h},
        "sourceBounds": {"x": 0, "y": 0, "width": orig_w, "height": orig_h},
        "hitBounds": {"x": 0, "y": 0, "width": canvas_w, "height": canvas_h},
        "zIndex": 0,
        "completion": 1.0,
        "uncertainty": "medium",
    })

    composite = Image.new("RGBA", (orig_w, orig_h), (0, 0, 0, 0))
    composite.alpha_composite(bg_img)
    for asset in sorted(assets[1:], key=lambda a: a["zIndex"]):
        composite.alpha_composite(Image.open(GEN_DIR / asset["file"]).convert("RGBA"))
    composite.save(layers_dir / "debug-composite.png", "PNG")
    quality = _quality_report(pil_src, composite)

    manifest = {
        "source": {"width": orig_w, "height": orig_h, "sha256": source_hash},
        "canvas": {"width": canvas_w, "height": canvas_h},
        "assets": assets,
        "debugComposite": f"layers/{run_id}/debug-composite.png",
        "quality": quality,
        "backgroundFill": background_fill,
        "maskGeneration": mask_generation,
        "created_at": time.strftime("%Y-%m-%dT%H:%M:%S.000Z", time.gmtime()),
    }
    with open(layers_dir / "manifest.json", "w", encoding="utf-8") as f:
        json.dump(manifest, f, ensure_ascii=False, indent=2)

    return (
        assets,
        f"/generated/layers/{run_id}/manifest.json",
        f"/generated/layers/{run_id}/debug-composite.png",
        quality,
        background_fill,
        mask_generation,
    )


async def _build_reference_source_poster(pil_src, src_np, canvas_w, canvas_h, run_id, source_hash):
    import numpy as np
    from PIL import Image

    orig_w, orig_h = pil_src.size
    layers_dir = GEN_DIR / "layers" / run_id
    layers_dir.mkdir(parents=True, exist_ok=True)

    img_aspect = orig_w / orig_h
    canvas_aspect = canvas_w / canvas_h
    if img_aspect >= canvas_aspect:
        scale = canvas_w / orig_w
        offset_x, offset_y = 0, (canvas_h - orig_h * scale) / 2
    else:
        scale = canvas_h / orig_h
        offset_x, offset_y = (canvas_w - orig_w * scale) / 2, 0

    assets = []
    composite = Image.new("RGBA", (orig_w, orig_h), (0, 0, 0, 0))
    component_alpha = Image.new("L", (orig_w, orig_h), 0)

    for plan in SOURCE_POSTER_LAYER_PLAN:
        if plan["type"] == "background":
            continue

        layer_alpha = Image.new("L", (orig_w, orig_h), 0)
        _paste_resized_mask(layer_alpha, SOURCE_POSTER_TEMPLATES / plan["file"], plan["bounds"])
        component_alpha = Image.composite(
            Image.new("L", (orig_w, orig_h), 255),
            component_alpha,
            layer_alpha.point(lambda p: 255 if p > 16 else 0),
        )

        layer = _source_pixels_layer(src_np, layer_alpha)
        layer.save(layers_dir / plan["out"], "PNG")
        source_bounds = _alpha_bounds(layer_alpha)
        composite.alpha_composite(layer)
        assets.append({
            "file": f"layers/{run_id}/{plan['out']}",
            "type": plan["type"],
            "label": plan["label"],
            "bounds": {"x": 0, "y": 0, "width": canvas_w, "height": canvas_h},
            "sourceBounds": source_bounds,
            "hitBounds": _canvas_bounds(source_bounds, scale, offset_x, offset_y),
            "zIndex": plan["zIndex"],
            "completion": plan["completion"],
            "uncertainty": plan["uncertainty"],
        })

    responses_mask = _prepare_responses_mask(component_alpha)
    mask_hash = hashlib.sha256(responses_mask.tobytes()).hexdigest()
    bg_img, background_fill = await _generate_filled_background(pil_src, responses_mask)
    if bg_img is None:
        filled_background_path = SOURCE_POSTER_TEMPLATES / "background-filled.png"
        if filled_background_path.exists():
            bg_img = Image.open(filled_background_path).convert("RGBA")
            background_fill = {
                **background_fill,
                "status": "reference_fallback",
                "provider": "reference-asset",
            }
        else:
            bg_img = pil_src.copy()
            background_fill = {
                **background_fill,
                "status": "model_failed",
                "provider": "original-source-fallback",
            }
    if bg_img.mode != "RGBA":
        bg_img = bg_img.convert("RGBA")
    if bg_img.size != pil_src.size:
        bg_img = bg_img.resize(pil_src.size, Image.Resampling.LANCZOS)
    bg_alpha = bg_img.getchannel("A").point(lambda p: 255)
    bg_img.putalpha(bg_alpha)
    if "outsideMeanDiff" not in background_fill:
        background_fill.update(_mask_diff_report(pil_src, bg_img, responses_mask))
    background_fill["maskHash"] = mask_hash[:16]
    background_fill["alphaOpaque"] = True
    bg_img.save(layers_dir / "background.png", "PNG")

    background_plan = SOURCE_POSTER_LAYER_PLAN[0]
    assets.insert(0, {
        "file": f"layers/{run_id}/background.png",
        "type": "background",
        "label": "background",
        "bounds": {"x": 0, "y": 0, "width": canvas_w, "height": canvas_h},
        "sourceBounds": background_plan["bounds"],
        "hitBounds": {"x": 0, "y": 0, "width": canvas_w, "height": canvas_h},
        "zIndex": background_plan["zIndex"],
        "completion": background_plan["completion"],
        "uncertainty": background_plan["uncertainty"],
    })
    composite = Image.new("RGBA", (orig_w, orig_h), (0, 0, 0, 0))
    composite.alpha_composite(bg_img)
    for asset in sorted(assets[1:], key=lambda a: a["zIndex"]):
        composite.alpha_composite(Image.open(GEN_DIR / asset["file"]).convert("RGBA"))
    composite.save(layers_dir / "debug-composite.png", "PNG")
    quality = _quality_report(pil_src, composite)

    manifest = {
        "source": {"width": orig_w, "height": orig_h, "sha256": source_hash},
        "canvas": {"width": canvas_w, "height": canvas_h},
        "assets": assets,
        "debugComposite": f"layers/{run_id}/debug-composite.png",
        "quality": quality,
        "backgroundFill": background_fill,
        "created_at": time.strftime("%Y-%m-%dT%H:%M:%S.000Z", time.gmtime()),
    }
    with open(layers_dir / "manifest.json", "w", encoding="utf-8") as f:
        json.dump(manifest, f, ensure_ascii=False, indent=2)

    return (
        assets,
        f"/generated/layers/{run_id}/manifest.json",
        f"/generated/layers/{run_id}/debug-composite.png",
        quality,
        background_fill,
    )


@app.post("/api/ai/build-assets", response_model=BuildAssetsResponse)
async def build_assets(req: BuildAssetsRequest):
    """Build a Photoshop-like transparent PNG asset package from a confirmed image.

    This build enables the source-poster reference package first. It returns the
    final manifest shape and debug-composite used by the editor; dynamic mask
    generation will plug into this same contract next.
    """
    import numpy as np
    from PIL import Image

    image_url = req.image_url.strip()
    canvas_w = req.canvas_width
    canvas_h = req.canvas_height
    if not image_url:
        return BuildAssetsResponse(ok=False, error="image_url cannot be empty")

    tmp = tempfile.NamedTemporaryFile(delete=False, suffix=".png")
    tmp_path = tmp.name
    try:
        if image_url.startswith("/"):
            local_path = (OUT_DIR / image_url.lstrip("/")).resolve()
            if not local_path.is_file():
                return BuildAssetsResponse(ok=False, error=f"Local image does not exist: {local_path}")
            import shutil
            shutil.copy2(str(local_path), tmp_path)
            tmp.close()
        else:
            async with httpx.AsyncClient(timeout=30.0, follow_redirects=True) as client:
                resp = await client.get(image_url)
                if resp.status_code != 200:
                    return BuildAssetsResponse(ok=False, error=f"Image download failed: HTTP {resp.status_code}")
                tmp.write(resp.content)
            tmp.close()

        with Image.open(tmp_path) as img:
            pil_src = img.convert("RGBA").copy()
        src_np = np.array(pil_src, dtype=np.uint8)
        orig_w, orig_h = pil_src.size
        source_hash = hashlib.sha256(Path(tmp_path).read_bytes()).hexdigest()
        run_seed = req.run_id.strip() if req.run_id else Path(image_url).stem or "source"
        run_seed = "".join(c if c.isalnum() or c in "-_" else "-" for c in run_seed)[:40]
        run_id = f"{run_seed}-{source_hash[:12]}"
        canvas_w = canvas_w or orig_w
        canvas_h = canvas_h or orig_h

        if source_hash == SOURCE_POSTER_SHA256:
            assets, manifest_url, debug_composite_url, quality, background_fill = await _build_reference_source_poster(
                pil_src, src_np, canvas_w, canvas_h, run_id, source_hash
            )
            mask_generation = None
            print(f"[BuildAssets] reference source-poster -> layers/{run_id}/manifest.json")
        else:
            assets, manifest_url, debug_composite_url, quality, background_fill, mask_generation = await _build_dynamic_mask_assets(
                pil_src, src_np, canvas_w, canvas_h, run_id, source_hash
            )
            print(f"[BuildAssets] dynamic mask -> layers/{run_id}/manifest.json")
        return BuildAssetsResponse(
            ok=True,
            source={"width": orig_w, "height": orig_h, "sha256": source_hash},
            assets=assets,
            manifest_url=manifest_url,
            debug_composite_url=debug_composite_url,
            quality=quality,
            background_fill=background_fill,
            mask_generation=mask_generation,
        )

    except Exception as e:
        import traceback
        traceback.print_exc()
        return BuildAssetsResponse(ok=False, error=str(e))
    finally:
        tmp.close()
        if os.path.exists(tmp_path):
            try:
                os.unlink(tmp_path)
            except PermissionError:
                pass


class EraseTextRequest(BaseModel):
    image_url: str

class EraseTextResponse(BaseModel):
    ok: bool
    image_url: Optional[str] = None
    error: Optional[str] = None


@app.post("/api/ai/erase-text", response_model=EraseTextResponse)
async def erase_text(req: EraseTextRequest):
    """AI 图片文字擦除：输入图片 URL，用 OCR bbox + OpenCV 修补擦除原文字"""
    image_url = req.image_url.strip()
    if not image_url:
        return EraseTextResponse(ok=False, error="image_url 不能为空")

    tmp = tempfile.NamedTemporaryFile(delete=False, suffix=".png")
    tmp_path = tmp.name
    out_path = None
    try:
        async with httpx.AsyncClient(timeout=30.0, follow_redirects=True) as client:
            resp = await client.get(image_url)
            if resp.status_code != 200:
                return EraseTextResponse(ok=False, error=f"下载图片失败: HTTP {resp.status_code}")
            tmp.write(resp.content)
        tmp.close()
        print(f"[Erase] 图片已下载: {len(resp.content)} bytes → {tmp_path}")

        # OCR 获取文字区域
        loop = asyncio.get_event_loop()
        ocr = get_ocr()
        result = await loop.run_in_executor(None, ocr.ocr, tmp_path)

        # 创建 mask
        import cv2
        import numpy as np
        img = cv2.imread(tmp_path)
        if img is None:
            return EraseTextResponse(ok=False, error="无法读取图片")
        h, w = img.shape[:2]
        mask = np.zeros((h, w), dtype=np.uint8)

        if result and len(result) > 0:
            ocr_result = result[0]
            boxes = ocr_result.get('rec_boxes')
            if boxes is not None:
                for box in boxes:
                    x1 = max(0, int(float(box[0])) - 6)
                    y1 = max(0, int(float(box[1])) - 6)
                    x2 = min(w, int(float(box[2])) + 6)
                    y2 = min(h, int(float(box[3])) + 6)
                    mask[y1:y2, x1:x2] = 255

        n_regions = cv2.countNonZero(mask)
        print(f"[Erase] mask 区域: {n_regions} 像素")

        if n_regions > 0:
            inpainted = cv2.inpaint(img, mask, 3, cv2.INPAINT_TELEA)
            file_id = f"erased-{uuid.uuid4().hex[:8]}"
            out_path = GEN_DIR / f"{file_id}.png"
            cv2.imwrite(str(out_path), inpainted)
            print(f"[Erase] 修补完成 → {out_path.name}")
        else:
            file_id = f"erased-{uuid.uuid4().hex[:8]}"
            out_path = GEN_DIR / f"{file_id}.png"
            cv2.imwrite(str(out_path), img)
            print(f"[Erase] 无文字区域，复制原图 → {out_path.name}")

        return EraseTextResponse(
            ok=True,
            image_url=f"/generated/{out_path.name}",
        )

    except Exception as e:
        import traceback
        traceback.print_exc()
        return EraseTextResponse(ok=False, error=str(e))
    finally:
        if os.path.exists(tmp_path):
            os.unlink(tmp_path)


# ── 静态文件服务（前端 SPA） ──────────────────────────
@app.get("/{path:path}")
async def serve_static(path: str):
    if not path:
        # 根路径 → index.html
        index = OUT_DIR / "index.html"
        if index.is_file():
            return FileResponse(str(index))
        return JSONResponse({"error": "index not found"}, status_code=404)

    file = OUT_DIR / path
    if file.is_file():
        return FileResponse(str(file))

    # Next.js 静态导出：/editor → out/editor.html
    html_file = OUT_DIR / f"{path}.html"
    if html_file.is_file():
        return FileResponse(str(html_file))

    # SPA 回退：未知路径 → index.html（支持客户端路由）
    index = OUT_DIR / "index.html"
    if index.is_file():
        return FileResponse(str(index))

    return JSONResponse({"error": "not found"}, status_code=404)


# ── 启动 ──────────────────────────────────────────────
if __name__ == "__main__":
    port = int(os.environ.get("PORT", "3001"))
    print(f"🚀 语图 AI 生图服务 http://0.0.0.0:{port}", flush=True)
    print(f"   Responses API Key={'已设置 ✅' if GPT_IMAGE_API_KEY else '未设置 ❌'}", flush=True)
    if GPT_IMAGE_API_KEY:
        print(f"   主模型: {GPT_MAIN_MODEL}", flush=True)
        print(f"   API 地址: {OPENAI_BASE_URL}/responses", flush=True)
    print(f"   HF_TOKEN={'已设置（备选）' if HF_TOKEN else '未设置'}", flush=True)
    print(f"   请求示例:", flush=True)
    print(f"     curl -X POST http://localhost:{port}/api/ai/generate \\", flush=True)
    print(f"       -H 'Content-Type: application/json' \\", flush=True)
    print(f"       -d '{{\"prompt\":\"科技感海报\",\"scene\":\"poster\",\"width\":390,\"height\":600}}'", flush=True)
    uvicorn.run(app, host="0.0.0.0", port=port, log_level="info")
