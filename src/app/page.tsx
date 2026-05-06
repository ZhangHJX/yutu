"use client";

import { useState, useEffect } from "react";
import dynamic from "next/dynamic";
import HomeScreen from "@/screens/HomeScreen";
import ProfileScreen from "@/screens/ProfileScreen";
import NotificationsScreen from "@/screens/NotificationsScreen";
import { loadDraft } from "@/data/storage";
import type { DesignDocument } from "@/core/DesignDocument";

const EditorPage = dynamic(() => import("@/components/EditorPage"), { ssr: false });
const AIPage = dynamic(() => import("@/components/AIPage"), { ssr: false });

type Tab = "home" | "create" | "notifications" | "profile";

interface CanvasConfig {
  width: number;
  height: number;
  background: string;
}

const PRESETS: { label: string; sub: string; width: number; height: number }[] = [
  { label: "头像", sub: "1:1 方形", width: 400, height: 400 },
  { label: "海报", sub: "9:16 竖版", width: 390, height: 844 },
  { label: "背景", sub: "16:9 横版", width: 800, height: 450 },
  { label: "直播装饰", sub: "自定义尺寸", width: 800, height: 600 },
  { label: "自由创作", sub: "空白画布", width: 390, height: 844 },
];

export default function Home() {
  const [tab, setTab] = useState<Tab>("home");
  const [inEditor, setInEditor] = useState(false);
  const [showCreateSheet, setShowCreateSheet] = useState(false);
  const [canvasConfig, setCanvasConfig] = useState<CanvasConfig | null>(null);
  const [draftId, setDraftId] = useState<string | undefined>(undefined);
  const [refreshTick, setRefreshTick] = useState(0);
  const [aiDoc, setAiDoc] = useState<DesignDocument | null>(null);
  const [showAI, setShowAI] = useState(false);
  // React ready 标识（hydration 确认）
  const [reactReady, setReactReady] = useState(false);
  useEffect(() => { setReactReady(true); console.log("React mounted"); }, []);

  const handleCreateCanvas = (preset: (typeof PRESETS)[number]) => {
    setCanvasConfig({ width: preset.width, height: preset.height, background: "#FFFFFF" });
    setDraftId(undefined);
    setAiDoc(null);
    setShowCreateSheet(false);
    setInEditor(true);
  };

  const handleOpenDraft = (id: string) => {
    const doc = loadDraft(id);
    if (!doc) return;
    setCanvasConfig({
      width: doc.canvas.width,
      height: doc.canvas.height,
      background: doc.canvas.background,
    });
    setDraftId(id);
    setAiDoc(null);
    setInEditor(true);
  };

  const handleAIGenerate = (doc: DesignDocument) => {
    setAiDoc(doc);
    setCanvasConfig({ width: doc.canvas.width, height: doc.canvas.height, background: doc.canvas.background });
    setDraftId(undefined);
    setShowAI(false);
    setInEditor(true);
  };

  const handleExitEditor = () => {
    setRefreshTick((t) => t + 1);
    setInEditor(false);
    setDraftId(undefined);
    setAiDoc(null);
  };

  if (showAI) {
    return <AIPage onGenerate={handleAIGenerate} onBack={() => setShowAI(false)} />;
  }

  if (inEditor && canvasConfig) {
    return (
      <EditorPage
        canvasConfig={canvasConfig}
        initialDoc={aiDoc ?? undefined}
        draftId={draftId}
        onBack={handleExitEditor}
      />
    );
  }

  return (
    <div className="screen">
      {/* 页面内容 */}
      <div className="screen-body">
        {tab === "home" && (
          <HomeScreen
            onCreate={() => setShowCreateSheet(true)}
            onOpenDraft={handleOpenDraft}
            refreshTick={refreshTick}
          />
        )}
        {tab === "notifications" && <NotificationsScreen />}
        {tab === "profile" && <ProfileScreen onOpenDraft={handleOpenDraft} />}
      </div>

      {/* 浮动创建按钮（首页展示） */}
      {tab === "home" && (
        <button className="fab" onClick={() => setShowCreateSheet(true)}>
          +
        </button>
      )}

      {/* 底部标签栏 */}
      <nav className="bottom-tabs">
        {([
          { key: "home", label: "首页", icon: HomeIcon },
          { key: "create", label: "创作", icon: CreateIcon },
          { key: "notifications", label: "消息", icon: NotifIcon },
          { key: "profile", label: "我的", icon: ProfileIcon },
        ] as const).map(({ key, label, icon: Icon }) => (
          <button
            key={key}
            className={`tab-btn ${tab === key ? "active" : ""}`}
            onClick={() => {
              if (key === "create") {
                setShowCreateSheet(true);
              } else {
                setTab(key);
              }
            }}
          >
            <Icon active={tab === key} />
            <span>{label}</span>
          </button>
        ))}
      </nav>

      {/* 创建画布底部弹窗 */}
      {showCreateSheet && (
        <div className="sheet-overlay" onClick={() => setShowCreateSheet(false)}>
          <div className="sheet" onClick={(e) => e.stopPropagation()}>
            <div className="sheet-header">
              <span>选择画布尺寸</span>
              <button className="sheet-close" onClick={() => setShowCreateSheet(false)}>
                取消
              </button>
            </div>
            <div className="sheet-presets">
              <button className="preset-btn ai-preset-btn" onClick={() => { setShowCreateSheet(false); setShowAI(true); }}>
                <div className="preset-thumb ai-preset-thumb">✨</div>
                <div className="preset-info">
                  <div className="preset-label">AI 创作</div>
                  <div className="preset-sub">输入描述，AI 生成可编辑设计</div>
                </div>
              </button>
              <div className="sheet-divider" />
              {PRESETS.map((preset) => (
                <button
                  key={preset.label}
                  className="preset-btn"
                  onClick={() => handleCreateCanvas(preset)}
                >
                  <div className="preset-thumb" style={{
                    width: preset.width > preset.height ? 48 : 36,
                    height: preset.height > preset.width ? 48 : 36,
                  }} />
                  <div className="preset-info">
                    <div className="preset-label">{preset.label}</div>
                    <div className="preset-sub">{preset.sub}</div>
                  </div>
                </button>
              ))}
            </div>
          </div>
        </div>
      )}

      {/* 创建弹窗样式 */}
      <style>{`
        .sheet-overlay {
          position: fixed;
          inset: 0;
          background: rgba(0,0,0,0.4);
          z-index: 300;
          display: flex;
          align-items: flex-end;
        }
        .sheet {
          width: 100%;
          max-height: 60vh;
          background: var(--bg-card);
          border-radius: 16px 16px 0 0;
          padding: 16px 0 calc(56px + env(safe-area-inset-bottom, 0px));
          animation: slideUp 0.25s ease-out;
        }
        @keyframes slideUp {
          from { transform: translateY(100%); }
          to { transform: translateY(0); }
        }
        .sheet-header {
          display: flex;
          justify-content: space-between;
          align-items: center;
          padding: 0 16px 16px;
          font-weight: 600;
          font-size: 16px;
        }
        .sheet-close {
          background: none;
          border: none;
          font-size: 14px;
          color: var(--primary);
          cursor: pointer;
        }
        .sheet-presets {
          display: flex;
          flex-direction: column;
          gap: 2px;
        }
        .preset-btn {
          display: flex;
          align-items: center;
          gap: 12px;
          padding: 12px 16px;
          background: none;
          border: none;
          cursor: pointer;
          -webkit-tap-highlight-color: transparent;
        }
        .preset-btn:active {
          background: var(--bg);
        }
        .preset-thumb {
          border: 1px solid var(--border);
          border-radius: 4px;
          background: var(--bg);
          flex-shrink: 0;
        }
        .preset-info {
          text-align: left;
        }
        .preset-label {
          font-size: 15px;
          font-weight: 500;
          color: var(--text);
        }
        .preset-sub {
          font-size: 12px;
          color: var(--text-secondary);
          margin-top: 2px;
        }
        .sheet-divider {
          height: 1px; background: var(--border); margin: 8px 16px;
        }
        .ai-preset-btn { border-radius: 8px; background: rgba(108,92,231,0.08); margin-bottom: 4px; }
        .ai-preset-btn:active { background: rgba(108,92,231,0.15) !important; }
        .ai-preset-thumb {
          display: flex; align-items: center; justify-content: center;
          font-size: 20px; border: none !important;
        }
      `}</style>
    </div>
  );
}

