"use client";

import { useState, useEffect } from "react";
import { recentDrafts } from "@/data/storage";
import type { DraftMeta } from "@/data/storage";

interface HomeScreenProps {
  onCreate: () => void;
  onOpenDraft: (id: string) => void;
  refreshTick: number;
}

const quickPresets = [
  { label: "头像", emoji: "👤", desc: "1:1 方形" },
  { label: "海报", emoji: "🖼️", desc: "9:16 竖版" },
  { label: "背景", emoji: "🏞️", desc: "16:9 横版" },
  { label: "空白", emoji: "✨", desc: "自由尺寸" },
];

const categories = [
  "全部", "推荐", "头像", "背景", "海报", "直播装饰", "表情包", "社交媒体", "名片",
];

const communityFeeds = [
  { id: "f1", title: "渐变抽象艺术头像", author: "设计师小王", avatar: "👤", likes: 128, comments: 23, tag: "头像" },
  { id: "f2", title: "夏日清新海报设计", author: "创意工坊", avatar: "🎨", likes: 256, comments: 45, tag: "海报" },
  { id: "f3", title: "极简风格直播间背景", author: "直播设计组", avatar: "📺", likes: 89, comments: 12, tag: "背景" },
  { id: "f4", title: "可爱猫猫表情包", author: "萌图工坊", avatar: "🐱", likes: 512, comments: 78, tag: "表情包" },
  { id: "f5", title: "商务简约名片模板", author: "设计师老张", avatar: "👔", likes: 67, comments: 8, tag: "名片" },
  { id: "f6", title: "霓虹风格直播边框", author: "霓虹灯", avatar: "💡", likes: 192, comments: 31, tag: "直播装饰" },
];

function formatTime(iso: string): string {
  const diff = Date.now() - new Date(iso).getTime();
  const min = Math.floor(diff / 60000);
  if (min < 1) return "刚刚";
  if (min < 60) return `${min} 分钟前`;
  const hour = Math.floor(min / 60);
  if (hour < 24) return `${hour} 小时前`;
  const day = Math.floor(hour / 24);
  return `${day} 天前`;
}

