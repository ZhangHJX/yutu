"use client";

import { useRef, useEffect, useState, useCallback, forwardRef, useImperativeHandle } from "react";
import { Canvas, Rect, Textbox, Ellipse, Triangle, FabricImage, FabricObject } from "fabric";
import type { DesignDocument, DesignComponent } from "@/core/DesignDocument";

interface FabricCanvasProps {
  document: DesignDocument;
  editable?: boolean;
  zoom?: number;
  hiddenIds?: Set<string>;
  selectedId?: string | null;
  selectedHitBounds?: { x: number; y: number; width: number; height: number } | null;
  onComponentSelect?: (id: string | null) => void;
  onComponentModify?: (id: string, changes: Partial<DesignComponent>) => void;
  onZoomChange?: (zoom: number) => void;
}

export interface FabricCanvasHandle {
  setZoom: (level: number) => void;
  getZoom: () => number;
  zoomToFit: () => void;
  zoomIn: () => void;
  zoomOut: () => void;
  exportJSON: () => unknown;
}

const MIN_ZOOM = 0.1;
const MAX_ZOOM = 10;

const FabricCanvas = forwardRef<FabricCanvasHandle, FabricCanvasProps>(function FabricCanvas(
  { document, editable = false, zoom: controlledZoom, hiddenIds, selectedId, selectedHitBounds, onComponentSelect, onComponentModify, onZoomChange },
  ref
) {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const wrapperRef = useRef<HTMLDivElement>(null);
  const fabricRef = useRef<Canvas | null>(null);
  const idMapRef = useRef<Map<string, FabricObject>>(new Map());
  const [ready, setReady] = useState(false);
  const [pan, setPan] = useState({ x: 0, y: 0 });
  const lastPos = useRef({ x: 0, y: 0 });

  /** 初始化 Canvas */
  useEffect(() => {
    if (!canvasRef.current) return;

    const canvas = new Canvas(canvasRef.current, {
      width: document.canvas.width,
      height: document.canvas.height,
      backgroundColor: "transparent",
      selection: editable,
      preserveObjectStacking: true,
    });

    fabricRef.current = canvas;
    setReady(true);

    return () => {
      canvas.dispose();
      fabricRef.current = null;
      idMapRef.current.clear();
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [document.canvas.width, document.canvas.height]);

  /** 渲染组件 */
  useEffect(() => {
    const canvas = fabricRef.current;
    if (!canvas || !ready) return;

    console.log("[FabricCanvas] 渲染组件, document:", {
      components: document.components.length,
      canvas: document.canvas,
      meta: document.meta,
    });

    canvas.clear();
    idMapRef.current.clear();

    // 背景色矩形（始终在最底层）
    const bgRect = new Rect({
      left: 0, top: 0,
      originX: 'left', originY: 'top',
      width: document.canvas.width,
      height: document.canvas.height,
      fill: document.canvas.background,
      selectable: false,
      evented: false,
      excludeFromExport: true,
      hasControls: false,
      lockMovementX: true,
      lockMovementY: true,
      lockScalingX: true,
      lockScalingY: true,
      lockRotation: true,
      hoverCursor: 'default',
      moveCursor: 'default',
    });
    canvas.add(bgRect);

    // 调试边框：画布外框（白色 2px + 蓝色 1px 内侧）
    const cx = document.canvas.width;
    const cy = document.canvas.height;
    const outerBorder = new Rect({
      left: 0, top: 0, originX: 'left', originY: 'top', width: cx, height: cy,
      fill: "transparent", stroke: "#FFFFFF", strokeWidth: 2,
      selectable: false, evented: false, excludeFromExport: true,
    });
    canvas.add(outerBorder);
    const innerBorder = new Rect({
      left: 1, top: 1, originX: 'left', originY: 'top', width: cx - 2, height: cy - 2,
      fill: "transparent", stroke: "#3498DB", strokeWidth: 1,
      selectable: false, evented: false, excludeFromExport: true,
    });
    canvas.add(innerBorder);

    // 所有组件均渲染为 Fabric 对象（不再跳过全画幅图片）
    document.components.forEach((comp) => {
      const obj = componentToFabric(comp, canvas, idMapRef.current);
      if (obj) {
        idMapRef.current.set(comp.id, obj);
        canvas.add(obj);
      }
    });

    canvas.requestRenderAll();

    // 首次渲染后应用可见性
    applyVisibility(hiddenIds);
  }, [document, ready]);

  /** 可见性切换：不重建 canvas，直接修改现有对象的 visible 属性 */
  const applyVisibility = useCallback((ids?: Set<string>) => {
    const canvas = fabricRef.current;
    if (!canvas || !ready) return;

    for (const [id, obj] of idMapRef.current) {
      const shouldHide = ids?.has(id) ?? false;
      const targetVisible = !shouldHide;
      if (obj.visible !== targetVisible) {
        obj.set({
          visible: targetVisible,
          selectable: targetVisible,
          evented: targetVisible,
        });
      }
    }

    canvas.requestRenderAll();
  }, [ready, document]);

  /** 可见性变更时直接切换，不触发主渲染循环 */
  useEffect(() => {
    applyVisibility(hiddenIds);
  }, [hiddenIds, applyVisibility]);

  useEffect(() => {
    const canvas = fabricRef.current;
    if (!canvas || !editable || !ready) return;

    for (const [id, obj] of idMapRef.current) {
      const component = document.components.find((c) => c.id === id);
      const isBackgroundAsset = component?.style?.assetType === "background";
      if (isBackgroundAsset) continue;
      const enabled = !(hiddenIds?.has(id) ?? false) && (selectedId ? id === selectedId : true);
      obj.set({ selectable: enabled, evented: enabled });
    }

    if (selectedId && !(hiddenIds?.has(selectedId) ?? false)) {
      const obj = idMapRef.current.get(selectedId);
      if (obj) canvas.setActiveObject(obj);
    } else {
      canvas.discardActiveObject();
    }
    canvas.requestRenderAll();
  }, [document.components, editable, hiddenIds, ready, selectedId]);

  /** 鼠标滚轮缩放（CSS transform 模式 — 只调 onZoomChange，不碰 Fabric zoom） */
  useEffect(() => {
    const canvas = fabricRef.current;
    if (!canvas) return;

    const onWheel = (opt: { e: WheelEvent }) => {
      const delta = opt.e.deltaY;
      const current = controlledZoom ?? 1;
      let newZoom = current * (0.999 ** delta);
      newZoom = Math.min(MAX_ZOOM, Math.max(MIN_ZOOM, newZoom));
      onZoomChange?.(newZoom);
      opt.e.preventDefault();
      opt.e.stopPropagation();
    };

    canvas.on("mouse:wheel", onWheel);
    return () => { canvas.off("mouse:wheel", onWheel); };
  }, [onZoomChange, controlledZoom]);

  /** Fabric 触控辅助：双指捏合缩放 */
  useEffect(() => {
    const canvas = fabricRef.current;
    if (!canvas) return;

    let pinchStartDist = 0;
    let pinchStartZoom = 1;

    const onMove = (opt: { e: any }) => {
      const e = opt.e;
      if (e.touches && e.touches.length === 2) {
        const dist = Math.hypot(
          e.touches[0].clientX - e.touches[1].clientX,
          e.touches[0].clientY - e.touches[1].clientY
        );
        if (pinchStartDist === 0) {
          pinchStartDist = dist;
          pinchStartZoom = controlledZoom ?? 1;
        } else {
          const scale = dist / pinchStartDist;
          const newZoom = Math.min(MAX_ZOOM, Math.max(MIN_ZOOM, pinchStartZoom * scale));
          onZoomChange?.(newZoom);
        }
        e.preventDefault();
        return;
      }
    };

    const onUp = () => {
      pinchStartDist = 0;
    };

    canvas.on("mouse:move" as any, onMove);
    canvas.on("mouse:up" as any, onUp);

    return () => {
      canvas.off("mouse:move" as any, onMove);
      canvas.off("mouse:up" as any, onUp);
    };
  }, [onZoomChange, controlledZoom]);

  /** 统一平移：画布空白区 + 暗区 + 鼠标 + 触控 */
  useEffect(() => {
    const wrapper = wrapperRef.current;
    const canvas = fabricRef.current;
    if (!wrapper || !canvas) return;

    let isPanning = false;
    let pendingPan: { x: number; y: number } | null = null;
    const winDoc = globalThis.document; // prop "document" shadows global

    const getXY = (e: MouseEvent | TouchEvent) => {
      const touches = (e as TouchEvent).touches;
      return touches
        ? { x: touches[0].clientX, y: touches[0].clientY }
        : { x: (e as MouseEvent).clientX, y: (e as MouseEvent).clientY };
    };

    const startPan = (pos: { x: number; y: number }) => {
      isPanning = true;
      pendingPan = null;
      lastPos.current = pos;
      canvas.selection = false;
    };

    const applyPan = (e: MouseEvent | TouchEvent) => {
      const pos = getXY(e);
      const dx = pos.x - lastPos.current.x;
      const dy = pos.y - lastPos.current.y;
      lastPos.current = pos;
      setPan(p => ({ x: p.x + dx, y: p.y + dy }));
      e.preventDefault();
    };

    const onDown = (e: MouseEvent | TouchEvent) => {
      const canvasEl = canvasRef.current;
      if (!canvasEl) return;
      const pos = getXY(e);
      const container = canvasEl.parentElement;
      const isOnCanvas = container?.contains(e.target as Node);

      if (isOnCanvas) {
        // 检查是否点在 Fabric 对象上 — 是则交给 Fabric 处理
        const fabricObj = canvas.findTarget(e);
        if (fabricObj) return;
        // 画布空白区域：触控等待阈值，鼠标立即平移
        if ('touches' in e) {
          pendingPan = pos;
        } else {
          startPan(pos);
        }
      } else {
        // 暗区：立即平移
        startPan(pos);
        e.preventDefault();
      }
    };

    const onMove = (e: MouseEvent | TouchEvent) => {
      if (isPanning) {
        applyPan(e);
        return;
      }
      // 触控等待突破阈值后进入平移
      if (pendingPan) {
        const pos = getXY(e);
        const dx = pos.x - pendingPan.x;
        const dy = pos.y - pendingPan.y;
        if (Math.abs(dx) > 5 || Math.abs(dy) > 5) {
          startPan(pendingPan);
          setPan(p => ({ x: p.x + dx, y: p.y + dy }));
          lastPos.current = pos;
          e.preventDefault();
        }
      }
    };

    const onUp = () => {
      isPanning = false;
      pendingPan = null;
      canvas.selection = editable;
    };

    wrapper.addEventListener('mousedown', onDown);
    wrapper.addEventListener('touchstart', onDown, { passive: false });
    winDoc.addEventListener('mousemove', onMove);
    winDoc.addEventListener('mouseup', onUp);
    winDoc.addEventListener('touchmove', onMove, { passive: false });
    winDoc.addEventListener('touchend', onUp);

    return () => {
      wrapper.removeEventListener('mousedown', onDown);
      wrapper.removeEventListener('touchstart', onDown);
      winDoc.removeEventListener('mousemove', onMove);
      winDoc.removeEventListener('mouseup', onUp);
      winDoc.removeEventListener('touchmove', onMove);
      winDoc.removeEventListener('touchend', onUp);
    };
  }, [editable]);

  /** 选中事件 */
  useEffect(() => {
    const canvas = fabricRef.current;
    if (!canvas || !editable) return;

    const onSelect = () => {
      const active = canvas.getActiveObject();
      if (!active) { onComponentSelect?.(null); return; }
      for (const [id, obj] of idMapRef.current) {
        if (obj === active) { onComponentSelect?.(id); return; }
      }
      onComponentSelect?.(null);
    };

    canvas.on("selection:created", onSelect);
    canvas.on("selection:updated", onSelect);
    canvas.on("selection:cleared", onSelect);
    return () => {
      canvas.off("selection:created", onSelect);
      canvas.off("selection:updated", onSelect);
      canvas.off("selection:cleared", onSelect);
    };
  }, [editable, onComponentSelect]);

  /** 修改事件 */
  useEffect(() => {
    const canvas = fabricRef.current;
    if (!canvas || !editable) return;

    const onModified = () => {
      const active = canvas.getActiveObject();
      if (!active) return;
      for (const [id, obj] of idMapRef.current) {
        if (obj === active) {
          onComponentModify?.(id, {
            x: obj.left ?? 0,
            y: obj.top ?? 0,
            // ⚠️ 必须用 getScaledWidth() 而非 obj.width
            // FabricImage.width = PNG 自然宽（如 1024），不是组件逻辑宽（如 390）
            // 写 obj.width 会使下次渲染 scale≈1 → 图片全尺寸 → 只露右下角
            width: obj.getScaledWidth(),
            height: obj.getScaledHeight(),
            rotation: obj.angle,
            opacity: obj.opacity,
          });
          return;
        }
      }
    };

    canvas.on("object:modified", onModified);
    return () => { canvas.off("object:modified", onModified); };
  }, [editable, onComponentModify]);

  /** 暴露方法 */
  useImperativeHandle(ref, () => ({
    setZoom(level: number) {
      const z = Math.min(MAX_ZOOM, Math.max(MIN_ZOOM, level));
      onZoomChange?.(z);
    },
    getZoom() {
      return controlledZoom ?? 1;
    },
    zoomToFit() {
      const wrapper = wrapperRef.current;
      if (!wrapper) return;

      // 以 wrapper 父容器（editor-canvas）为基准计算适配缩放
      const container = wrapper.parentElement;
      if (!container) return;
      const rect = container.getBoundingClientRect();
      const padding = 32;
      const cw = document.canvas.width;
      const ch = document.canvas.height;
      const scaleX = (rect.width - padding) / cw;
      const scaleY = (rect.height - padding) / ch;
      let fitScale = Math.min(scaleX, scaleY);
      fitScale = Math.min(fitScale, 1);    // 不超过 1x
      fitScale = Math.max(fitScale, 0.1);  // 不低于 0.1x

      // 重置平移 + 缩放
      setPan({ x: 0, y: 0 });
      onZoomChange?.(fitScale);
    },
    zoomIn() {
      const current = controlledZoom ?? 1;
      let z = current * 1.2;
      z = Math.min(MAX_ZOOM, z);
      onZoomChange?.(z);
    },
    zoomOut() {
      const current = controlledZoom ?? 1;
      let z = current / 1.2;
      z = Math.max(MIN_ZOOM, z);
      onZoomChange?.(z);
    },
    exportJSON() {
      return fabricRef.current?.toJSON();
    },
  }), [onZoomChange, controlledZoom]);

  return (
    <div className="fabric-canvas-wrapper" ref={wrapperRef}>
      <div className="fabric-stage" style={{ position: 'relative', width: document.canvas.width, height: document.canvas.height, transform: `translate(${pan.x}px, ${pan.y}px) scale(${controlledZoom ?? 1})`, transformOrigin: 'center center' }}>
        <canvas ref={canvasRef} style={{ display: 'block' }} />
        {selectedHitBounds && (
          <div
            className="fabric-hitbox"
            style={{
              position: "absolute",
              left: selectedHitBounds.x,
              top: selectedHitBounds.y,
              width: selectedHitBounds.width,
              height: selectedHitBounds.height,
              border: "2px dashed #00CEC9",
              background: "rgba(0, 206, 201, 0.12)",
              pointerEvents: "none",
              zIndex: 10,
              boxShadow: "0 0 0 1px rgba(0,0,0,0.35)",
            }}
          />
        )}
      </div>
      {!ready && <div className="fabric-loading">加载画布...</div>}
    </div>
  );
});

export default FabricCanvas;

/* ===== DesignComponent → Fabric Object ===== */

function componentToFabric(comp: DesignComponent, canvas: Canvas, idMap?: Map<string, FabricObject>): FabricObject | null {
  const base = {
    left: comp.x,
    top: comp.y,
    originX: 'left' as const,
    originY: 'top' as const,
    width: comp.width,
    height: comp.height,
    angle: comp.rotation ?? 0,
    opacity: comp.opacity ?? 1,
  };

  switch (comp.type) {
    case "text": {
      const s = comp.style as Record<string, unknown>;
      return new Textbox(comp.content, {
        ...base,
        fontSize: (s.fontSize as number) ?? 24,
        fontFamily: (s.fontFamily as string) ?? "sans-serif",
        fill: (s.color as string) ?? "#000000",
        fontWeight: (s.fontWeight as string) ?? "normal",
        fontStyle: (s.fontStyle as "normal" | "italic" | "oblique") ?? "normal",
        underline: (s.underline as boolean) ?? false,
        linethrough: (s.linethrough as boolean) ?? false,
        textAlign: (s.textAlign as "left" | "center" | "right" | "justify") ?? "left",
        lineHeight: (s.lineHeight as number) ?? 1.2,
      });
    }

    case "image": {
      const imgPlaceholder = new Rect({ ...base, fill: "#DFE6E9", rx: 4, ry: 4 });
      if (comp.content) {
        // 所有图片组件都走 FabricImage 渲染
        // 全画幅图片（background 组件）→ 锁定不可编辑
        // 非全画幅图片（资产层）→ 可选/可拖/可缩放
        const canvasW = canvas.getWidth();
        const canvasH = canvas.getHeight();
        const isBackgroundAsset = comp.style?.assetType === "background";
        const absoluteUrl = new URL(comp.content, window.location.origin).toString();
        console.log(`[FabricCanvas] 手动加载图片: ${absoluteUrl}`);

        const imgEl = new window.Image();
        imgEl.onload = () => {
          const scaleX = comp.width / (imgEl.naturalWidth || 1);
          const scaleY = comp.height / (imgEl.naturalHeight || 1);
          console.log(`[FabricCanvas] 图片加载:`, {
            comp: { id: comp.id, x: comp.x, y: comp.y, w: comp.width, h: comp.height },
            pngNatural: { w: imgEl.naturalWidth, h: imgEl.naturalHeight },
            scale: { x: scaleX, y: scaleY, uniform: scaleX === scaleY ? scaleX : 'NON-UNIFORM' },
            isBackgroundAsset,
            url: absoluteUrl.slice(-40),
          });

          if (!imgPlaceholder.canvas) {
            console.warn("[FabricCanvas] 占位 Rect 已不在画布上，跳过");
            return;
          }

          const fabricImg = new FabricImage(imgEl);
          fabricImg.width = imgEl.naturalWidth;
          fabricImg.height = imgEl.naturalHeight;

          // 如果 placeholder 已被 canvas.clear() 移除，跳过（跨渲染周期）
          if (imgPlaceholder.canvas !== canvas) {
            console.warn("[FabricCanvas] 占位 Rect 已不在画布上，跳过");
            return;
          }
          // 用 canvas 参数操作（不用 imgPlaceholder.canvas，因为 remove 后会置 null）
          canvas.remove(imgPlaceholder);
          fabricImg.set({
            left: comp.x,
            top: comp.y,
            originX: 'left',
            originY: 'top',
            scaleX,
            scaleY,
            selectable: !isBackgroundAsset,
            evented: !isBackgroundAsset,
            hasControls: !isBackgroundAsset,
            lockMovementX: isBackgroundAsset,
            lockMovementY: isBackgroundAsset,
            lockScalingX: isBackgroundAsset,
            lockScalingY: isBackgroundAsset,
            lockRotation: isBackgroundAsset,
            lockUniScaling: !isBackgroundAsset, // 拖动控制点不改变宽高比
            hoverCursor: isBackgroundAsset ? "default" : "move",
          });
          canvas.add(fabricImg);

          // 更新 idMap：把 comp.id 指向真实的 FabricImage
          if (idMap) {
            idMap.set(comp.id, fabricImg);
          }

          canvas.requestRenderAll();
          console.log("[FabricCanvas] 图片已添加到画布，idMap 已更新");
        };

        imgEl.onerror = (err) => {
          console.error(`[FabricCanvas] 图片加载失败: ${absoluteUrl}`, err);
          // 画布上显示错误标记
          const errLabel = new Textbox("⚠️ 图片加载失败", {
            left: 8, top: 8,
            width: Math.max(160, comp.width - 16),
            fontSize: 14,
            fill: "#e74c3c",
            backgroundColor: "rgba(0,0,0,0.6)",
            selectable: false,
            evented: false,
          });
          canvas.add(errLabel);
          canvas.requestRenderAll();
        };

        imgEl.src = absoluteUrl;
      }
      return imgPlaceholder;
    }

    case "shape": {
      const s = comp.style as Record<string, unknown>;
      const shapeType = (s.shapeType as string) ?? "rect";
      const fill = (s.fill as string) ?? "#6C5CE7";
      const stroke = (s.stroke as string) ?? undefined;
      const strokeWidth = (s.strokeWidth as number) ?? 0;

      switch (shapeType) {
        case "circle":
        case "ellipse":
          return new Ellipse({ ...base, rx: base.width / 2, ry: base.height / 2, fill, stroke, strokeWidth });
        case "triangle":
          return new Triangle({ ...base, fill, stroke, strokeWidth });
        case "star": {
          // 五角星用 Polygon，但 Fabric 7 可能没有直接支持，用 Triangle 替代
          return new Triangle({ ...base, fill, stroke, strokeWidth });
        }
        case "line": {
          return new Rect({ ...base, height: 4, fill, rx: 2, ry: 2, stroke, strokeWidth });
        }
        case "rounded-rect":
          return new Rect({ ...base, rx: 16, ry: 16, fill, stroke, strokeWidth });
        case "circle-outline":
          return new Ellipse({ ...base, rx: base.width / 2, ry: base.height / 2, fill: "transparent", stroke: fill, strokeWidth: 3 });
        default:
          return new Rect({ ...base, rx: (s.borderRadius as number) ?? 0, ry: (s.borderRadius as number) ?? 0, fill, stroke, strokeWidth });
      }
    }

    case "group":
      return new Rect({ ...base, fill: "transparent", stroke: "#999", strokeDashArray: [4, 4] });

    default:
      return null;
  }
}
