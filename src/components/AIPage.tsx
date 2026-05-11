"use client";

import { useState, useCallback } from "react";
import type { DesignDocument } from "@/core/DesignDocument";

interface AIPageProps {
  onGenerate: (doc: DesignDocument) => void;
  onBack: () => void;
}

interface GenerateResult {
  document: DesignDocument;
  imageUrl: string;
}

interface GenerateResponse {
  ok: boolean;
  document?: DesignDocument;
  image_url?: string;
  questions?: string[];
  error?: string;
  debug?: unknown;
}

class GenerateCategoryError extends Error {
  payload: unknown;

  constructor(message: string, payload: unknown) {
    super(message);
    this.name = "GenerateCategoryError";
    this.payload = payload;
  }
}

const API_BASE = process.env.NEXT_PUBLIC_AI_API_BASE || "";
const DEFAULT_SONGS = "公主病\n半情歌\n他的猫\n不将就\n月牙湾\n记事本\n小美满\n眉间雪\n闹够了没有\n勇气大爆发\n回忆的沙漏\n别找我麻烦";

function parseSongs(text: string): string[] {
  return text
    .split(/\r?\n|,|，/)
    .map((song) => song.trim())
    .filter(Boolean);
}

async function generateCategory(params: {
  title: string;
  songsText: string;
  style: string;
  description: string;
  useDefaultLayout: boolean;
  followupRound: number;
}): Promise<GenerateResponse> {
  const res = await fetch(`${API_BASE}/api/ai/generate-category`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      category: "playlist",
      title: params.title,
      songs: parseSongs(params.songsText),
      style: params.style,
      description: params.description,
      use_default_layout: params.useDefaultLayout,
      followup_round: params.followupRound,
    }),
  });
  const text = await res.text();
  let data: Partial<GenerateResponse> & { detail?: unknown };
  try {
    data = text ? JSON.parse(text) : {};
  } catch {
    data = { error: text };
  }
  if (!res.ok) {
    const message =
      typeof data.detail === "string"
        ? data.detail
        : data.error || text || res.statusText;
    throw new GenerateCategoryError(`HTTP ${res.status}: ${message}`, data);
  }
  return data as GenerateResponse;
}

