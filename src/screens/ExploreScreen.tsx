"use client";

import { useState } from "react";

const categories = [
  { key: "all", label: "全部" },
  { key: "avatar", label: "头像" },
  { key: "background", label: "背景" },
  { key: "poster", label: "海报" },
  { key: "live", label: "直播装饰" },
  { key: "meme", label: "表情包" },
  { key: "social", label: "社交媒体" },
];

const mockGrid = Array.from({ length: 18 }, (_, i) => ({
  id: `explore-${i}`,
  title: `设计作品 ${i + 1}`,
  author: `设计师 ${(i % 5) + 1}`,
  likes: Math.floor(Math.random() * 200),
}));

export default function ExploreScreen() {
  const [activeCat, setActiveCat] = useState("all");

  return (
    <div className="page-content">
      <div className="top-nav">探索</div>

      {/* 分类筛选 */}
      <div className="tag-scroll">
        {categories.map((cat) => (
          <button
            key={cat.key}
            className={`tag ${activeCat === cat.key ? "active" : ""}`}
            onClick={() => setActiveCat(cat.key)}
          >
            {cat.label}
          </button>
        ))}
      </div>

      {/* 网格视图 */}
      <div className="explore-grid">
        {mockGrid.map((item) => (
          <div key={item.id} className="explore-item">
            <div className="explore-item-image">
              <svg viewBox="0 0 80 80" width="36" height="36" fill="none" stroke="#ccc" strokeWidth="1.5">
                <rect x="15" y="15" width="50" height="50" rx="6" />
                <circle cx="33" cy="33" r="5" />
                <polyline points="62,52 48,38 28,58" />
              </svg>
            </div>
            <div className="explore-item-info">
              <div className="explore-item-title">{item.title}</div>
              <div className="explore-item-author">
                <span>{item.author}</span>
                <span className="explore-item-likes">♥ {item.likes}</span>
              </div>
            </div>
          </div>
        ))}
      </div>

      <style>{`
        .explore-grid {
          display: grid;
          grid-template-columns: 1fr 1fr;
          gap: 8px;
          padding: 8px 16px 80px;
        }
        .explore-item {
          background: var(--bg-card);
          border-radius: 12px;
          overflow: hidden;
          box-shadow: 0 1px 3px rgba(0,0,0,0.06);
        }
        .explore-item-image {
          width: 100%;
          aspect-ratio: 1;
          background: var(--border);
          display: flex;
          align-items: center;
          justify-content: center;
        }
        .explore-item-info {
          padding: 8px 10px;
        }
        .explore-item-title {
          font-size: 13px;
          font-weight: 500;
          margin-bottom: 4px;
          white-space: nowrap;
          overflow: hidden;
          text-overflow: ellipsis;
        }
        .explore-item-author {
          font-size: 11px;
          color: var(--text-secondary);
          display: flex;
          justify-content: space-between;
          align-items: center;
        }
        .explore-item-likes {
          color: #e17055;
        }
        .page-content {
          padding-bottom: calc(56px + env(safe-area-inset-bottom, 0px));
          height: 100vh;
          overflow-y: auto;
        }
      `}</style>
    </div>
  );
}
