import type { DesignDocument } from "@/core/DesignDocument";

export interface AIGenParams {
  prompt: string;
  scene: string;
  width: number;
  height: number;
}

export interface CanvasConfig {
  width: number;
  height: number;
  background: string;
}

/** 内联 SVG 渐变图片（避免外网依赖） */
function gradientSVG(w: number, h: number, c1: string, c2: string, deg = 135): string {
  return `data:image/svg+xml,${encodeURIComponent(`<svg xmlns="http://www.w3.org/2000/svg" width="${w}" height="${h}"><defs><linearGradient id="g" x1="0%" y1="0%" x2="100%" y2="100%"><stop offset="0%" stop-color="${c1}"/><stop offset="100%" stop-color="${c2}"/></linearGradient></defs><rect width="${w}" height="${h}" fill="url(#g)"/></svg>`)}`;
}

/** Mock AI 生成 — 按场景返回不同的 DesignDocument */
export function mockAIGen(params: AIGenParams): DesignDocument {
  const { scene, width, height } = params;

  const makeDoc = (
    background: string,
    bgImage: string | null,
    components: any[],
    name: string,
  ): DesignDocument => ({
    version: 1,
    canvas: { width, height, background },
    components: bgImage
      ? [
          {
            id: "ai-bg-img",
            type: "image",
            x: 0,
            y: 0,
            width,
            height,
            style: {},
            content: bgImage,
            editable: true,
            editableProperties: [],
            slot: null,
          } as any,
          ...components,
        ]
      : components,
    meta: { name, scene: scene as "avatar" | "background" | "live_decoration" | "poster" | "custom", tags: ["ai"], createdAt: new Date().toISOString() },
  });

  switch (scene) {
    /* ============ 头像 ============ */
    case "avatar":
      return makeDoc(
        "#2D3436",
        null,
        [
          { id: "av-circle", type: "shape", x: width / 2 - 60, y: 40, width: 120, height: 120, style: { shapeType: "circle", fill: "#6C5CE7" } },
          { id: "av-inner", type: "shape", x: width / 2 - 45, y: 55, width: 90, height: 90, style: { shapeType: "circle", fill: "#A29BFE" } },
          { id: "av-letter", type: "text", x: width / 2 - 20, y: 75, width: 40, height: 50, content: "A", style: { fontSize: 42, color: "#FFFFFF", fontWeight: "bold", textAlign: "center" } },
          { id: "av-name", type: "text", x: 20, y: 190, width: width - 40, height: 30, content: "用户名", style: { fontSize: 20, color: "#FFFFFF", fontWeight: "bold", textAlign: "center" } },
          { id: "av-bio", type: "text", x: 20, y: 225, width: width - 40, height: 40, content: "创意设计师", style: { fontSize: 14, color: "#A29BFE", textAlign: "center" } },
          { id: "av-tag-1", type: "shape", x: width / 2 - 55, y: 280, width: 110, height: 28, style: { shapeType: "rounded-rect", fill: "#6C5CE7", borderRadius: 14 } },
          { id: "av-tag-text", type: "text", x: width / 2 - 45, y: 284, width: 90, height: 20, content: "AI 生成", style: { fontSize: 12, color: "#FFFFFF", textAlign: "center" } },
        ],
        "AI 头像",
      );

    /* ============ 海报 ============ */
    case "poster":
      return makeDoc(
        "#1a1a2e",
        gradientSVG(width, height, "#1a1a2e", "#16213e"),
        [
          { id: "po-circle-1", type: "shape", x: width - 160, y: -40, width: 200, height: 200, style: { shapeType: "circle", fill: "#6C5CE7", opacity: 0.3 } },
          { id: "po-circle-2", type: "shape", x: -60, y: height - 140, width: 180, height: 180, style: { shapeType: "circle-outline", fill: "#FD79A8", stroke: "#FD79A8", strokeWidth: 2, opacity: 0.4 } },
          { id: "po-title", type: "text", x: 30, y: 100, width: width - 60, height: 60, content: "AI 生成海报", style: { fontSize: 34, color: "#FFFFFF", fontWeight: "bold", textAlign: "center" } },
          { id: "po-sub", type: "text", x: 30, y: 165, width: width - 60, height: 24, content: "用文字描述你的想法", style: { fontSize: 15, color: "#A29BFE", textAlign: "center" } },
          { id: "po-line", type: "shape", x: 60, y: 210, width: width - 120, height: 2, style: { shapeType: "line", fill: "#6C5CE7" } },
          { id: "po-body", type: "text", x: 30, y: 240, width: width - 60, height: 120, content: "语图（YuTu）让每个人都能轻松创作精美的设计。输入文字描述，AI 将为你生成可编辑的设计稿，直接修改文字、调整颜色。", style: { fontSize: 14, color: "#DFE6E9", lineHeight: 1.6 } },
          { id: "po-btn-bg", type: "shape", x: width / 2 - 80, y: 420, width: 160, height: 44, style: { shapeType: "rounded-rect", fill: "#6C5CE7", borderRadius: 22 } },
          { id: "po-btn-text", type: "text", x: width / 2 - 70, y: 430, width: 140, height: 24, content: "立即体验", style: { fontSize: 15, color: "#FFFFFF", fontWeight: "bold", textAlign: "center" } },
        ],
        "AI 海报设计",
      );

    /* ============ 背景/壁纸 ============ */
    case "background":
      return makeDoc(
        "#0a0a1a",
        gradientSVG(width, height, "#0a0a1a", "#1a1a3e"),
        [
          { id: "bg-dot-1", type: "shape", x: 30, y: 30, width: 40, height: 40, style: { shapeType: "circle", fill: "#6C5CE7", opacity: 0.5 } },
          { id: "bg-dot-2", type: "shape", x: width - 80, y: 80, width: 60, height: 60, style: { shapeType: "circle", fill: "#FD79A8", opacity: 0.3 } },
          { id: "bg-dot-3", type: "shape", x: 60, y: height - 120, width: 80, height: 80, style: { shapeType: "circle-outline", fill: "#A29BFE", stroke: "#A29BFE", opacity: 0.3 } },
          { id: "bg-dot-4", type: "shape", x: width - 100, y: height - 80, width: 30, height: 30, style: { shapeType: "circle", fill: "#00CEC9", opacity: 0.4 } },
          { id: "bg-line-1", type: "shape", x: 20, y: height / 2, width: width / 3, height: 1, style: { shapeType: "line", fill: "#6C5CE7", opacity: 0.3 } },
          { id: "bg-line-2", type: "shape", x: width * 0.55, y: height * 0.35, width: width / 4, height: 1, style: { shapeType: "line", fill: "#FD79A8", opacity: 0.3 } },
          { id: "bg-quote", type: "text", x: 30, y: height / 2 - 60, width: width - 60, height: 50, content: "设计 · 无限可能", style: { fontSize: 26, color: "#FFFFFF", fontWeight: "200", textAlign: "center" } },
          { id: "bg-sub", type: "text", x: 30, y: height / 2 + 10, width: width - 60, height: 20, content: "语图 AI 生成壁纸", style: { fontSize: 12, color: "#A29BFE", textAlign: "center" } },
        ],
        "AI 壁纸",
      );

    /* ============ 直播装饰 ============ */
    case "live_decoration":
    default:
      return makeDoc(
        "#0D0D1A",
        gradientSVG(width, height, "#0D0D1A", "#1A0A2E"),
        [
          { id: "lv-frame", type: "shape", x: 4, y: 4, width: width - 8, height: height - 8, style: { shapeType: "rounded-rect", fill: "transparent", stroke: "#6C5CE7", strokeWidth: 3, borderRadius: 16 } },
          { id: "lv-glint-1", type: "shape", x: 20, y: 20, width: 60, height: 3, style: { shapeType: "line", fill: "#FD79A8" } },
          { id: "lv-glint-2", type: "shape", x: width - 80, y: 20, width: 60, height: 3, style: { shapeType: "line", fill: "#00CEC9" } },
          { id: "lv-name", type: "text", x: 20, y: 60, width: width - 40, height: 40, content: "直播间标题", style: { fontSize: 28, color: "#FFFFFF", fontWeight: "bold", textAlign: "center" } },
          { id: "lv-host", type: "text", x: 20, y: 105, width: width - 40, height: 20, content: "主播昵称", style: { fontSize: 14, color: "#A29BFE", textAlign: "center" } },
          { id: "lv-badge", type: "shape", x: width / 2 - 50, y: 150, width: 100, height: 24, style: { shapeType: "rounded-rect", fill: "#FD79A8", borderRadius: 12 } },
          { id: "lv-badge-text", type: "text", x: width / 2 - 45, y: 153, width: 90, height: 18, content: "LIVE", style: { fontSize: 12, color: "#FFFFFF", fontWeight: "bold", textAlign: "center" } },
          { id: "lv-decoration-1", type: "shape", x: -30, y: height - 120, width: 100, height: 100, style: { shapeType: "circle-outline", fill: "#6C5CE7", stroke: "#6C5CE7", opacity: 0.2 } },
          { id: "lv-decoration-2", type: "shape", x: width - 70, y: height - 80, width: 60, height: 60, style: { shapeType: "circle", fill: "#00CEC9", opacity: 0.15 } },
        ],
        "AI 直播装饰",
      );
  }
}