/* 底部标签图标（SVG内联） */
function HomeIcon({ active }: { active: boolean }) {
  return (
    <svg viewBox="0 0 24 24" fill={active ? "#6C5CE7" : "#999"} stroke="none">
      <path d="M12 3L4 9v12h5v-7h6v7h5V9z" />
    </svg>
  );
}

function CreateIcon({ active }: { active: boolean }) {
  return (
    <svg viewBox="0 0 24 24" fill="none" stroke={active ? "#6C5CE7" : "#999"} strokeWidth="2">
      <rect x="3" y="3" width="18" height="18" rx="3" />
      <line x1="12" y1="8" x2="12" y2="16" />
      <line x1="8" y1="12" x2="16" y2="12" />
    </svg>
  );
}

function NotifIcon({ active }: { active: boolean }) {
  return (
    <svg viewBox="0 0 24 24" fill="none" stroke={active ? "#6C5CE7" : "#999"} strokeWidth="2">
      <path d="M18 8A6 6 0 006 8c0 7-3 9-3 9h18s-3-2-3-9" />
      <path d="M13.73 21a2 2 0 01-3.46 0" />
    </svg>
  );
}

function ProfileIcon({ active }: { active: boolean }) {
  return (
    <svg viewBox="0 0 24 24" fill="none" stroke={active ? "#6C5CE7" : "#999"} strokeWidth="2">
      <circle cx="12" cy="8" r="4" />
      <path d="M4 20c0-4 3.6-8 8-8s8 4 8 8" />
    </svg>
  );
}