export default function HomeScreen({ onCreate, onOpenDraft, refreshTick }: HomeScreenProps) {
  const [drafts, setDrafts] = useState<DraftMeta[]>([]);
  const [feedTab, setFeedTab] = useState<"recommend" | "following">("recommend");
  const [activeCategory, setActiveCategory] = useState("全部");
  const [showDetail, setShowDetail] = useState<string | null>(null);

  useEffect(() => {
    setDrafts(recentDrafts(10));
  }, [refreshTick]);

  // 作品详情弹窗
  if (showDetail) {
    const feed = communityFeeds.find((f) => f.id === showDetail);
    if (feed) return <FeedDetail feed={feed} onBack={() => setShowDetail(null)} />;
  }

  return (
    <div className="page-content">
      <div className="top-nav">语图</div>

      {/* 搜索栏 */}
      <div className="search-bar">
        <svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="#999" strokeWidth="2">
          <circle cx="11" cy="11" r="8" />
          <line x1="21" y1="21" x2="16.65" y2="16.65" />
        </svg>
        <span>搜索模板或作品...</span>
      </div>

      {/* 分类标签 */}
      <div className="tag-scroll">
        {categories.map((tag) => (
          <button
            key={tag}
            className={`tag ${activeCategory === tag ? "active" : ""}`}
            onClick={() => setActiveCategory(tag)}
          >
            {tag}
          </button>
        ))}
      </div>

      {/* 快速创作 */}
      <section className="home-section">
        <h2 className="home-section-title">快速创作</h2>
        <div className="quick-grid">
          {quickPresets.map((preset) => (
            <button key={preset.label} className="quick-btn" onClick={onCreate}>
              <span className="quick-emoji">{preset.emoji}</span>
              <span className="quick-label">{preset.label}</span>
              <span className="quick-desc">{preset.desc}</span>
            </button>
          ))}
        </div>
      </section>

      {/* 最近使用 */}
      {drafts.length > 0 && (
        <section className="home-section">
          <div className="home-section-row">
            <h2 className="home-section-title">最近使用</h2>
            <button className="home-more" onClick={() => {}}>查看全部</button>
          </div>
          <div className="recent-list">
            {drafts.slice(0, 3).map((d) => (
              <button key={d.id} className="recent-card" onClick={() => onOpenDraft(d.id)}>
                <div className="recent-thumb">
                  <svg viewBox="0 0 24 24" width="20" height="20" fill="none" stroke="#999" strokeWidth="1.5">
                    <rect x="3" y="3" width="18" height="18" rx="3" />
                    <line x1="12" y1="8" x2="12" y2="16" />
                    <line x1="8" y1="12" x2="16" y2="12" />
                  </svg>
                </div>
                <div className="recent-info">
                  <div className="recent-name">{d.name}</div>
                  <div className="recent-meta">{d.canvas.width}×{d.canvas.height} · {formatTime(d.updatedAt)}</div>
                </div>
                <span className="recent-arrow">›</span>
              </button>
            ))}
          </div>
        </section>
      )}

      {/* 社区作品流 — 推荐/关注切换 */}
      <section className="home-section">
        <div className="feed-tabs">
          <button
            className={`feed-tab ${feedTab === "recommend" ? "active" : ""}`}
            onClick={() => setFeedTab("recommend")}
          >
            推荐
          </button>
          <button
            className={`feed-tab ${feedTab === "following" ? "active" : ""}`}
            onClick={() => setFeedTab("following")}
          >
            关注
          </button>
        </div>
      </section>

      {/* 作品卡片列表 */}
      <div className="feed-list">
        {communityFeeds.map((feed) => (
          <div key={feed.id} className="feed-card" onClick={() => setShowDetail(feed.id)}>
            <div className="feed-card-image">
              <svg viewBox="0 0 80 80" width="40" height="40" fill="none" stroke="#bbb" strokeWidth="1.5">
                <rect x="10" y="10" width="60" height="60" rx="8" />
                <circle cx="30" cy="30" r="6" />
                <polyline points="65,55 50,40 25,65" />
              </svg>
            </div>
            <div className="feed-card-body">
              <div className="feed-card-title">{feed.title}</div>
              <div className="feed-card-author">
                <span className="feed-card-avatar">{feed.avatar}</span>
                <span>{feed.author}</span>
                <span className="feed-card-tag">{feed.tag}</span>
              </div>
              <div className="feed-card-actions">
                <span className="feed-card-action">♥ {feed.likes}</span>
                <span className="feed-card-action">💬 {feed.comments}</span>
              </div>
            </div>
          </div>
        ))}
      </div>

      <style>{`
        .home-section { padding: 12px 16px; }
        .home-section-title { font-size: 16px; font-weight: 600; margin-bottom: 12px; }
        .home-section-row { display: flex; justify-content: space-between; align-items: center; margin-bottom: 12px; }
        .home-section-row .home-section-title { margin-bottom: 0; }
        .home-more { background: none; border: none; color: var(--primary); font-size: 13px; cursor: pointer; }
        .quick-grid { display: grid; grid-template-columns: repeat(4, 1fr); gap: 8px; }
        .quick-btn {
          display: flex; flex-direction: column; align-items: center; gap: 4px;
          padding: 16px 8px; background: var(--bg-card); border: 1px solid var(--border);
          border-radius: 12px; cursor: pointer; -webkit-tap-highlight-color: transparent;
          transition: transform 0.15s;
        }
        .quick-btn:active { transform: scale(0.96); }
        .quick-emoji { font-size: 24px; }
        .quick-label { font-size: 13px; font-weight: 500; }
        .quick-desc { font-size: 11px; color: var(--text-secondary); }
        .recent-list { display: flex; flex-direction: column; gap: 6px; }
        .recent-card {
          display: flex; align-items: center; gap: 10px; padding: 10px 12px;
          background: var(--bg-card); border: 1px solid var(--border); border-radius: 10px;
          cursor: pointer; width: 100%; text-align: left; -webkit-tap-highlight-color: transparent;
        }
        .recent-card:active { background: var(--bg); }
        .recent-thumb { width: 36px; height: 36px; background: var(--bg); border-radius: 6px; display: flex; align-items: center; justify-content: center; flex-shrink: 0; }
        .recent-info { flex: 1; min-width: 0; }
        .recent-name { font-size: 13px; font-weight: 500; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
        .recent-meta { font-size: 11px; color: var(--text-secondary); margin-top: 2px; }
        .recent-arrow { color: #ccc; font-size: 18px; flex-shrink: 0; }
        .feed-tabs { display: flex; gap: 0; border-bottom: 1px solid var(--border); margin: 0 -16px; padding: 0 16px; }
        .feed-tab {
          flex: 1; padding: 10px 0; text-align: center; background: none; border: none;
          font-size: 15px; color: var(--text-secondary); cursor: pointer; position: relative;
          -webkit-tap-highlight-color: transparent;
        }
        .feed-tab.active { color: var(--primary); font-weight: 600; }
        .feed-tab.active::after {
          content: ""; position: absolute; bottom: -1px; left: 20%; right: 20%;
          height: 2px; background: var(--primary); border-radius: 1px;
        }
        .feed-list { padding: 0 16px 80px; display: flex; flex-direction: column; gap: 8px; }
        .feed-card {
          display: flex; gap: 12px; padding: 12px; background: var(--bg-card);
          border-radius: 12px; border: 1px solid var(--border); cursor: pointer;
          -webkit-tap-highlight-color: transparent;
        }
        .feed-card:active { background: var(--bg); }
        .feed-card-image {
          width: 100px; height: 100px; border-radius: 8px; background: var(--bg);
          display: flex; align-items: center; justify-content: center; flex-shrink: 0;
        }
        .feed-card-body { flex: 1; min-width: 0; display: flex; flex-direction: column; gap: 4px; }
        .feed-card-title { font-size: 15px; font-weight: 600; }
        .feed-card-author { display: flex; align-items: center; gap: 4px; font-size: 13px; color: var(--text-secondary); }
        .feed-card-avatar { font-size: 16px; }
        .feed-card-tag { margin-left: auto; font-size: 11px; color: var(--primary); background: rgba(108,92,231,0.1); padding: 1px 8px; border-radius: 8px; }
        .feed-card-actions { display: flex; gap: 16px; margin-top: auto; font-size: 12px; color: var(--text-secondary); }
        .feed-card-action { cursor: pointer; }
        .page-content { padding-bottom: calc(56px + env(safe-area-inset-bottom, 0px)); height: 100vh; overflow-y: auto; }
      `}</style>
    </div>
  );
}

