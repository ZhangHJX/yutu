"use client";

import { useState, useRef, useCallback, useEffect } from "react";
import FabricCanvas from "@/canvas/FabricCanvas";
import type { FabricCanvasHandle } from "@/canvas/FabricCanvas";
import type { DesignDocument, DesignComponent } from "@/core/DesignDocument";
import { saveDraft, loadDraft } from "@/data/storage";
import { mockAIGen } from "@/data/mockAI";

const AI_API_BASE = process.env.NEXT_PUBLIC_AI_API_BASE || "";

async function callAIGenerate(
  prompt: string, scene: string, width: number, height: number
): Promise<{ document: DesignDocument; imageUrl: string }> {
  const res = await fetch(`${AI_API_BASE}/api/ai/generate`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ prompt, scene, style: "modern", width, height }),
  });
  const data = await res.json();
  if (!data.ok) {
    throw new Error(data.error || "AI 生成失败");
  }
  return { document: data.document as DesignDocument, imageUrl: data.image_url as string };
}

/** 调用 V2 透明 PNG 资产拆分接口 */
async function callBuildAssets(
  imageUrl: string, canvasW: number, canvasH: number, runId: string
): Promise<any> {
  const fullUrl = imageUrl.startsWith("http") ? imageUrl : `${window.location.origin}${imageUrl}`;
  const res = await fetch(`${AI_API_BASE}/api/ai/build-assets`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ image_url: fullUrl, canvas_width: canvasW, canvas_height: canvasH, run_id: runId }),
  });
  const data = await res.json();
  if (!data.ok) throw new Error(data.error || "图层拆分失败");
  return data;
}

interface EditorPageProps {
  canvasConfig: { width: number; height: number; background: string };
  initialDoc?: DesignDocument;
  draftId?: string;
  onBack: () => void;
}

/* ===== 文字属性预设 ===== */
const FONTS = ["sans-serif", "Arial", "Helvetica", "Georgia", "Times New Roman", "Courier New", "PingFang SC", "Microsoft YaHei"];
const FONT_SIZES = [8, 10, 12, 14, 16, 18, 20, 24, 28, 32, 36, 42, 48, 56, 64, 72];
const SHAPES = [
  { key: "rect", label: "矩形", icon: "▬" },
  { key: "rounded-rect", label: "圆角矩形", icon: "▭" },
  { key: "circle", label: "圆形", icon: "○" },
  { key: "triangle", label: "三角形", icon: "△" },
  { key: "line", label: "线条", icon: "─" },
  { key: "circle-outline", label: "空心圆", icon: "◯" },
];

const MATERIAL_IMAGES = [
  { id: "m1", name: "渐变背景1", color: "#6C5CE7" },
  { id: "m2", name: "渐变背景2", color: "#00CEC9" },
  { id: "m3", name: "纹理1", color: "#FD79A8" },
  { id: "m4", name: "纹理2", color: "#FDCB6E" },
  { id: "m5", name: "图案1", color: "#A29BFE" },
  { id: "m6", name: "图案2", color: "#FF7675" },
];

function createBlankDoc(c: { width: number; height: number; background: string }): DesignDocument {
  return {
    version: 1,
    canvas: { ...c },
    components: [],
    meta: { name: "未命名设计", scene: "custom", tags: [], createdAt: new Date().toISOString() },
  };
}

