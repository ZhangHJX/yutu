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
    provider: Optional[str] = None  # "responses-api" | "huggingface"

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


async def try_gpt_image_generate(prompt: str, w: int, h: int) -> Optional[bytes]:
    """通过 Responses API + image_generation tool 生图（支持 gpt-image-2 等模型）"""
    if not GPT_IMAGE_API_KEY:
        print("[GPT-Image] 未配置 GPT_IMAGE_API_KEY")
        return None

    url = f"{OPENAI_BASE_URL.rstrip('/')}/responses"
    payload = {
        "model": GPT_MAIN_MODEL,
        "input": prompt,
        "tools": [{"type": "image_generation"}],
    }
    print(f"[GPT-Image] 请求: prompt={prompt[:40]}, url={url}, model={GPT_MAIN_MODEL}")

    async with httpx.AsyncClient(timeout=120.0) as client:
        try:
            resp = await client.post(
                url,
                json=payload,
                headers={
                    "Authorization": f"Bearer {GPT_IMAGE_API_KEY}",
                    "Content-Type": "application/json",
                },
            )

            if resp.status_code != 200:
                print(f"[GPT-Image] 错误 HTTP {resp.status_code}: {resp.text[:300]}")
                return None

            data = resp.json()
            if data.get("status") != "completed":
                err = data.get("error", "状态未完成")
                print(f"[GPT-Image] 生成失败: {err}")
                return None

            output = data.get("output", [])
            for item in output:
                if item.get("type") == "image_generation_call":
                    b64 = item.get("result", "")
                    if b64:
                        print(f"[GPT-Image] 成功 ({len(b64)} chars base64)")
                        return base64.b64decode(b64)

            print(f"[GPT-Image] 输出中未找到 image_generation_call: {str(output)[:200]}")
            return None

        except Exception as e:
            print(f"[GPT-Image] 异常: {e}")
            return None

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