/** 作品详情页（轻量弹窗级） */
function FeedDetail({ feed, onBack }: { feed: typeof communityFeeds[number]; onBack: () => void }) {
  const [liked, setLiked] = useState(false);
  const [likeCount, setLikeCount] = useState(feed.likes);

  const handleLike = () => {
    setLiked(!liked);
    setLikeCount((c) => (liked ? c - 1 : c + 1));
  };

  return (
    <div className="page-content">
      <div className="top-nav" style={{ display: "flex", alignItems: "center", gap: 12, justifyContent: "flex-start" }}>
        <button className="detail-back" onClick={onBack}>‹ 返回</button>
        <span>作品详情</span>
      </div>

      {/* 作品展示 */}
      <div className="detail-image">
        <svg viewBox="0 0 80 80" width="56" height="56" fill="none" stroke="#bbb" strokeWidth="1.5">
          <rect x="10" y="10" width="60" height="60" rx="8" />
          <circle cx="30" cy="30" r="6" />
          <polyline points="65,55 50,40 25,65" />
        </svg>
      </div>

      {/* 信息区 */}
      <div className="detail-info">
        <h2 className="detail-title">{feed.title}</h2>
        <div className="detail-author-row">
          <span className="detail-avatar">{feed.avatar}</span>
          <span className="detail-author">{feed.author}</span>
          <button className="detail-follow">+ 关注</button>
        </div>
        <div className="detail-tags">
          <span className="detail-tag">{feed.tag}</span>
          <span className="detail-tag">AI 生成</span>
        </div>
      </div>

      {/* 互动区 */}
      <div className="detail-actions">
        <button className={`detail-action-btn ${liked ? "liked" : ""}`} onClick={handleLike}>
          ♥ {likeCount}
        </button>
        <button className="detail-action-btn">
          💬 {feed.comments}
        </button>
        <button className="detail-action-btn">
          ⭐ 收藏
        </button>
        <button className="detail-action-btn">
          📤 分享
        </button>
      </div>

      {/* 评论区 */}
      <div className="detail-comments">
        <h3 className="detail-comments-title">评论 ({feed.comments})</h3>
        {[
          { user: "用户A", text: "好看！求模板", time: "1 小时前" },
          { user: "用户B", text: "颜色搭配很舒服", time: "3 小时前" },
        ].map((c, i) => (
          <div key={i} className="comment-item">
            <span className="comment-avatar">{i === 0 ? "👤" : "😊"}</span>
            <div className="comment-body">
              <div className="comment-user">{c.user}</div>
              <div className="comment-text">{c.text}</div>
              <div className="comment-time">{c.time}</div>
            </div>
          </div>
        ))}
      </div>

      <style>{`
        .detail-back { background: none; border: none; color: var(--primary); font-size: 15px; cursor: pointer; padding: 4px 0; }
        .detail-image { width: 100%; max-width: 360px; aspect-ratio: 1; margin: 16px auto; background: var(--bg-card); border-radius: 12px; display: flex; align-items: center; justify-content: center; border: 1px solid var(--border); }
        .detail-info { padding: 0 16px; }
        .detail-title { font-size: 20px; font-weight: 700; margin-bottom: 12px; }
        .detail-author-row { display: flex; align-items: center; gap: 8px; margin-bottom: 12px; }
        .detail-avatar { font-size: 24px; }
        .detail-author { font-size: 15px; font-weight: 500; flex: 1; }
        .detail-follow { background: var(--primary); color: white; border: none; border-radius: 16px; padding: 4px 14px; font-size: 13px; cursor: pointer; }
        .detail-tags { display: flex; gap: 6px; }
        .detail-tag { font-size: 12px; color: var(--text-secondary); background: var(--bg); padding: 2px 10px; border-radius: 8px; }
        .detail-actions { display: flex; gap: 8px; padding: 16px; }
        .detail-action-btn { flex: 1; padding: 10px; background: var(--bg-card); border: 1px solid var(--border); border-radius: 8px; font-size: 13px; cursor: pointer; text-align: center; }
        .detail-action-btn.liked { color: #e74c3c; border-color: #e74c3c; background: rgba(231,76,60,0.05); }
        .detail-comments { padding: 0 16px 80px; }
        .detail-comments-title { font-size: 15px; font-weight: 600; margin-bottom: 12px; }
        .comment-item { display: flex; gap: 10px; margin-bottom: 12px; }
        .comment-avatar { font-size: 20px; }
        .comment-body { flex: 1; }
        .comment-user { font-size: 13px; font-weight: 600; }
        .comment-text { font-size: 14px; margin-top: 2px; }
        .comment-time { font-size: 11px; color: var(--text-secondary); margin-top: 4px; }
        .page-content { padding-bottom: calc(56px + env(safe-area-inset-bottom, 0px)); height: 100vh; overflow-y: auto; }
      `}</style>
    </div>
  );
}
