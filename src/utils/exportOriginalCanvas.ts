import type { DesignComponent, DesignDocument } from "@/core/DesignDocument";

type CanvasElementType = "image" | "rectangle" | "ellipse" | "line" | "text";

interface ExportOptions {
  hiddenIds?: string[];
  imageFileNames?: Record<string, string>;
}

interface ZipEntry {
  path: string;
  data: Uint8Array;
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

function safeFileName(value: string, fallback: string): string {
  const name = value.replace(/[<>:"/\\|?*\u0000-\u001f]/g, "_").trim();
  return name || fallback;
}

function imageFileName(component: DesignComponent, used: Set<string>): string {
  const fallback = `${component.id}.png`;
  const sourceName = safeFileName(imageFilePath(component.content), fallback);
  const withExtension = /\.[a-z0-9]{2,5}$/i.test(sourceName) ? sourceName : `${sourceName}.png`;
  const dot = withExtension.lastIndexOf(".");
  const base = dot > 0 ? withExtension.slice(0, dot) : withExtension;
  const ext = dot > 0 ? withExtension.slice(dot) : ".png";
  let candidate = withExtension;
  let index = 2;
  while (used.has(candidate)) {
    candidate = `${base}-${index}${ext}`;
    index += 1;
  }
  used.add(candidate);
  return candidate;
}

function imageUrl(content: string): string | null {
  const trimmed = content.trim();
  if (!trimmed) return null;
  if (/^https?:\/\//i.test(trimmed) || /^data:/i.test(trimmed)) return trimmed;
  if (trimmed.startsWith("/")) return new URL(trimmed, window.location.origin).href;
  return null;
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

function toElement(component: DesignComponent, hiddenIds: Set<string>, imageFileNames: Record<string, string>) {
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
    filePath: type === "image" ? imageFileNames[component.id] ?? imageFilePath(component.content) : "",
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
  const imageFileNames = options.imageFileNames ?? {};
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
    elements: sorted.map(({ component }) => toElement(component, hiddenIds, imageFileNames)),
    title: document.meta.name,
    desc: document.meta.tags.join(","),
    sceneId: 0,
    tagData: [],
  };
}

function crc32(data: Uint8Array): number {
  let crc = -1;
  for (const byte of data) {
    crc ^= byte;
    for (let bit = 0; bit < 8; bit += 1) {
      crc = (crc >>> 1) ^ (0xedb88320 & -(crc & 1));
    }
  }
  return (crc ^ -1) >>> 0;
}

function writeUint16(view: DataView, offset: number, value: number) {
  view.setUint16(offset, value, true);
}

function writeUint32(view: DataView, offset: number, value: number) {
  view.setUint32(offset, value, true);
}

function concat(parts: Uint8Array[]): Uint8Array {
  const total = parts.reduce((sum, part) => sum + part.length, 0);
  const output = new Uint8Array(total);
  let offset = 0;
  for (const part of parts) {
    output.set(part, offset);
    offset += part.length;
  }
  return output;
}

function zip(entries: ZipEntry[]): Uint8Array {
  const encoder = new TextEncoder();
  const now = new Date();
  const dosTime = (now.getHours() << 11) | (now.getMinutes() << 5) | Math.floor(now.getSeconds() / 2);
  const dosDate = ((now.getFullYear() - 1980) << 9) | ((now.getMonth() + 1) << 5) | now.getDate();
  const localParts: Uint8Array[] = [];
  const centralParts: Uint8Array[] = [];
  let offset = 0;

  for (const entry of entries) {
    const name = encoder.encode(entry.path);
    const checksum = crc32(entry.data);
    const local = new Uint8Array(30 + name.length);
    const localView = new DataView(local.buffer);
    writeUint32(localView, 0, 0x04034b50);
    writeUint16(localView, 4, 20);
    writeUint16(localView, 6, 0x0800);
    writeUint16(localView, 8, 0);
    writeUint16(localView, 10, dosTime);
    writeUint16(localView, 12, dosDate);
    writeUint32(localView, 14, checksum);
    writeUint32(localView, 18, entry.data.length);
    writeUint32(localView, 22, entry.data.length);
    writeUint16(localView, 26, name.length);
    local.set(name, 30);
    localParts.push(local, entry.data);

    const central = new Uint8Array(46 + name.length);
    const centralView = new DataView(central.buffer);
    writeUint32(centralView, 0, 0x02014b50);
    writeUint16(centralView, 4, 20);
    writeUint16(centralView, 6, 20);
    writeUint16(centralView, 8, 0x0800);
    writeUint16(centralView, 10, 0);
    writeUint16(centralView, 12, dosTime);
    writeUint16(centralView, 14, dosDate);
    writeUint32(centralView, 16, checksum);
    writeUint32(centralView, 20, entry.data.length);
    writeUint32(centralView, 24, entry.data.length);
    writeUint16(centralView, 28, name.length);
    writeUint32(centralView, 42, offset);
    central.set(name, 46);
    centralParts.push(central);

    offset += local.length + entry.data.length;
  }

  const central = concat(centralParts);
  const end = new Uint8Array(22);
  const endView = new DataView(end.buffer);
  writeUint32(endView, 0, 0x06054b50);
  writeUint16(endView, 8, entries.length);
  writeUint16(endView, 10, entries.length);
  writeUint32(endView, 12, central.length);
  writeUint32(endView, 16, offset);

  return concat([...localParts, central, end]);
}

async function imageEntries(doc: DesignDocument, imageFileNames: Record<string, string>): Promise<ZipEntry[]> {
  const entries: ZipEntry[] = [];
  for (const component of doc.components) {
    if (component.type !== "image" || !component.content.trim()) continue;
    const url = imageUrl(component.content);
    if (!url) {
      throw new Error(`Cannot package image asset: ${component.content}`);
    }
    const response = await fetch(url);
    if (!response.ok) {
      throw new Error(`Cannot fetch image asset: ${component.content}`);
    }
    entries.push({
      path: `images/${imageFileNames[component.id]}`,
      data: new Uint8Array(await response.arrayBuffer()),
    });
  }
  return entries;
}

function imageFileNames(doc: DesignDocument): Record<string, string> {
  const used = new Set<string>();
  return Object.fromEntries(
    doc.components
      .filter((component) => component.type === "image" && component.content.trim())
      .map((component) => [component.id, imageFileName(component, used)])
  );
}

function downloadBlob(blob: Blob, fileName: string) {
  const url = URL.createObjectURL(blob);
  const link = document.createElement("a");
  link.href = url;
  link.download = fileName;
  document.body.appendChild(link);
  link.click();
  link.remove();
  URL.revokeObjectURL(url);
}

export async function downloadOriginalCanvasModel(doc: DesignDocument, hiddenIds: string[] = []) {
  const names = imageFileNames(doc);
  const payload = toOriginalCanvasModel(doc, { hiddenIds, imageFileNames: names });
  const draft = new TextEncoder().encode(JSON.stringify(payload, null, 2));
  const packed = zip([
    { path: "draft.json", data: draft },
    ...await imageEntries(doc, names),
  ]);
  const archive = new ArrayBuffer(packed.byteLength);
  new Uint8Array(archive).set(packed);
  const blob = new Blob([archive], { type: "application/zip" });
  downloadBlob(blob, `${payload.title || "yutu-canvas"}.original-yutu.zip`);
}