export default function EditorPage({ canvasConfig, initialDoc, draftId, onBack }: EditorPageProps) {
  const canvasRef = useRef<FabricCanvasHandle>(null);
  const [doc, setDoc] = useState<DesignDocument>(() => {
    if (initialDoc) return initialDoc;
    if (draftId) { const s = loadDraft(draftId); if (s) return s; }
    return createBlankDoc(canvasConfig);
  });
  const [selectedId, setSelectedId] = useState<string | null>(null);
  const [draftName, setDraftName] = useState(doc.meta.name);
  const [saved, setSaved] = useState(false);
  const [zoom, setZoom] = useState(1);
  const [showLayers, setShowLayers] = useState(false);
  const [showExport, setShowExport] = useState(false);
  const [showShapes, setShowShapes] = useState(false);
  const [showImagePicker, setShowImagePicker] = useState(false);
  const [showAI, setShowAI] = useState(false);
  const [aiPrompt, setAiPrompt] = useState("");
  const [aiScene, setAiScene] = useState<"avatar" | "background" | "live_decoration" | "poster" | "custom">("poster");
  const [aiLoading, setAiLoading] = useState(false);
  const [aiError, setAiError] = useState<string | null>(null);

  /* ---- 资产拆分状态 ---- */
  interface AssetInfo {
    type: string;
    label: string;
    zIndex: number;
    completion: number;
    uncertainty: string;
    hitBounds?: { x: number; y: number; width: number; height: number };
  }
  const [splitStatus, setSplitStatus] = useState<"idle" | "running" | "done" | "error">("idle");
  const [splitCount, setSplitCount] = useState(0);
  const splitTriggeredRef = useRef<string | null>(null);
  const [hiddenLayers, setHiddenLayers] = useState<Set<string>>(new Set());
  const [assetInfoMap, setAssetInfoMap] = useState<Map<string, AssetInfo>>(new Map());

  /* ---- 调试信息 ────────────────────── */
  const BUILD_VER = "2026-05-06-15:03";
  const hasImageComp = doc.components.some((c) => c.type === "image");
  const imageComp = doc.components.find((c) => c.type === "image");

  // 首次 mount 时打印文档信息
  useEffect(() => {
    console.log("[EditorPage] 文档信息:", {
      version: doc.version,
      canvas: doc.canvas,
      components: doc.components.map((c) => ({ id: c.id, type: c.type, content: c.content?.slice?.(0, 60) })),
      initialDoc: !!initialDoc,
      draftId,
    });
  }, []);

  /* ---- 首次加载时适配画布到可视区域（AI 文档进入编辑器） ---- */
  useEffect(() => {
    if (initialDoc && canvasRef.current) {
      // 双 rAF 确保布局已稳定
      const raf = requestAnimationFrame(() => {
        requestAnimationFrame(() => {
          canvasRef.current?.zoomToFit();
        });
      });
      return () => cancelAnimationFrame(raf);
    }
  }, []);

  /** 窗口/屏幕方向变化时重新适配（修复手机端裁切） */
  useEffect(() => {
    const onResize = () => {
      if (canvasRef.current) {
        requestAnimationFrame(() => {
          requestAnimationFrame(() => {
            canvasRef.current?.zoomToFit();
          });
        });
      }
    };
    window.addEventListener('resize', onResize);
    window.addEventListener('orientationchange', onResize);
    return () => {
      window.removeEventListener('resize', onResize);
      window.removeEventListener('orientationchange', onResize);
    };
  }, []);

  /** 拆分成功/失败后 3 秒清除状态 */
  useEffect(() => {
    if (splitStatus === "done" || splitStatus === "error") {
      const t = setTimeout(() => setSplitStatus("idle"), 3000);
      return () => clearTimeout(t);
    }
  }, [splitStatus]);

  /** 进入编辑器时自动调用 build-assets 拆分透明 PNG 资产层 */
  useEffect(() => {
    const imgComp = doc.components.find(
      (c) => c.type === "image" && c.x === 0 && c.y === 0 &&
      c.width === doc.canvas.width && c.height === doc.canvas.height
    );
    if (!imgComp?.content) return;

    // 已有资产层 → 跳过
    if (doc.components.some((c) => c.id.startsWith("asset-"))) return;
    // 正在处理同一张图 → 跳过
    if (splitTriggeredRef.current === imgComp.content) return;

    splitTriggeredRef.current = imgComp.content;
    setSplitStatus("running");

    const runId = imgComp.id.replace(/[^a-zA-Z0-9_-]/g, "-");
    callBuildAssets(imgComp.content, doc.canvas.width, doc.canvas.height, runId)
      .then((result: any) => {
        const assets = result.assets || [];
        // 按 zIndex 排序保证渲染顺序
        const sorted = [...assets].sort((a: any, b: any) => a.zIndex - b.zIndex);

        // ── 调试打印：每个资产的坐标闭环 ──
        console.log("[BuildAssets] 资产坐标调试:");
        sorted.forEach((a: any, i: number) => {
          console.log(
            `  [${i}] ${a.type} "${a.label?.slice?.(0, 20)}"` +
            `  bounds_canvas=(x=${a.bounds.x} y=${a.bounds.y} w=${a.bounds.width} h=${a.bounds.height})` +
            `  file=${a.file} zIndex=${a.zIndex}`
          );
        });

        const assetComponents: DesignComponent[] = [];
        const infoMap = new Map<string, AssetInfo>();

        sorted.forEach((a: any, i: number) => {
          const id = `asset-${runId}-${i}`;
          assetComponents.push({
            id,
            type: "image",
            x: a.bounds.x,
            y: a.bounds.y,
            width: a.bounds.width,
            height: a.bounds.height,
            content: `/generated/${a.file}`,
            editable: true,
            editableProperties: [],
            slot: null,
            style: { assetType: a.type },
          });
          infoMap.set(id, {
            type: a.type,
            label: a.label,
            zIndex: a.zIndex,
            completion: a.completion,
            uncertainty: a.uncertainty,
            hitBounds: a.hitBounds,
          });
        });

        if (assetComponents.length === 0) {
          setSplitCount(0);
          setSplitStatus("done");
          return;
        }

        setAssetInfoMap(infoMap);
        setDoc((prev) => {
          // 移除原全画幅图片组件（已由 assets 中的 background 替代）
          const filtered = prev.components.filter((c) => !(
            c.type === "image" &&
            c.x === 0 && c.y === 0 &&
            c.width === prev.canvas.width &&
            c.height === prev.canvas.height
          ));
          return { ...prev, components: [...filtered, ...assetComponents] };
        });
        setSplitCount(assetComponents.length);
        setSplitStatus("done");
      })
      .catch((e) => {
        console.error("[BuildAssets] 拆分失败:", e);
        setSplitStatus("error");
      });
  }, [doc]);

  /** 文字擦除（已停用，改为视觉平面拆分路线）
  useEffect(() => {
    ...
  }, [doc]);
  */

  /* ---- 选中组件的快捷引用 ---- */
  const selectedComp = selectedId ? doc.components.find((c) => c.id === selectedId) ?? null : null;
  const isTextSelected = selectedComp?.type === "text" && selectedComp.editable;

  /* ---- 操作函数 ---- */
  const handleSave = useCallback(() => {
    saveDraft({ ...doc, meta: { ...doc.meta, name: draftName } });
    setSaved(true);
    setTimeout(() => setSaved(false), 1500);
  }, [doc, draftName]);

  const handleBack = () => {
    saveDraft({ ...doc, meta: { ...doc.meta, name: draftName } });
    onBack();
  };

  const updateDoc = (updater: (prev: DesignDocument) => DesignDocument) => {
    setDoc(updater);
  };

  const handleComponentModify = (id: string, changes: Record<string, unknown>) => {
    updateDoc((prev) => ({
      ...prev,
      components: prev.components.map((c) => (c.id === id ? { ...c, ...changes } : c)),
    }));
  };

  const updateSelectedStyle = (styleChanges: Record<string, unknown>) => {
    if (!selectedId) return;
    updateDoc((prev) => ({
      ...prev,
      components: prev.components.map((c) =>
        c.id === selectedId ? { ...c, style: { ...c.style, ...styleChanges } } : c
      ),
    }));
  };

  const updateSelectedContent = (content: string) => {
    if (!selectedId) return;
    updateDoc((prev) => ({
      ...prev,
      components: prev.components.map((c) => (c.id === selectedId ? { ...c, content } : c)),
    }));
  };

  /* ---- 添加组件 ---- */
  const handleAddText = () => {
    const id = `text-${Date.now()}`;
    updateDoc((prev) => ({
      ...prev,
      components: [...prev.components, {
        id, type: "text" as const, editable: true, editableProperties: [],
        slot: null, x: 40, y: 80, width: 200, height: 40,
        style: { fontSize: 24, color: "#2D3436" },
        content: "双击编辑文字",
      }],
    }));
    setSelectedId(id);
  };

  const handleAddShape = (shapeType: string) => {
    const id = `shape-${Date.now()}`;
    setShowShapes(false);
    updateDoc((prev) => ({
      ...prev,
      components: [...prev.components, {
        id, type: "shape" as const, editable: true, editableProperties: [],
        slot: null, x: 60, y: 120, width: 120, height: shapeType === "line" ? 4 : 80,
        style: { shapeType, fill: "#A29BFE", borderRadius: 0 },
        content: "",
      }],
    }));
    setSelectedId(id);
  };

  const handleAddImage = (src: string) => {
    const id = `img-${Date.now()}`;
    setShowImagePicker(false);
    updateDoc((prev) => ({
      ...prev,
      components: [...prev.components, {
        id, type: "image" as const, editable: true, editableProperties: [],
        slot: null, x: 40, y: 80, width: 200, height: 200,
        style: {},
        content: src,
      }],
    }));
    setSelectedId(id);
  };

  const handleDelete = () => {
    if (!selectedId) return;
    updateDoc((prev) => ({
      ...prev,
      components: prev.components.filter((c) => c.id !== selectedId),
    }));
    setSelectedId(null);
  };

  /* ---- 图层操作 ---- */
  const handleLayerSelect = (id: string) => setSelectedId(id);
  const handleLayerDelete = (id: string) => {
    updateDoc((prev) => ({
      ...prev, components: prev.components.filter((c) => c.id !== id),
    }));
    if (selectedId === id) setSelectedId(null);
  };
  const handleLayerMove = (index: number, direction: "up" | "down") => {
    updateDoc((prev) => {
      const comps = [...prev.components];
      const targetIdx = comps.findIndex((c) => c.id === selectedId);
      if (targetIdx < 0) return prev;
      const newIdx = direction === "up" ? targetIdx + 1 : targetIdx - 1;
      if (newIdx < 0 || newIdx >= comps.length) return prev;
      [comps[targetIdx], comps[newIdx]] = [comps[newIdx], comps[targetIdx]];
      return { ...prev, components: comps };
    });
  };
  const handleToggleVisibility = (id: string) => {
    setHiddenLayers(prev => {
      const next = new Set(prev);
      if (next.has(id)) next.delete(id);
      else next.add(id);
      return next;
    });
  };

  /* ---- 选中组件渲染 ---- */
  const renderTextProps = () => {
    if (!isTextSelected || !selectedComp) return null;
    const s = selectedComp.style as Record<string, unknown>;

    return (
      <div className="text-props-panel">
        <div className="text-props-row">
          <select
            className="tp-select"
            value={(s.fontFamily as string) ?? "sans-serif"}
            onChange={(e) => updateSelectedStyle({ fontFamily: e.target.value })}
          >
            {FONTS.map((f) => (<option key={f} value={f}>{f}</option>))}
          </select>
          <select
            className="tp-select tp-size"
            value={(s.fontSize as number) ?? 24}
            onChange={(e) => updateSelectedStyle({ fontSize: Number(e.target.value) })}
          >
            {FONT_SIZES.map((sz) => (<option key={sz} value={sz}>{sz}</option>))}
          </select>
        </div>
        <div className="text-props-row">
          <ToggleBtn active={!!s.fontWeight && s.fontWeight !== "normal"} label="B" onClick={() => updateSelectedStyle({ fontWeight: (s.fontWeight as string) === "bold" ? "normal" : "bold" })} />
          <ToggleBtn active={!!s.fontStyle && s.fontStyle === "italic"} label="I" onClick={() => updateSelectedStyle({ fontStyle: (s.fontStyle as string) === "italic" ? "normal" : "italic" })} />
          <ToggleBtn active={!!s.underline} label="U" onClick={() => updateSelectedStyle({ underline: !s.underline })} />
          <ToggleBtn active={!!s.linethrough} label="S" onClick={() => updateSelectedStyle({ linethrough: !s.linethrough })} />
          <div className="tp-color-wrap">
            <input
              type="color"
              className="tp-color"
              value={(s.color as string) ?? "#000000"}
              onChange={(e) => updateSelectedStyle({ color: e.target.value })}
            />
            <span className="tp-color-label">颜色</span>
          </div>
        </div>
        <div className="text-props-row">
          {(["left", "center", "right"] as const).map((align) => (
            <ToggleBtn key={align} active={(s.textAlign as string) === align} label={align === "left" ? "⬅" : align === "center" ? "⥤" : "➡"} onClick={() => updateSelectedStyle({ textAlign: align })} />
          ))}
          <input
            type="number"
            className="tp-number"
            value={(s.lineHeight as number) ?? 1.2}
            min={0.5} max={3} step={0.1}
            onChange={(e) => updateSelectedStyle({ lineHeight: Number(e.target.value) })}
            style={{ width: 48 }}
          />
          <span className="tp-hint">行距</span>
        </div>
        <div className="text-props-row tp-content-row">
          <textarea
            className="tp-content"
            value={selectedComp.content}
            onChange={(e) => updateSelectedContent(e.target.value)}
            rows={2}
            placeholder="输入文字内容..."
          />
        </div>
      </div>
    );
  };

  const triggerZoomDrag = useRef(false);

  const handleZoomDown = useCallback((e: React.MouseEvent | React.TouchEvent) => {
    const el = e.currentTarget as HTMLElement;
    const track = el.closest(".zoom-track-h") as HTMLElement;
    if (!track) return;
    triggerZoomDrag.current = true;

    const update = (clientX: number) => {
      const rect = track.getBoundingClientRect();
      const pct = (clientX - rect.left) / rect.width;
      const newZoom = Math.max(0.1, Math.min(4, pct * 4));
      canvasRef.current?.setZoom(newZoom);
      setZoom(newZoom);
    };

    const cx = "touches" in e ? e.touches[0].clientX : e.clientX;
    update(cx);

    const onMove = (ev: MouseEvent | TouchEvent) => {
      const x = "touches" in ev ? ev.touches[0].clientX : ev.clientX;
      update(x);
    };
    const onUp = () => {
      triggerZoomDrag.current = false;
      document.removeEventListener("mousemove", onMove);
      document.removeEventListener("mouseup", onUp);
      document.removeEventListener("touchmove", onMove);
      document.removeEventListener("touchend", onUp);
    };
    document.addEventListener("mousemove", onMove);
    document.addEventListener("mouseup", onUp);
    document.addEventListener("touchmove", onMove, { passive: false });
    document.addEventListener("touchend", onUp);
  }, []);

  return (
    <div className="editor-screen">
      {/* 顶部栏 */}
      <div className="editor-header">
        <button className="editor-btn" onClick={handleBack}>‹ 返回</button>
        <div className="editor-title-area">
          <input className="editor-name-input" value={draftName} onChange={(e) => setDraftName(e.target.value)} placeholder="未命名设计" />
          <span className="editor-size">{canvasConfig.width}×{canvasConfig.height}</span>
        </div>
        <div className="editor-header-actions">
          <button className={`editor-btn editor-btn-save ${saved ? "saved" : ""}`} onClick={handleSave}>
            {saved ? "✓" : "保存"}
          </button>
        </div>
      </div>

      {/* 顶部缩放条（水平） */}
      <div className="zoom-bar-h">
        <button className="zoom-btn zoom-btn-h" onClick={() => {
          canvasRef.current?.zoomOut();
        }}>−</button>
        <div
          className="zoom-track-h"
          onMouseDown={handleZoomDown}
          onTouchStart={handleZoomDown}
        >
          <div className="zoom-thumb-h" style={{ left: `${(zoom / 4) * 100}%` }} />
        </div>
        <button className="zoom-btn zoom-btn-h" onClick={() => {
          canvasRef.current?.zoomIn();
        }}>+</button>
        <span className="zoom-label-h">{Math.round(zoom * 100)}%</span>
      </div>

      {/* 主编辑区 */}
      <div className="editor-main">
        {/* 左侧工具栏（默认展开） */}
        <div className="toolbar-left">
          <button className="tool-btn" onClick={handleAddText} title="文字">
            <svg viewBox="0 0 24 24" width="20" height="20" fill="none" stroke="currentColor" strokeWidth="2">
              <polyline points="4 7 4 4 20 4 20 7" /><line x1="9" y1="20" x2="15" y2="20" /><line x1="12" y1="4" x2="12" y2="20" />
            </svg>
            <span>文字</span>
          </button>
          <button className="tool-btn" onClick={() => setShowShapes(true)} title="形状">
            <svg viewBox="0 0 24 24" width="20" height="20" fill="none" stroke="currentColor" strokeWidth="2">
              <rect x="3" y="3" width="18" height="18" rx="2" />
            </svg>
            <span>形状</span>
          </button>
          <button className="tool-btn" onClick={() => setShowImagePicker(true)} title="图片">
            <svg viewBox="0 0 24 24" width="20" height="20" fill="none" stroke="currentColor" strokeWidth="2">
              <rect x="3" y="3" width="18" height="18" rx="2" /><circle cx="8.5" cy="8.5" r="1.5" /><polyline points="21 15 16 10 5 21" />
            </svg>
            <span>图片</span>
          </button>
          <button className="tool-btn" onClick={() => setShowAI(true)} title="AI">
            <svg viewBox="0 0 24 24" width="20" height="20" fill="none" stroke="currentColor" strokeWidth="2">
              <path d="M12 3c.5 2 2 3.5 4 4-2 .5-3.5 2-4 4-.5-2-2-3.5-4-4 2-.5 3.5-2 4-4z" /><path d="M19 14c.3 1.3 1.3 2.3 2.7 2.7-1.3.3-2.3 1.3-2.7 2.7-.3-1.3-1.3-2.3-2.7-2.7 1.3-.3 2.3-1.3 2.7-2.7z" /><path d="M5 14c.3 1.3 1.3 2.3 2.7 2.7-1.3.3-2.3 1.3-2.7 2.7-.3-1.3-1.3-2.3-2.7-2.7C3.7 16.3 4.7 15.3 5 14z" />
            </svg>
            <span>AI</span>
          </button>
          <button className="tool-btn" onClick={() => setShowExport(true)} title="导出">
            <svg viewBox="0 0 24 24" width="20" height="20" fill="none" stroke="currentColor" strokeWidth="2">
              <path d="M21 15v4a2 2 0 01-2 2H5a2 2 0 01-2-2v-4" /><polyline points="7 10 12 15 17 10" /><line x1="12" y1="15" x2="12" y2="3" />
            </svg>
            <span>导出</span>
          </button>
        </div>

        {/* 画布 */}
        <div className="editor-canvas">
          <FabricCanvas
            ref={canvasRef}
            document={doc}
            editable
            zoom={zoom}
            hiddenIds={hiddenLayers}
            onComponentSelect={(id) => setSelectedId(id)}
            onComponentModify={handleComponentModify}
            onZoomChange={(z) => setZoom(z)}
          />
        </div>

        {/* 右侧图层触发器（默认折叠） */}
        <div className="layer-trigger-right" onClick={() => setShowLayers(!showLayers)}>
          <span>≡</span>
        </div>

        {/* 右侧展开的图层面板 */}
        {showLayers && (
          <div className="layer-panel-right">
            <div className="layer-panel-header">
              <span>图层</span>
              <button className="layer-close" onClick={() => setShowLayers(false)}>✕</button>
            </div>
            <div className="layer-list">
              {doc.components.length === 0 && (
                <div className="layer-empty">暂无图层</div>
              )}
              {[...doc.components].reverse().map((comp, i) => {
                const assetInfo = comp.id.startsWith("asset-") ? assetInfoMap.get(comp.id) : null;
                const isHidden = hiddenLayers.has(comp.id);
                return (
                  <div
                    key={comp.id}
                    className={`layer-item ${selectedId === comp.id ? "active" : ""} ${isHidden ? "layer-hidden" : ""}`}
                    onClick={() => handleLayerSelect(comp.id)}
                  >
                    <button
                      className="layer-vis-btn"
                      onClick={(e) => { e.stopPropagation(); handleToggleVisibility(comp.id); }}
                    >
                      {isHidden ? "◯" : "●"}
                    </button>
                    <span className="layer-icon">
                      {assetInfo ? (
                        <span className={`layer-type-dot type-${assetInfo.type}`} />
                      ) : comp.type === "text" ? (
                        "T"
                      ) : comp.type === "image" ? (
                        "🖼"
                      ) : "▣"}
                    </span>
                    {assetInfo ? (
                      <span className="layer-name">
                        <span className="layer-type-label">{assetInfo.type}</span>
                        <span className="layer-asset-label">{assetInfo.label}</span>
                      </span>
                    ) : (
                      <span className="layer-name">{comp.type} {doc.components.length - i}</span>
                    )}
                  </div>
                );
              })}
            </div>
          </div>
        )}
      </div>

      {/* ── 调试信息浮条（总是显示，便于排查问题） ── */}
      <div className="debug-bar">
          <span>🛠 v{BUILD_VER}</span>
          <span>组件: {doc.components.length}</span>
          <span>类型: {doc.components.map((c) => c.type).join(",")}</span>
          {imageComp && <span style={{ fontSize: 10, maxWidth: 200, overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }}>
            img: {imageComp.content}
          </span>}
        </div>

      {/* ── 诊断 &lt;img&gt;（当有 image 组件时隐藏加载同一 URL，检测图片本身能否显示） ── */}
      {imageComp?.content && (
        <img
          src={imageComp.content}
          alt="diag"
          style={{
            position: "fixed", bottom: 60, right: 8, zIndex: 9999,
            width: 48, height: 48, objectFit: "cover",
            border: "2px solid #e74c3c", borderRadius: 4,
            background: "#333",
          }}
          onLoad={() => console.log("[EditorPage] 诊断<img> 加载成功:", imageComp.content)}
          onError={() => console.error("[EditorPage] 诊断<img> 加载失败:", imageComp.content)}
        />
      )}

      {/* ── 拆分状态提示（3 秒自动消失） ── */}
      {splitStatus === "running" && (
        <div className="ocr-toast">🔍 正在拆分图层...</div>
      )}
      {splitStatus === "done" && splitCount > 0 && (
        <div className="ocr-toast ocr-toast-done">✅ 已拆分 {splitCount} 个资产层</div>
      )}
      {splitStatus === "error" && (
        <div className="ocr-toast ocr-toast-error">⚠️ 图层拆分失败</div>
      )}

      {/* 选中组件信息浮条 */}
      {selectedId && assetInfoMap.get(selectedId)?.hitBounds && (
        <div
          className="asset-hitbox"
          style={{
            left: `${assetInfoMap.get(selectedId)!.hitBounds!.x}px`,
            top: `${assetInfoMap.get(selectedId)!.hitBounds!.y}px`,
            width: `${assetInfoMap.get(selectedId)!.hitBounds!.width}px`,
            height: `${assetInfoMap.get(selectedId)!.hitBounds!.height}px`,
          }}
        />
      )}

      {selectedId && selectedComp && (
        <div className="editor-selected-info">
          <span>{selectedComp.type === "text" ? "📝" : selectedComp.type === "image" ? "🖼️" : "▣"} {selectedComp.type}</span>
          <div className="selected-actions">
            <button className="sel-btn sel-delete" onClick={handleDelete}>删除</button>
          </div>
        </div>
      )}

      {/* 文字属性面板（浮层） */}
      {renderTextProps()}

      {/* 形状选择弹窗 */}
      {showShapes && (
        <div className="tool-sheet-overlay" onClick={() => setShowShapes(false)}>
          <div className="tool-sheet" onClick={(e) => e.stopPropagation()}>
            <div className="tool-sheet-header">
              选择形状
              <button className="tool-sheet-close" onClick={() => setShowShapes(false)}>✕</button>
            </div>
            <div className="shape-grid">
              {SHAPES.map((sh) => (
                <button key={sh.key} className="shape-btn" onClick={() => handleAddShape(sh.key)}>
                  <span className="shape-icon">{sh.icon}</span>
                  <span className="shape-label">{sh.label}</span>
                </button>
              ))}
            </div>
          </div>
        </div>
      )}

      {/* 图片选择弹窗 */}
      {showImagePicker && (
        <div className="tool-sheet-overlay" onClick={() => setShowImagePicker(false)}>
          <div className="tool-sheet" onClick={(e) => e.stopPropagation()}>
            <div className="tool-sheet-header">
              选择图片来源
              <button className="tool-sheet-close" onClick={() => setShowImagePicker(false)}>✕</button>
            </div>
            <div className="img-source-section">
              <h4 className="img-source-title">本地上传</h4>
              <div className="img-upload-area" onClick={() => alert("本地上传功能 (UI 预览)")}>
                <span className="img-upload-icon">📁</span>
                <span>点击选择本地图片</span>
              </div>
            </div>
            <div className="img-source-section">
              <h4 className="img-source-title">素材库</h4>
              <div className="material-grid">
                {MATERIAL_IMAGES.map((m) => (
                  <button key={m.id} className="material-btn" onClick={() => handleAddImage(`material://${m.id}`)}>
                    <div className="material-preview" style={{ background: m.color }} />
                    <span className="material-name">{m.name}</span>
                  </button>
                ))}
              </div>
            </div>
          </div>
        </div>
      )}

      {/* 导出弹窗 */}
      {showExport && (
        <div className="tool-sheet-overlay" onClick={() => setShowExport(false)}>
          <div className="tool-sheet" onClick={(e) => e.stopPropagation()}>
            <div className="tool-sheet-header">
              导出
              <button className="tool-sheet-close" onClick={() => setShowExport(false)}>✕</button>
            </div>
            <div className="export-section">
              <h4 className="img-source-title">导出格式</h4>
              <div className="export-format-list">
                {["PNG（推荐）", "JPG（较小体积）", "PNG 透明背景", "SVG（矢量）"].map((fmt) => (
                  <button key={fmt} className="export-format-btn" onClick={() => { setShowExport(false); alert(`导出格式: ${fmt}`); }}>
                    {fmt}
                  </button>
                ))}
              </div>
            </div>
            <div className="export-section">
              <h4 className="img-source-title">导出到</h4>
              <button className="export-app-btn" onClick={() => { setShowExport(false); alert("导出到双鱼 App"); }}>
                📱 导出到双鱼 App
              </button>
            </div>
          </div>
        </div>
      )}

      {/* AI 生成弹窗 */}
      {showAI && (
        <div className="tool-sheet-overlay" onClick={() => { if (!aiLoading) setShowAI(false); }}>
          <div className="tool-sheet" onClick={(e) => e.stopPropagation()}>
            <div className="tool-sheet-header">
              AI 生成设计
              <button className="tool-sheet-close" onClick={() => { if (!aiLoading) setShowAI(false); }}>✕</button>
            </div>
            <div className="ai-modal-section">
              <textarea
                className="ai-modal-input"
                value={aiPrompt}
                onChange={(e) => setAiPrompt(e.target.value)}
                placeholder="描述你的设计需求，例如：科技感海报，紫色主色调，简约风格..."
                rows={3}
                disabled={aiLoading}
              />
            </div>
            <div className="ai-modal-section">
              <h4 className="img-source-title">场景</h4>
              <div className="ai-modal-scenes">
                {([
                  { key: "poster", label: "海报" },
                  { key: "avatar", label: "头像" },
                  { key: "background", label: "壁纸" },
                  { key: "live_decoration", label: "直播" },
                ] as { key: "avatar" | "background" | "live_decoration" | "poster" | "custom"; label: string }[]).map((s) => (
                  <button
                    key={s.key}
                    className={`ai-modal-scene-btn ${aiScene === s.key ? "active" : ""}`}
                    onClick={() => setAiScene(s.key)}
                    disabled={aiLoading}
                  >
                    {s.label}
                  </button>
                ))}
              </div>
            </div>
            {aiError && (
              <div className="ai-modal-error">
                <span>❌ {aiError}</span>
                <button onClick={() => setAiError(null)}>关闭</button>
              </div>
            )}

            <button
              className="ai-modal-generate"
              onClick={async () => {
                if (!aiPrompt.trim() || aiLoading) return;
                setAiError(null);
                setAiLoading(true);
                const curW = doc.canvas.width;
                const curH = doc.canvas.height;

                // 🔧 测试 shortcut：跳过 API
                if (aiPrompt.trim() === "111") {
                  const newDoc: DesignDocument = {
                    version: 1,
                    canvas: { width: curW, height: curH, background: "#1a1a2e" },
                    components: [{
                      id: "ai-bg-source-poster",
                      type: "image",
                      x: 0, y: 0,
                      width: curW, height: curH,
                      content: "/generated/source-poster.png",
                      editable: true,
                      editableProperties: [],
                      slot: null,
                      style: {},
                    }],
                    meta: {
                      name: "测试素材",
                      scene: aiScene as DesignDocument["meta"]["scene"],
                      tags: ["ai", "test"],
                      createdAt: new Date().toISOString(),
                    },
                  };
                  setDoc(newDoc);
                  setShowAI(false);
                  setAiPrompt("");
                  setAiLoading(false);
                  // 适配画布到可视区域
                  requestAnimationFrame(() => {
                    requestAnimationFrame(() => canvasRef.current?.zoomToFit());
                  });
                  return;
                }

                try {
                  const { document: newDoc } = await callAIGenerate(
                    aiPrompt.trim(), aiScene, curW, curH
                  );
                  setDoc(newDoc);
                  setShowAI(false);
                  setAiPrompt("");
                  // 适配画布到可视区域
                  requestAnimationFrame(() => {
                    requestAnimationFrame(() => canvasRef.current?.zoomToFit());
                  });
                } catch (e) {
                  setAiError(e instanceof Error ? e.message : "AI 生成失败");
                  console.error("[EditorAI] 生成错误:", e);
                } finally {
                  setAiLoading(false);
                }
              }}
              disabled={aiLoading || !aiPrompt.trim()}
            >
              {aiLoading ? "✨ 生成中..." : "✨ AI 生成"}
            </button>

            <button
              className="ai-modal-mock"
              onClick={() => {
                if (!aiPrompt.trim() || aiLoading) return;
                setAiError(null);
                setAiLoading(true);
                const curW = doc.canvas.width;
                const curH = doc.canvas.height;
                setTimeout(() => {
                  const newDoc = mockAIGen({
                    prompt: aiPrompt.trim(),
                    scene: aiScene,
                    width: curW,
                    height: curH,
                  });
                  setDoc(newDoc);
                  setAiLoading(false);
                  setShowAI(false);
                  setAiPrompt("");
                }, 600);
              }}
              disabled={aiLoading || !aiPrompt.trim()}
            >
              调试模式
            </button>
          </div>
        </div>
      )}

      <style>{`
        .editor-header {
          height: 44px; background: #2d2d2d; display: flex; align-items: center;
          justify-content: space-between; padding: 0 12px; color: white; flex-shrink: 0; gap: 8px;
        }
        .editor-btn { background: none; border: none; color: white; font-size: 14px; padding: 6px 10px; cursor: pointer; white-space: nowrap; }
        .editor-title-area { flex: 1; display: flex; flex-direction: column; align-items: center; min-width: 0; }
        .editor-name-input { background: transparent; border: none; color: white; font-size: 14px; font-weight: 600; text-align: center; width: 100%; max-width: 160px; outline: none; }
        .editor-name-input::placeholder { color: #888; }
        .editor-size { font-size: 10px; color: #888; }
        .editor-header-actions { display: flex; gap: 4px; }
        .editor-btn-save { background: #6C5CE7; border-radius: 6px; font-size: 12px; padding: 4px 12px; transition: background 0.2s; }
        .editor-btn-save.saved { background: #27ae60; }

        /* 主编辑区 */
        .editor-main { flex: 1; display: flex; overflow: hidden; position: relative; background: #1a1a1a; }

        /* ===== 顶部水平缩放条（居中） ===== */
        .zoom-bar-h {
          height: 36px; background: #2d2d2d; display: flex; align-items: center;
          justify-content: center; gap: 8px; padding: 0 4px; flex-shrink: 0;
          border-bottom: 1px solid #444; user-select: none; -webkit-user-select: none;
        }
        .zoom-btn-h { background: none; border: none; color: #aaa; font-size: 18px; cursor: pointer; padding: 2px 6px; line-height: 1; user-select: none; -webkit-user-select: none; -webkit-touch-callout: none; }
        .zoom-btn-h:active { color: white; }
        .zoom-track-h { width: 120px; height: 4px; background: #555; border-radius: 2px; position: relative; cursor: pointer; flex-shrink: 0; touch-action: none; }
        .zoom-thumb-h { width: 14px; height: 14px; background: #A29BFE; border-radius: 50%; position: absolute; top: -5px; margin-left: -7px; pointer-events: none; }
        .zoom-label-h { color: #aaa; font-size: 11px; min-width: 36px; text-align: right; user-select: none; -webkit-user-select: none; }

        /* ===== 左侧工具栏（默认展开） ===== */
        .toolbar-left {
          width: 56px; background: #333; display: flex; flex-direction: column;
          align-items: center; gap: 2px; padding: 8px 0; flex-shrink: 0;
          border-right: 1px solid #444;
        }
        .tool-btn {
          display: flex; flex-direction: column; align-items: center; gap: 2px;
          background: none; border: none; color: #aaa; font-size: 10px;
          padding: 6px 4px; cursor: pointer; width: 48px; border-radius: 6px;
          -webkit-tap-highlight-color: transparent;
        }
        .tool-btn:active { background: #444; color: #A29BFE; }
        .tool-btn:active svg { stroke: #A29BFE; }

        /* ===== 右侧图层触发器（浮动按钮） ===== */
        .layer-trigger-right {
          position: absolute; right: 4px; top: 50%; transform: translateY(-50%);
          width: 28px; height: 60px; background: #333; display: flex; align-items: center; justify-content: center;
          cursor: pointer; color: #aaa; font-size: 18px; border-radius: 6px; z-index: 50;
          -webkit-tap-highlight-color: transparent;
        }
        .layer-trigger-right:active { background: #444; }

        /* 右侧展开的图层面板（绝对定位覆盖在画布上） */
        .layer-panel-right {
          position: absolute; right: 0; top: 0; bottom: 0;
          width: 160px; background: #2d2d2d; display: flex; flex-direction: column;
          border-left: 1px solid #444; z-index: 49; animation: slideInRight 0.2s ease-out;
        }
        @keyframes slideInRight { from { width: 0; opacity: 0; } to { width: 160px; opacity: 1; } }
        .layer-panel-header { display: flex; justify-content: space-between; align-items: center; padding: 8px 10px; color: #ccc; font-size: 13px; font-weight: 600; border-bottom: 1px solid #444; }
        .layer-close { background: none; border: none; color: #888; font-size: 14px; cursor: pointer; }
        .layer-list { flex: 1; overflow-y: auto; padding: 4px 0; }
        .layer-empty { padding: 20px; text-align: center; color: #666; font-size: 12px; }
        .layer-item { display: flex; align-items: center; gap: 6px; padding: 8px 10px; cursor: pointer; color: #aaa; font-size: 12px; border-left: 3px solid transparent; }
        .layer-item.active { background: rgba(108,92,231,0.15); color: #A29BFE; border-left-color: #6C5CE7; }
        .layer-item.layer-hidden { opacity: 0.4; }
        .layer-icon { width: 18px; text-align: center; font-size: 12px; flex-shrink: 0; }
        .layer-name { flex: 1; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; display: flex; flex-direction: column; gap: 1px; }
        .layer-btn { background: none; border: none; color: #666; font-size: 10px; cursor: pointer; padding: 2px 4px; }
        .layer-btn:hover { color: #e74c3c; }
        .layer-vis-btn { background: none; border: none; color: #888; font-size: 10px; cursor: pointer; padding: 2px; flex-shrink: 0; width: 16px; text-align: center; }
        .layer-vis-btn:active { color: #A29BFE; }
        .layer-type-dot { display: inline-block; width: 8px; height: 8px; border-radius: 50%; }
        .layer-type-dot.type-playlist-panel { background: #6C5CE7; }
        .layer-type-dot.type-title { background: #00CEC9; }
        .layer-type-dot.type-label { background: #FDCB6E; }
        .layer-type-dot.type-background { background: #636e72; }
        .layer-type-label { font-size: 9px; color: #888; text-transform: uppercase; }
        .layer-asset-label { font-size: 10px; color: #ccc; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }

        /* 画布容器 */
        .editor-canvas { flex: 1; display: flex; align-items: center; justify-content: center; overflow: hidden; background: #1a1a1a; }
        .editor-canvas canvas { resize: none !important; user-select: none !important; -webkit-user-select: none !important; touch-action: none !important; }

        /* 选中信息浮条 */
        .editor-selected-info { background: #3d3d3d; color: #aaa; font-size: 12px; padding: 6px 16px; display: flex; align-items: center; justify-content: space-between; flex-shrink: 0; }
        .selected-actions { display: flex; gap: 6px; }
        .sel-btn { background: #555; color: #ccc; border: none; border-radius: 4px; font-size: 11px; padding: 2px 10px; cursor: pointer; }
        .sel-delete { background: #e74c3c; color: white; }

        /* 文字属性面板（浮层） */
        .text-props-panel {
          background: #2d2d2d; padding: 8px 12px;
          display: flex; flex-direction: column; gap: 6px; flex-shrink: 0;
          border-top: 1px solid #444;
        }
        .text-props-row { display: flex; align-items: center; gap: 6px; }
        .tp-select { background: #3d3d3d; color: white; border: 1px solid #555; border-radius: 4px; padding: 4px 6px; font-size: 12px; outline: none; flex: 1; }
        .tp-size { width: 56px; flex: none; }
        .tp-number { background: #3d3d3d; color: white; border: 1px solid #555; border-radius: 4px; padding: 4px 6px; font-size: 12px; outline: none; width: 40px; }
        .tp-toggle { background: #3d3d3d; color: #aaa; border: 1px solid #555; border-radius: 4px; padding: 4px 8px; font-size: 12px; cursor: pointer; font-weight: 600; min-width: 28px; text-align: center; }
        .tp-toggle.active { background: #6C5CE7; color: white; border-color: #6C5CE7; }
        .tp-color-wrap { display: flex; align-items: center; gap: 4px; }
        .tp-color { width: 24px; height: 24px; border: none; border-radius: 4px; padding: 0; cursor: pointer; background: none; }
        .tp-color-label { font-size: 11px; color: #888; }
        .tp-hint { font-size: 11px; color: #888; }
        .tp-content-row { padding-top: 4px; border-top: 1px solid #444; }
        .tp-content { width: 100%; background: #3d3d3d; color: white; border: 1px solid #555; border-radius: 4px; padding: 6px 8px; font-size: 13px; outline: none; resize: none; font-family: inherit; }

        /* 弹窗 */
        .tool-sheet-overlay { position: fixed; inset: 0; background: rgba(0,0,0,0.5); z-index: 400; display: flex; align-items: flex-end; }
        .tool-sheet { width: 100%; max-height: 60vh; background: #2d2d2d; border-radius: 16px 16px 0 0; padding: 16px 16px calc(48px + env(safe-area-inset-bottom, 0px)); overflow-y: auto; animation: slideUp 0.25s ease-out; }
        .tool-sheet-header { font-size: 16px; font-weight: 600; color: white; margin-bottom: 16px; display: flex; justify-content: space-between; align-items: center; }
        .tool-sheet-close { background: none; border: none; color: #888; font-size: 20px; cursor: pointer; padding: 4px 8px; line-height: 1; border-radius: 4px; }
        .tool-sheet-close:active { background: #444; color: white; }
        @keyframes slideUp { from { transform: translateY(100%); } to { transform: translateY(0); } }

        /* 形状网格 */
        .shape-grid { display: grid; grid-template-columns: repeat(3, 1fr); gap: 8px; }
        .shape-btn { display: flex; flex-direction: column; align-items: center; gap: 4px; padding: 16px 8px; background: #3d3d3d; border: 1px solid #555; border-radius: 10px; cursor: pointer; color: white; }
        .shape-btn:active { background: #4d4d4d; }
        .shape-icon { font-size: 24px; }
        .shape-label { font-size: 12px; color: #aaa; }

        /* 图片来源 */
        .img-source-section { margin-bottom: 16px; }
        .img-source-title { font-size: 13px; color: #aaa; margin-bottom: 8px; font-weight: 500; }
        .img-upload-area { display: flex; align-items: center; gap: 8px; padding: 16px; background: #3d3d3d; border: 2px dashed #555; border-radius: 10px; cursor: pointer; color: #aaa; font-size: 14px; justify-content: center; }
        .img-upload-area:active { border-color: #A29BFE; color: white; }
        .img-upload-icon { font-size: 24px; }
        .material-grid { display: grid; grid-template-columns: repeat(3, 1fr); gap: 8px; }
        .material-btn { display: flex; flex-direction: column; align-items: center; gap: 4px; padding: 8px; background: none; border: 1px solid #555; border-radius: 8px; cursor: pointer; color: white; }
        .material-btn:active { border-color: #A29BFE; }
        .material-preview { width: 100%; aspect-ratio: 1; border-radius: 6px; }
        .material-name { font-size: 11px; color: #aaa; }

        /* 导出 */
        .export-section { margin-bottom: 16px; }
        .export-format-list { display: flex; flex-direction: column; gap: 6px; }
        .export-format-btn { padding: 12px 16px; background: #3d3d3d; border: 1px solid #555; border-radius: 8px; color: white; font-size: 14px; text-align: left; cursor: pointer; }
        .export-format-btn:active { border-color: #A29BFE; }
        .export-app-btn { width: 100%; padding: 14px; background: #6C5CE7; border: none; border-radius: 10px; color: white; font-size: 15px; cursor: pointer; text-align: center; }
        .export-app-btn:active { opacity: 0.8; }

        .fabric-canvas-wrapper { display: flex; align-items: center; justify-content: center; width: 100%; height: 100%; overflow: hidden; touch-action: none; transform-origin: center center; }
        .fabric-stage { position: relative; flex-shrink: 0; }
        .fabric-loading { color: #666; font-size: 14px; }

        /* AI 弹窗 */
        .ai-modal-section { margin-bottom: 16px; }
        .ai-modal-input { width: 100%; background: #3d3d3d; border: 1px solid #555; border-radius: 8px; padding: 10px 12px; font-size: 14px; color: white; outline: none; resize: none; font-family: inherit; box-sizing: border-box; }
        .ai-modal-input:focus { border-color: #6C5CE7; }
        .ai-modal-input:disabled { opacity: 0.5; }
        .ai-modal-scenes { display: flex; gap: 8px; }
        .ai-modal-scene-btn { flex: 1; padding: 8px; background: #3d3d3d; border: 1px solid #555; border-radius: 6px; color: #aaa; font-size: 13px; cursor: pointer; text-align: center; }
        .ai-modal-scene-btn.active { background: rgba(108,92,231,0.2); border-color: #6C5CE7; color: #A29BFE; }
        .ai-modal-scene-btn:disabled { opacity: 0.5; }
        .ai-modal-error { display: flex; align-items: center; gap: 8px; padding: 10px; background: rgba(231,76,60,0.15); border: 1px solid rgba(231,76,60,0.3); border-radius: 6px; color: #e74c3c; font-size: 12px; margin-bottom: 12px; }
        .ai-modal-error button { margin-left: auto; background: none; border: none; color: #e74c3c; font-size: 11px; cursor: pointer; text-decoration: underline; }
        .ai-modal-generate { width: 100%; padding: 12px; background: #6C5CE7; border: none; border-radius: 8px; color: white; font-size: 15px; font-weight: 600; cursor: pointer; margin-top: 8px; }
        .ai-modal-generate:disabled { opacity: 0.5; cursor: not-allowed; }
        .ai-modal-mock { width: 100%; padding: 8px; background: none; border: 1px dashed #555; border-radius: 6px; color: #666; font-size: 12px; cursor: pointer; margin-top: 6px; }
        .ai-modal-mock:disabled { opacity: 0.4; cursor: not-allowed; }

        /* ── OCR 状态提示浮条 ── */
        .ocr-toast {
          position: fixed; top: 56px; left: 50%; transform: translateX(-50%);
          z-index: 9999; padding: 8px 18px; border-radius: 8px;
          background: rgba(0,0,0,0.85); color: white; font-size: 13px;
          font-weight: 500; white-space: nowrap;
          animation: ocrFadeIn 0.3s ease;
          pointer-events: none;
        }
        .ocr-toast-done { background: rgba(39, 174, 96, 0.9); }
        .ocr-toast-error { background: rgba(231, 76, 60, 0.9); }
        .asset-hitbox {
          position: absolute;
          border: 2px dashed #00CEC9;
          background: rgba(0, 206, 201, 0.12);
          pointer-events: none;
          z-index: 45;
          box-shadow: 0 0 0 1px rgba(0,0,0,0.35);
        }
        @keyframes ocrFadeIn {
          from { opacity: 0; transform: translateX(-50%) translateY(-8px); }
          to { opacity: 1; transform: translateX(-50%) translateY(0); }
        }

        /* ── 调试信息浮条 ── */
        .debug-bar {
          position: fixed; bottom: 0; left: 0; right: 0; z-index: 9998;
          display: flex; align-items: center; gap: 8px;
          padding: 3px 8px; background: rgba(0,0,0,0.8);
          color: #0f0; font-size: 11px; font-family: monospace;
          overflow-x: auto; white-space: nowrap;
        }
      `}</style>
    </div>
  );
}

/** 切换按钮组件 */
function ToggleBtn({ active, label, onClick }: { active: boolean; label: string; onClick: () => void }) {
  return (
    <button className={`tp-toggle ${active ? "active" : ""}`} onClick={onClick}>
      {label}
    </button>
  );
}
