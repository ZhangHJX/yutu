"use client";

import { useState, useCallback } from "react";
import type { DesignDocument } from "@/core/DesignDocument";
import playlistTemplate from "../../templates/playlist-poster-111.json";

interface AIPageProps {
  onGenerate: (doc: DesignDocument) => void;
  onBack: () => void;
}

interface GenerateResult {
  document: DesignDocument;
  imageUrl: string;
}

type TemplateSlot = (typeof playlistTemplate.slots)[number];

const API_BASE = process.env.NEXT_PUBLIC_AI_API_BASE || "";
const THUMBNAIL_SCALE_X = 78 / playlistTemplate.canvas.width;
const THUMBNAIL_SCALE_Y = 120 / playlistTemplate.canvas.height;

function slotThumbStyle(slot: TemplateSlot) {
  return {
    left: slot.x * THUMBNAIL_SCALE_X,
    top: slot.y * THUMBNAIL_SCALE_Y,
    width: ("w" in slot ? slot.w : 0) * THUMBNAIL_SCALE_X,
    height: ("h" in slot ? slot.h : 0) * THUMBNAIL_SCALE_Y,
  };
}

async function generateTemplate(title: string, songsText: string, style: string): Promise<GenerateResult> {
  const songs = songsText
    .split(/\r?\n|,|，/)
    .map((song) => song.trim())
    .filter(Boolean);
  const res = await fetch(`${API_BASE}/api/ai/generate-template`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ title, songs, style, template_id: "playlist-poster-111" }),
  });
  const data = await res.json();
  if (!data.ok) {
    throw new Error(data.error || "模板生成失败");
  }
  return { document: data.document as DesignDocument, imageUrl: data.image_url as string };
}

export default function AIPage({ onGenerate, onBack }: AIPageProps) {
  const [title, setTitle] = useState("支持点歌 // 学歌 // 歌单未完待续");
  const [style, setStyle] = useState("dreamy pastel pink aesthetic, hyper-cute girly style");
  const [songsText, setSongsText] = useState(
    "公主病\n半情歌\n他的猫\n不将就\n月牙湾\n记事本\n小美满\n眉间雪\n闹够了没有\n勇气大爆发\n回忆的沙漏\n别找我麻烦\n彩虹的微笑\n但愿人长久\n离别开出花\n可惜没如果\n词不达意\n明天你好\n玫瑰窃贼\n天命风流\n漠河舞厅\n我好想你\n专属味道\n依然爱你"
  );
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [result, setResult] = useState<GenerateResult | null>(null);

  const handleGenerate = useCallback(async () => {
    if (!style.trim() || loading) return;
    setError(null);
    setResult(null);
    setLoading(true);

    try {
      const genResult = await generateTemplate(title.trim(), songsText, style.trim());
      setResult(genResult);
    } catch (e) {
      setError(e instanceof Error ? e.message : "模板生成失败，请重试");
    } finally {
      setLoading(false);
    }
  }, [title, songsText, style, loading]);

  const handleConfirm = useCallback(() => {
    if (!result) return;
    onGenerate(result.document);
  }, [result, onGenerate]);

  const handleRegenerate = useCallback(() => {
    void handleGenerate();
  }, [handleGenerate]);

  return (
    <div className="ai-screen">
      <div className="ai-header">
        <button className="ai-back" onClick={onBack}>返回</button>
        <span className="ai-title">模板创作</span>
        <div style={{ width: 48 }} />
      </div>

      <div className="ai-body">
        {!result && (
          <>
            <label className="ai-label">选择模板</label>
            <button className="template-card active" type="button">
              <span className="template-thumb">
                {playlistTemplate.slots
                  .filter((slot) => slot.id !== "background")
                  .map((slot) => (
                    <span key={slot.id} className={`thumb-slot thumb-${slot.id}`} style={slotThumbStyle(slot)} />
                  ))}
              </span>
              <span className="template-info">
                <strong>111 歌单海报</strong>
                <small>女孩 / 标题 / 播放器 / 歌单 / 背景</small>
              </span>
            </button>

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

            <label className="ai-label">图片风格</label>
            <textarea
              className="ai-input"
              value={style}
              onChange={(e) => setStyle(e.target.value)}
              placeholder="例如：dreamy pastel pink aesthetic, hyper-cute girly style"
              rows={3}
            />

            <button className="ai-generate-btn" onClick={handleGenerate} disabled={loading || !style.trim()}>
              {loading ? (
                <span className="ai-loading">
                  <span className="ai-spinner" />
                  正在按模板生成组件...
                </span>
              ) : (
                "生成模板海报"
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
            <span className="ai-loading-text">组件生成通常需要 1-2 分钟</span>
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
        .template-card {
          display: flex; align-items: center; gap: 14px; padding: 12px;
          background: var(--bg-card); border: 1px solid var(--primary); border-radius: 12px;
          color: var(--text); text-align: left; cursor: pointer;
        }
        .template-thumb {
          position: relative; flex: 0 0 auto; width: 78px; height: 120px; border-radius: 8px;
          background: linear-gradient(160deg, #ffe2ee, #ffc1dc); overflow: hidden;
          box-shadow: inset 0 0 0 1px rgba(255,255,255,0.65);
        }
        .template-thumb .thumb-slot { position: absolute; border-radius: 6px; background: rgba(255,255,255,0.75); border: 1px solid rgba(255,105,180,0.55); }
        .template-thumb .thumb-title { background: rgba(255,99,168,0.8); }
        .template-thumb .thumb-girl { background: rgba(255,255,255,0.58); }
        .template-info { display: flex; flex-direction: column; gap: 4px; }
        .template-info strong { font-size: 15px; }
        .template-info small { font-size: 12px; color: var(--text-secondary); line-height: 1.4; }
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