@app.post("/api/ai/build-assets", response_model=BuildAssetsResponse)
async def build_assets(req: BuildAssetsRequest):
    """V2：从源图按组件 plan 拆出透明 PNG 资产 + manifest"""
    import cv2
    import numpy as np
    from PIL import Image

    image_url = req.image_url.strip()
    canvas_w = req.canvas_width
    canvas_h = req.canvas_height
    if not image_url:
        return BuildAssetsResponse(ok=False, error="image_url 不能为空")

    tmp = tempfile.NamedTemporaryFile(delete=False, suffix=".png")
    tmp_path = tmp.name
    try:
        # 1) 下载源图（支持相对路径 → 本地文件）
        if image_url.startswith("/"):
            local_path = (OUT_DIR / image_url.lstrip("/")).resolve()
            if not local_path.is_file():
                return BuildAssetsResponse(ok=False, error=f"本地文件不存在: {local_path}")
            import shutil
            shutil.copy2(str(local_path), tmp_path)
            tmp.close()
        else:
            async with httpx.AsyncClient(timeout=30.0, follow_redirects=True) as client:
                resp = await client.get(image_url)
                if resp.status_code != 200:
                    return BuildAssetsResponse(ok=False, error=f"下载图片失败: HTTP {resp.status_code}")
                tmp.write(resp.content)
            tmp.close()

        pil_src = Image.open(tmp_path).convert("RGBA")
        src_np = np.array(pil_src, dtype=np.uint8)
        orig_w, orig_h = pil_src.size

        # 2) 计算缩放（同 decompose-assets）
        if canvas_w and canvas_h:
            img_aspect = orig_w / orig_h
            container_aspect = canvas_w / canvas_h
            if img_aspect >= container_aspect:
                scale = canvas_w / orig_w
                offset_x, offset_y = 0, (canvas_h - orig_h * scale) / 2
            else:
                scale = canvas_h / orig_h
                offset_x, offset_y = (canvas_w - orig_w * scale) / 2, 0
        else:
            scale, offset_x, offset_y = 1.0, 0, 0

        # 3) 运行 OCR 获取组件 plan（复用 decompose 逻辑）
        loop = asyncio.get_event_loop()
        ocr = get_ocr()
        ocr_result = await loop.run_in_executor(None, ocr.ocr, tmp_path)

        raw_regions = []
        if ocr_result and len(ocr_result) > 0:
            r = ocr_result[0]
            texts = r.get('rec_texts', []) or []
            scores = r.get('rec_scores', []) or []
            boxes = r.get('rec_boxes')
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
                    crop = pil_src.crop((x1, y1, x2, y2))
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
                        cr = int(np.mean(tp[:, 0]))
                        cg = int(np.mean(tp[:, 1]))
                        cb = int(np.mean(tp[:, 2]))
                        text_color = f"#{cr:02x}{cg:02x}{cb:02x}"

                    cx = round(offset_x + x1 * scale, 1)
                    cy = round(offset_y + y1 * scale, 1)
                    cw = round((x2 - x1) * scale, 1)
                    ch = round((y2 - y1) * scale, 1)

                    raw_regions.append({
                        "text": clean, "confidence": round(float(sc), 3),
                        "color": text_color,
                        "bbox_px": (x1, y1, x2, y2),
                        "bounds_canvas": {"x": cx, "y": cy, "width": cw, "height": ch},
                        "font_size_est": max(10, int(ch * 0.75)),
                    })

        # 4) 分组 + 密度合并（复用 decompose 的 _merge_into_panels）
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

        # 密度合并：将密集文本组簇合并为面板
        text_groups, _ = _merge_into_panels(text_groups)

        # 5) 构建组件列表 + 生成透明 PNG
        img_bgr = cv2.cvtColor(src_np[:, :, :3], cv2.COLOR_RGB2BGR)
        assets = []
        layers_dir = GEN_DIR / "layers"
        layers_dir.mkdir(parents=True, exist_ok=True)

        # 背景层（直接复制全图）
        bg_path = layers_dir / "background.png"
        pil_src.save(str(bg_path))
        assets.append({
            "file": "background.png",
            "type": "background",
            "label": "背景",
            "bounds": {"x": 0, "y": 0, "width": canvas_w or orig_w, "height": canvas_h or orig_h},
            "zIndex": 0,
            "completion": 1.0,
            "uncertainty": "none",
        })

        # 文本组 → 组件
        z_base = 10
        for gi, group in enumerate(text_groups):
            # 各组件的像素坐标 bounds
            if "bounds_canvas" in group:
                # 已合并的面板：从画布坐标反推像素坐标
                cb = group["bounds_canvas"]
                gx = int((cb["x"] - offset_x) / scale)
                gy = int((cb["y"] - offset_y) / scale)
                gw = int(cb["width"] / scale)
                gh = int(cb["height"] / scale)
                # 用合并后的文字作为 label
                label = group["text"][:30]
                # 已合并密集文本 → playlist-panel
                ltype = "playlist-panel"
            else:
                # 普通文本组
                xs, ys = [], []
                for r in group if isinstance(group, list) else [group]:
                    b = r["bbox_px"]
                    xs.extend([b[0], b[2]])
                    ys.extend([b[1], b[3]])
                gx, gy = min(xs), min(ys)
                gx2, gy2 = max(xs), max(ys)
                gw, gh = gx2 - gx, gy2 - gy
                if gh < 10 or gw < 10:
                    continue
                ly_h = gh
                if ly_h > 80:
                    ltype = "title"
                elif ly_h < 25:
                    ltype = "label"
                else:
                    ltype = "text"
                label = " ".join(r["text"] for r in (group if isinstance(group, list) else [group]))[:30]

            # 主要组件（title / playlist-panel）：用 GrabCut 生成 mask
            # 小型组件（label / text）：直接羽化矩形
            use_grabcut = ltype in ("playlist-panel", "title")

            if not use_grabcut:
                # 小型文字：直接矩形 + 2px 羽化
                crop_mask = np.ones((gh, gw), dtype=np.uint8) * 255
                crop_mask = _feather_mask_edge(crop_mask, feather_px=2)
                crop_src = src_np[gy:gy+gh, gx:gw+gx].copy()
                if crop_src.shape[2] == 4:
                    crop_src[:, :, 3] = crop_mask
                else:
                    crop_src = np.dstack([crop_src, crop_mask])
                asset_img = Image.fromarray(crop_src)
                completion = 1.0
                uncertainty = "low"
                actual_bounds = (gx, gy, gw, gh)
            else:
                # 主要组件：GrabCut mask
                padding = max(8, int(min(gw, gh) * 0.08))
                px = max(0, gx - padding)
                py = max(0, gy - padding)
                pw = min(orig_w - px, gw + padding * 2)
                ph = min(orig_h - py, gh + padding * 2)

                full_mask = _generate_mask_grabcut(img_bgr, gx, gy, gw, gh, padding)
                result = _extract_asset(src_np, full_mask, px, py, pw, ph)
                if result[0] is None:
                    continue
                asset_img, actual_bounds = result
                completion = 0.95
                uncertainty = "low"

            # 保存 PNG
            filename = f"layer-{gi}.png"
            filepath = layers_dir / filename
            asset_img.save(str(filepath), "PNG")

            # 画布坐标
            cb = {
                "x": round(offset_x + actual_bounds[0] * scale, 1),
                "y": round(offset_y + actual_bounds[1] * scale, 1),
                "width": round(actual_bounds[2] * scale, 1),
                "height": round(actual_bounds[3] * scale, 1),
            }

            assets.append({
                "file": filename,
                "type": ltype,
                "label": label,
                "bounds": cb,
                "zIndex": gi + z_base,
                "completion": completion,
                "uncertainty": uncertainty,
            })

        # 6) 写 manifest
        manifest = {
            "source": {"width": orig_w, "height": orig_h},
            "canvas": {"width": canvas_w or orig_w, "height": canvas_h or orig_h},
            "assets": assets,
            "created_at": time.strftime("%Y-%m-%dT%H:%M:%S.000Z", time.gmtime()),
        }
        manifest_path = layers_dir / "manifest.json"
        with open(manifest_path, "w", encoding="utf-8") as f:
            json.dump(manifest, f, ensure_ascii=False, indent=2)

        print(f"[BuildAssets] {len(assets)} 个资产 → layers/manifest.json")
        return BuildAssetsResponse(
            ok=True,
            source={"width": orig_w, "height": orig_h},
            assets=assets,
            manifest_url="/generated/layers/manifest.json",
        )

    except Exception as e:
        import traceback
        traceback.print_exc()
        return BuildAssetsResponse(ok=False, error=str(e))
    finally:
        if os.path.exists(tmp_path):
            os.unlink(tmp_path)


# ── 文字擦除（P1b 快速 OpenCV 修补） ──────────────────
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
