"use client";

import { useState, useCallback } from "react";
import type { DesignDocument } from "@/core/DesignDocument";
import { mockAIGen } from "@/data/mockAI";

interface AIPageProps {
  onGenerate: (doc: DesignDocument) => void;
  onBack: () => void;
}

/* ===== 场景预设 ===== */
const SCENES: { key: "avatar" | "background" | "live_decoration" | "poster" | "custom"; label: string; icon: string; desc: string }[] = [
  { key: "poster", label: "海报", icon: "🎨", desc: "9:16 竖版海报" },
  { key: "avatar", label: "头像", icon: "👤", desc: "1:1 方形头像" },
  { key: "background", label: "壁纸", icon: "🖼", desc: "背景/壁纸" },
  { key: "live_decoration", label: "直播装饰", icon: "🔴", desc: "直播场景装饰" },
];

const COLORS = ["#6C5CE7", "#FD79A8", "#00CEC9", "#FDCB6E", "#E17055", "#00B894"];

const SIZES: Record<string, { width: number; height: number }> = {
  poster: { width: 390, height: 600 },
  avatar: { width: 400, height: 400 },
  background: { width: 800, height: 450 },
  live_decoration: { width: 800, height: 600 },
};

interface GenerateResult {
  document: DesignDocument;
  imageUrl: string;
}

/* ===== 真实 AI 生成 ===== */
const API_BASE = process.env.NEXT_PUBLIC_AI_API_BASE || "";

async function generateAI(
  prompt: string, scene: string, style: string, width: number, height: number
): Promise<GenerateResult> {
  const res = await fetch(`${API_BASE}/api/ai/generate`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ prompt, scene, style, width, height }),
  });
  const data = await res.json();
  if (!data.ok) {
    throw new Error(data.error || "AI 生成失败");
  }
  return { document: data.document as DesignDocument, imageUrl: data.image_url as string };
}