export default function AIPage({ onGenerate, onBack }: AIPageProps) {
  const [title, setTitle] = useState("支持点歌 // 学歌 // 歌单未完待续");
  const [style, setStyle] = useState("dreamy pastel pink aesthetic, hyper-cute girly style");
  const [songsText, setSongsText] = useState(DEFAULT_SONGS);
  const [description, setDescription] = useState("");
  const [useDefaultLayout, setUseDefaultLayout] = useState(true);
  const [followupRound, setFollowupRound] = useState(0);
  const [questions, setQuestions] = useState<string[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [result, setResult] = useState<GenerateResult | null>(null);

  const handleGenerate = useCallback(async () => {
    if (loading) return;
    setError(null);
    setResult(null);
    setLoading(true);

    try {
      const data = await generateCategory({ title, songsText, style, description, useDefaultLayout, followupRound });
      if (data.questions?.length) {
        setQuestions(data.questions);
        setFollowupRound((round) => Math.min(round + 1, 3));
        return;
      }
      if (!data.ok || !data.document || !data.image_url) {
        throw new GenerateCategoryError(data.error || "生成失败", data);
      }
      setQuestions([]);
      setFollowupRound(0);
      console.log("[GenerateCategory] text layers", data.document.components
        .filter((component) => component.type === "text")
        .map((component) => ({
          id: component.id,
          name: component.name,
          contentLength: component.content.length,
          bounds: { x: component.x, y: component.y, width: component.width, height: component.height },
          zIndex: component.style?.zIndex,
          color: component.style?.color,
          fontSize: component.style?.fontSize,
        })));
      setResult({ document: data.document, imageUrl: data.image_url });
    } catch (e) {
      if (e instanceof GenerateCategoryError) {
        console.error("[GenerateCategory] failed", e.payload);
        setError(e.message);
      } else {
        console.error("[GenerateCategory] failed", e);
        setError(e instanceof Error ? e.message : "生成失败，请重试");
      }
    } finally {
      setLoading(false);
    }
  }, [title, songsText, style, description, useDefaultLayout, followupRound, loading]);

  const handleConfirm = useCallback(() => {
    if (result) onGenerate(result.document);
  }, [result, onGenerate]);

  const handleRegenerate = useCallback(() => {
    void handleGenerate();
  }, [handleGenerate]);

  return (
    <div className="ai-screen">
      <div className="ai-header">
        <button className="ai-back" onClick={onBack}>返回</button>
        <span className="ai-title">AI 素材创作</span>
        <div style={{ width: 48 }} />
      </div>

      <div className="ai-body">
        {!result && (
          <>
            <label className="ai-label">素材分类</label>
            <button className="category-card active" type="button">
              <span className="category-thumb">
                <span className="category-block title" />
                <span className="category-block visual" />
                <span className="category-block list" />
              </span>
              <span className="category-info">
                <strong>歌单</strong>
                <small>AI 先生成布局 map，再按组件生成素材，文字最后渲染为可编辑文本层</small>
              </span>
            </button>

            <label className="ai-check-row">
              <input
                type="checkbox"
                checked={useDefaultLayout}
                onChange={(e) => {
                  setUseDefaultLayout(e.target.checked);
                  setQuestions([]);
                  setFollowupRound(0);
                }}
              />
              <span>使用默认布局判断</span>
            </label>

            {questions.length > 0 && (
              <div className="ai-questions">
                <strong>需要补充信息</strong>
                {questions.map((question) => (
                  <span key={question}>{question}</span>
                ))}
              </div>
            )}

            <label className="ai-label">标题</label>
            <input
              className="ai-input"
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              placeholder="输入标题"
            />

            <label className="ai-label">歌单</label>
            <textarea
              className="ai-input"
              value={songsText}
              onChange={(e) => setSongsText(e.target.value)}
              placeholder="每行一首歌"
              rows={7}
            />

            <label className="ai-label">风格</label>
            <textarea
              className="ai-input"
              value={style}
              onChange={(e) => setStyle(e.target.value)}
              placeholder="例如：dreamy pastel pink aesthetic, hyper-cute girly style"
              rows={3}
            />

            <label className="ai-label">补充说明</label>
            <textarea
              className="ai-input"
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              placeholder="可填写画面情绪、目标人群、特殊元素等"
              rows={3}
            />

            <button className="ai-generate-btn" onClick={handleGenerate} disabled={loading}>
              {loading ? (
                <span className="ai-loading">
                  <span className="ai-spinner" />
                  正在生成布局和组件...
                </span>
              ) : questions.length ? (
                "提交补充并继续生成"
              ) : (
                "生成歌单素材"
              )}
            </button>
          </>
        )}

        {result && (
          <div className="ai-result">
            <label className="ai-label">生成预览</label>
            <div className="ai-preview-wrap">
              <img src={result.imageUrl} alt="生成预览" className="ai-preview-img" />
            </div>

            <div className="ai-result-actions">
              <button className="ai-regenerate-btn" onClick={handleRegenerate} disabled={loading}>
                重新生成
              </button>
              <button className="ai-confirm-btn" onClick={handleConfirm}>
                确认，进入编辑
              </button>
            </div>
          </div>
        )}

        {loading && (
          <div className="ai-loading-full">
            <span className="ai-spinner-lg" />
            <span className="ai-loading-text">完整生成通常需要 1-2 分钟</span>
          </div>
        )}

        {error && (
          <div className="ai-error">
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
        input.ai-input { resize: initial; }
        .ai-input:focus { border-color: var(--primary); }
        .category-card {
          display: flex; align-items: center; gap: 14px; padding: 12px;
          background: var(--bg-card); border: 1px solid var(--primary); border-radius: 12px;
          color: var(--text); text-align: left; cursor: pointer;
        }
        .category-thumb {
          position: relative; flex: 0 0 auto; width: 78px; height: 120px; border-radius: 8px;
          background: linear-gradient(160deg, #ffe2ee, #ffc1dc); overflow: hidden;
          box-shadow: inset 0 0 0 1px rgba(255,255,255,0.65);
        }
        .category-block { position: absolute; border-radius: 6px; background: rgba(255,255,255,0.8); border: 1px solid rgba(255,105,180,0.55); }
        .category-block.title { left: 10px; top: 10px; width: 58px; height: 14px; background: rgba(255,99,168,0.8); }
        .category-block.visual { left: 8px; top: 34px; width: 28px; height: 66px; }
        .category-block.list { left: 42px; top: 34px; width: 28px; height: 74px; }
        .category-info { display: flex; flex-direction: column; gap: 4px; }
        .category-info strong { font-size: 15px; }
        .category-info small { font-size: 12px; color: var(--text-secondary); line-height: 1.4; }
        .ai-check-row { display: flex; align-items: center; gap: 8px; font-size: 13px; color: var(--text-secondary); }
        .ai-questions {
          display: flex; flex-direction: column; gap: 6px; padding: 12px;
          background: rgba(108,92,231,0.08); border: 1px solid rgba(108,92,231,0.2);
          border-radius: 10px; font-size: 13px; color: var(--text);
        }
        .ai-questions strong { color: var(--primary); }
        .ai-generate-btn {
          width: 100%; padding: 14px; background: var(--primary); color: white;
          border: none; border-radius: 12px; font-size: 16px; font-weight: 600;
          cursor: pointer; margin-top: 8px;
        }
        .ai-generate-btn:disabled { opacity: 0.5; cursor: not-allowed; }
        .ai-loading { display: flex; align-items: center; justify-content: center; gap: 8px; font-size: 14px; }
        .ai-spinner, .ai-spinner-lg {
          display: inline-block; border-radius: 50%; animation: aiSpin 0.6s linear infinite;
        }
        .ai-spinner { width: 16px; height: 16px; border: 2px solid rgba(255,255,255,0.3); border-top-color: white; }
        .ai-spinner-lg { width: 32px; height: 32px; border: 3px solid rgba(108,92,231,0.2); border-top-color: var(--primary); }
        @keyframes aiSpin { to { transform: rotate(360deg); } }
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
        .ai-result-actions { display: flex; gap: 12px; margin-top: 4px; }
        .ai-regenerate-btn, .ai-confirm-btn {
          flex: 1; padding: 14px; border-radius: 12px; font-size: 15px; font-weight: 600; cursor: pointer;
        }
        .ai-regenerate-btn { background: var(--bg-card); border: 1px solid var(--border); color: var(--text); }
        .ai-confirm-btn { background: var(--primary); color: white; border: none; }
        .ai-loading-full {
          display: flex; flex-direction: column; align-items: center;
          gap: 12px; padding: 28px 20px;
        }
        .ai-loading-text { font-size: 14px; color: var(--text-secondary); }
        .ai-error {
          display: flex; align-items: center; gap: 8px; padding: 12px;
          background: rgba(231,76,60,0.1); border: 1px solid rgba(231,76,60,0.3);
          border-radius: 10px; color: #e74c3c; font-size: 13px;
        }
        .ai-error-retry {
          margin-left: auto; background: none; border: none;
          color: #e74c3c; font-size: 12px; cursor: pointer; text-decoration: underline;
        }
      `}</style>
    </div>
  );
}
