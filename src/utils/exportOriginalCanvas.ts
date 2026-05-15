import type { DesignComponent, DesignDocument } from "@/core/DesignDocument";

type CanvasElementType = "image" | "rectangle" | "ellipse" | "line" | "text";

interface ExportOptions {
  hiddenIds?: string[];
}

function number(value: unknown, fallback: number): number {
  return typeof value === "number" && Number.isFinite(value) ? value : fallback;
}

function alpha(value: unknown, fallback = 1): number {
  return Math.min(1, Math.max(0, number(value, fallback)));
}

function color(value: unknown, fallback: string): string {
  if (typeof value !== "string" || !value.trim()) return fallback;
  const raw = value.trim();
  const rgba = raw.match(/^rgba?\(([^)]+)\)$/i);
  if (!rgba) return raw;
  const parts = rgba[1].split(",").map((part) => Number(part.trim()));
  if (parts.length < 3 || parts.some((part) => Number.isNaN(part))) return fallback;
  return `#${parts.slice(0, 3).map((part) => Math.max(0, Math.min(255, Math.round(part))).toString(16).padStart(2, "0")).join("")}`;
}

function rgbaAlpha(value: unknown, fallback = 1): number {
  if (typeof value !== "string") return fallback;
  const rgba = value.trim().match(/^rgba?\(([^)]+)\)$/i);
  if (!rgba) return fallback;
  const parts = rgba[1].split(",").map((part) => Number(part.trim()));
  return parts.length >= 4 && !Number.isNaN(parts[3]) ? alpha(parts[3], fallback) : fallback;
}

function alignIndex(value: unknown): number {
  switch (value) {
    case "right":
      return 1;
    case "center":
      return 2;
    case "justify":
      return 3;
    case "start":
      return 4;
    case "end":
      return 5;
    default:
      return 0;
  }
}

function styleName(style: Record<string, unknown>): string {
  const weight = String(style.fontWeight ?? "").toLowerCase();
  const fontStyle = String(style.fontStyle ?? "").toLowerCase();
  if (fontStyle === "italic" || fontStyle === "oblique") return "Italic";
  if (weight === "bold" || Number(weight) >= 600) return "Bold";
  return "Regular";
}

function imageFilePath(content: string): string {
  const trimmed = content.trim();
  if (!trimmed) return "";
  try {
    return new URL(trimmed, "https://local.invalid").pathname.split("/").filter(Boolean).pop() ?? trimmed;
  } catch {
    return trimmed.split(/[\\/]/).filter(Boolean).pop() ?? trimmed;
  }
}

function elementType(component: DesignComponent): CanvasElementType {
  if (component.type === "image") return "image";
  if (component.type === "text") return "text";
  if (component.type === "shape") {
    const shapeType = String(component.style?.shapeType ?? "");
    if (shapeType === "line") return "line";
    if (shapeType === "circle" || shapeType === "circle-outline") return "ellipse";
    return "rectangle";
  }
  return "rectangle";
}

function toElement(component: DesignComponent, hiddenIds: Set<string>) {
  const style = component.style ?? {};
  const type = elementType(component);
  const shadow = typeof style.shadow === "object" && style.shadow !== null ? style.shadow as Record<string, unknown> : {};
  const rotation = number(component.rotation, 0) * Math.PI / 180;
  const opacity = alpha(component.opacity ?? style.opacity);
  const textShadowColor = color(shadow.color, "#D8D8D8");
  const borderColor = color(style.stroke ?? style.borderColor, "#D8D8D8");
  const borderWidth = Math.round(number(style.strokeWidth ?? style.borderWidth, 0));

  return {
    id: component.id,
    type,
    x: number(component.x, 0),
    y: number(component.y, 0),
    width: number(component.width, 0),
    height: number(component.height, 0),
    hidden: hiddenIds.has(component.id),
    locked: false,
    selected: false,
    filePath: type === "image" ? imageFilePath(component.content) : "",
    fileAlpha: type === "image" ? opacity : 1,
    fillColor: color(style.fill ?? style.color, "#D8D8D8"),
    fillAlpha: type !== "text" && type !== "image" ? opacity : 1,
    text: type === "text" ? component.content : "",
    fontSize: number(style.fontSize, 14),
    fontId: 0,
    familyKey: String(style.fontFamily ?? "sans-serif"),
    styleName: styleName(style),
    align: alignIndex(style.textAlign),
    lineHeight: number(style.lineHeight, 1),
    fontSpace: number(style.letterSpacing, 0),
    textColor: color(style.color, "#000000"),
    textAlpha: type === "text" ? opacity : 1,
    isShawOpen: Boolean(shadow.color) && number(shadow.blur, 0) > 0,
    shawColor: textShadowColor,
    shawX: number(shadow.offsetX, 0),
    shawY: number(shadow.offsetY, 0),
    blurValue: number(shadow.blur, 0),
    shawAlpha: rgbaAlpha(shadow.color, 1),
    borderColor,
    borderWidth,
    borderAlpha: borderWidth > 0 ? 1 : 0,
    rotation,
    scale: 1,
  };
}

export function toOriginalCanvasModel(document: DesignDocument, options: ExportOptions = {}) {
  const hiddenIds = new Set(options.hiddenIds ?? []);
  const width = number(document.canvas.width, 1080);
  const height = number(document.canvas.height, 1080);
  const sorted = document.components
    .map((component, index) => ({ component, index }))
    .sort((a, b) => number(a.component.style?.zIndex, a.index) - number(b.component.style?.zIndex, b.index));

  return {
    id: 0,
    userId: 0,
    uuid: crypto.randomUUID(),
    ratio: `${width}:${height}`,
    clarity: "0",
    x: 0,
    y: 0,
    scale: 1,
    width,
    height,
    fillColor: color(document.canvas.background, "#FFFFFF"),
    fillAlpha: 1,
    locked: false,
    isSelected: false,
    version: 1,
    timestamp: Math.floor(Date.now() / 1000),
    elements: sorted.map(({ component }) => toElement(component, hiddenIds)),
    title: document.meta.name,
    desc: document.meta.tags.join(","),
    sceneId: 0,
    tagData: [],
  };
}

export function downloadOriginalCanvasModel(doc: DesignDocument, hiddenIds: string[] = []) {
  const payload = toOriginalCanvasModel(doc, { hiddenIds });
  const blob = new Blob([JSON.stringify(payload, null, 2)], { type: "application/json;charset=utf-8" });
  const url = URL.createObjectURL(blob);
  const link = document.createElement("a");
  link.href = url;
  link.download = `${payload.title || "yutu-canvas"}.json`;
  document.body.appendChild(link);
  link.click();
  link.remove();
  URL.revokeObjectURL(url);
}