export default function AIPage({ onGenerate, onBack }: AIPageProps) {
  const [prompt, setPrompt] = useState("");
  const [scene, setScene] = useState<"avatar" | "background" | "live_decoration" | "poster" | "custom">("poster");
  const [style, setStyle] = useState("modern");
  const [color, setColor] = useState("#6C5CE7");
  const [loading, setLoading] = useState(false);
  const [progressText, setProgressText] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [result, setResult] = useState<GenerateResult | null>(null);

  /** AI 生成（真实） */
  const handleGenerate = useCallback(async () => {
    if (!prompt.trim() || loading) return;
    setError(null);
    setResult(null);
    setLoading(true);
    setProgressText("AI 正在理解描述并生成图片...");

    try {
      const size = SIZES[scene] ?? { width: 390, height: 600 };

      // 🔧 测试 shortcut：prompt 为纯数字 "111" 时，跳过 API，直接用本地素材图
      if (prompt.trim() === "111") {
        const doc: DesignDocument = {
          version: 1,
          canvas: { width: size.width, height: size.height, background: "#1a1a2e" },
          components: [{
            id: "ai-bg-source-poster",
            type: "image",
            x: 0, y: 0,
            width: size.width, height: size.height,
            content: "/generated/source-poster.png",
            editable: true,
            editableProperties: [],
            slot: null,
            style: {},
          }],
          meta: {
            name: "测试素材",
            scene: scene as DesignDocument["meta"]["scene"],
            tags: ["ai", "test"],
            createdAt: new Date().toISOString(),
          },
        };
        setResult({ document: doc, imageUrl: "/generated/source-poster.png" });
        setLoading(false);
        return;
      }

      const genResult = await generateAI(prompt.trim(), scene, style, size.width, size.height);
      setResult(genResult);
    } catch (e) {
      const msg = e instanceof Error ? e.message : "AI 生成失败，请重试";
      console.error("[AIPage] 生成错误:", e);
      setError(msg);
    } finally {
      setLoading(false);
    }
  }, [prompt, scene, style, loading]);

  /** 调试模式（Mock） */
  const handleMock = useCallback(() => {
    if (!prompt.trim() || loading) return;
    setError(null);
    setResult(null);
    setLoading(true);
    setProgressText("调试模式：生成模拟数据...");

    setTimeout(() => {
      const size = SIZES[scene] ?? { width: 390, height: 600 };
      const doc = mockAIGen({ prompt: prompt.trim(), scene, ...size });
      setResult({ document: doc, imageUrl: "" });
      setLoading(false);
    }, 500);
  }, [prompt, scene, loading]);

  /** 确认进入编辑器 */
  const handleConfirm = useCallback(() => {
    if (!result) return;
    onGenerate(result.document);
  }, [result, onGenerate]);

  /** 重新生成 */
  const handleRegenerate = useCallback(() => {
    setResult(null);
    setError(null);
    handleGenerate();
  }, [handleGenerate]);

  return (
    <div className="ai-screen">
      {/* 顶部 */}
      <div className="ai-header">
        <button className="ai-back" onClick={onBack}>‹ 返回</button>
        <span className="ai-title">AI 创作</span>
        <div style={{ width: 48 }} />
      </div>

      <div className="ai-body">
        {/* ── 输入区（未生成时显示） ── */}
        {!result && (
          <>
            <label className="ai-label">描述你的设计需求</label>
            <textarea
              className="ai-input"
              value={prompt}
              onChange={(e) => setPrompt(e.target.value)}
              placeholder="例如：一个简约风格的科技感海报，紫色主色调..."
              rows={3}
            />

            <label className="ai-label">选择场景</label>
            <div className="ai-scenes">
              {SCENES.map((s) => (
                <button
                  key={s.key}
                  className={`ai-scene-btn ${scene === s.key ? "active" : ""}`}
                  onClick={() => setScene(s.key)}
                >
                  <span className="ai-scene-icon">{s.icon}</span>
                  <span className="ai-scene-label">{s.label}</span>
                  <span className="ai-scene-desc">{s.desc}</span>
                </button>
              ))}
            </div>

            <label className="ai-label">主色调</label>
            <div className="ai-colors">
              {COLORS.map((c) => (
                <button
                  key={c}
                  className={`ai-color-btn ${color === c ? "active" : ""}`}
                  style={{ background: c }}
                  onClick={() => setColor(c)}
                />
              ))}
            </div>

            {/* 生成按钮 */}
            <button
              className="ai-generate-btn"
              onClick={handleGenerate}
              disabled={loading || !prompt.trim()}
            >
              {loading ? (
                <span className="ai-loading">
                  <span className="ai-spinner" />
                  {progressText}
                </span>
              ) : (
                "✨ AI 生成"
              )}
            </button>

            {/* 调试模式按钮 */}
            <button
              className="ai-mock-btn"
              onClick={handleMock}
              disabled={loading || !prompt.trim()}
            >
              调试模式（Mock）
            </button>
          </>
        )}

        {/* ── 生成结果预览 ── */}
        {result && (
          <div className="ai-result">
            <label className="ai-label">生成预览</label>
            <div className="ai-preview-wrap">
              {result.imageUrl ? (
                <img
                  src={result.imageUrl}
                  alt="AI 生成预览"
                  className="ai-preview-img"
                />
              ) : (
                <div className="ai-preview-placeholder">
                  <span>🎨</span>
                  <span>Mock 数据（无真实图片）</span>
                </div>
              )}
            </div>

            <div className="ai-result-actions">
              <button
                className="ai-regenerate-btn"
                onClick={handleRegenerate}
                disabled={loading}
              >
                🔄 重新生成
              </button>
              <button
                className="ai-confirm-btn"
                onClick={handleConfirm}
              >
                ✅ 确认，进入编辑
              </button>
            </div>
          </div>
        )}

        {/* ── 加载状态 ── */}
        {loading && (
          <div className="ai-loading-full">
            <span className="ai-spinner-lg" />
            <span className="ai-loading-text">{progressText}</span>
          </div>
        )}

        {/* ── 错误提示 ── */}
        {error && (
          <div className="ai-error">
            <span>❌</span>
            <span>{error}</span>
            <button className="ai-error-retry" onClick={() => setError(null)}>关闭</button>
          </div>
        )}
      </div>

      <style>{`
        .ai-screen {
          height: 100%; display: flex; flex-direction: column;
          background: var(--bg); color: var(--text);
        }
        .ai-header {
          height: 44px; display: flex; align-items: center;
          justify-content: space-between; padding: 0 12px;
          border-bottom: 1px solid var(--border);
        }
        .ai-back { background: none; border: none; color: var(--primary); font-size: 16px; cursor: pointer; padding: 4px 8px; }
        .ai-title { font-size: 16px; font-weight: 600; }
        .ai-body { flex: 1; overflow-y: auto; padding: 16px; display: flex; flex-direction: column; gap: 16px; }
        .ai-label { font-size: 13px; font-weight: 600; color: var(--text-secondary); }
        .ai-input {
          width: 100%; background: var(--bg-card); border: 1px solid var(--border);
          border-radius: 10px; padding: 12px; font-size: 14px; color: var(--text);
          outline: none; resize: none; font-family: inherit; box-sizing: border-box;
        }
        .ai-input:focus { border-color: var(--primary); }

        .ai-scenes { display: grid; grid-template-columns: 1fr 1fr; gap: 8px; }
        .ai-scene-btn {
          display: flex; flex-direction: column; align-items: center; gap: 2px;
          padding: 12px 8px; background: var(--bg-card); border: 1px solid var(--border);
          border-radius: 10px; cursor: pointer; -webkit-tap-highlight-color: transparent;
        }
        .ai-scene-btn.active { border-color: var(--primary); background: rgba(108,92,231,0.08); }
        .ai-scene-icon { font-size: 22px; }
        .ai-scene-label { font-size: 13px; font-weight: 600; color: var(--text); }
        .ai-scene-desc { font-size: 11px; color: var(--text-secondary); }

        .ai-colors { display: flex; gap: 10px; }
        .ai-color-btn {
          width: 32px; height: 32px; border-radius: 50%; border: 2px solid transparent;
          cursor: pointer; -webkit-tap-highlight-color: transparent;
        }
        .ai-color-btn.active { border-color: var(--text); }

        .ai-generate-btn {
          width: 100%; padding: 14px; background: var(--primary); color: white;
          border: none; border-radius: 12px; font-size: 16px; font-weight: 600;
          cursor: pointer; margin-top: 8px;
        }
        .ai-generate-btn:disabled { opacity: 0.5; cursor: not-allowed; }
        .ai-loading { display: flex; align-items: center; justify-content: center; gap: 8px; font-size: 14px; }
        .ai-spinner {
          display: inline-block; width: 16px; height: 16px;
          border: 2px solid rgba(255,255,255,0.3); border-top-color: white;
          border-radius: 50%; animation: aiSpin 0.6s linear infinite;
        }
        @keyframes aiSpin { to { transform: rotate(360deg); } }

        /* 调试按钮 */
        .ai-mock-btn {
          width: 100%; padding: 10px; background: none;
          border: 1px dashed var(--border); border-radius: 8px;
          color: var(--text-secondary); font-size: 13px;
          cursor: pointer; margin-top: -8px;
        }
        .ai-mock-btn:disabled { opacity: 0.4; cursor: not-allowed; }

        /* 预览区 */
        .ai-result { display: flex; flex-direction: column; gap: 12px; }
        .ai-preview-wrap {
          width: 100%; display: flex; justify-content: center;
          background: var(--bg-card); border-radius: 12px; padding: 16px;
          border: 1px solid var(--border);
        }
        .ai-preview-img {
          max-width: 100%; max-height: 60vh; object-fit: contain;
          border-radius: 8px; box-shadow: 0 4px 20px rgba(0,0,0,0.3);
        }
        .ai-preview-placeholder {
          display: flex; flex-direction: column; align-items: center;
          gap: 12px; padding: 40px 20px; color: var(--text-secondary);
          font-size: 14px;
        }
        .ai-preview-placeholder span:first-child { font-size: 40px; }

        .ai-result-actions {
          display: flex; gap: 12px; margin-top: 4px;
        }
        .ai-regenerate-btn {
          flex: 1; padding: 14px; background: var(--bg-card);
          border: 1px solid var(--border); border-radius: 12px;
          color: var(--text); font-size: 15px; font-weight: 500;
          cursor: pointer;
        }
        .ai-regenerate-btn:disabled { opacity: 0.5; }
        .ai-regenerate-btn:active { background: var(--border); }
        .ai-confirm-btn {
          flex: 1; padding: 14px; background: var(--primary); color: white;
          border: none; border-radius: 12px; font-size: 15px; font-weight: 600;
          cursor: pointer;
        }
        .ai-confirm-btn:active { opacity: 0.8; }

        /* 全屏加载 */
        .ai-loading-full {
          display: flex; flex-direction: column; align-items: center;
          gap: 12px; padding: 40px 20px;
        }
        .ai-spinner-lg {
          width: 32px; height: 32px;
          border: 3px solid rgba(108,92,231,0.2); border-top-color: var(--primary);
          border-radius: 50%; animation: aiSpin 0.6s linear infinite;
        }
        .ai-loading-text { font-size: 14px; color: var(--text-secondary); }

        /* 错误提示 */
        .ai-error {
          display: flex; align-items: center; gap: 8px;
          padding: 12px; background: rgba(231,76,60,0.1);
          border: 1px solid rgba(231,76,60,0.3); border-radius: 10px;
          color: #e74c3c; font-size: 13px;
        }
        .ai-error-retry {
          margin-left: auto; background: none; border: none;
          color: #e74c3c; font-size: 12px; cursor: pointer;
          text-decoration: underline;
        }
      `}</style>
    </div>
  );
}
