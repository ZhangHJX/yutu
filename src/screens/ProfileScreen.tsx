"use client";

import { useState, useEffect } from "react";
import { recentDrafts, loadDraft, deleteDraft } from "@/data/storage";
import type { DraftMeta } from "@/data/storage";

type ProfilePage = "main" | "designs" | "drafts" | "favorites" | "materials" | "settings" | "feedback" | "editProfile";

interface ProfileScreenProps {
  onOpenDraft?: (id: string) => void;
}

const mockUser = {
  nickname: "语图用户",
  bio: "AI 设计爱好者",
  stats: { designs: 12, followers: 36, following: 24 },
};

const mockDesigns = Array.from({ length: 12 }, (_, i) => ({
  id: `pd-${i}`,
  title: `我的设计 ${i + 1}`,
  date: `${i + 1} 天前`,
}));

export default function ProfileScreen({ onOpenDraft }: ProfileScreenProps) {
  const [page, setPage] = useState<ProfilePage>("main");

  if (page === "designs") return <DesignsPage onBack={() => setPage("main")} />;
  if (page === "drafts") return <DraftsPage onBack={() => setPage("main")} onOpenDraft={onOpenDraft} />;
  if (page === "favorites") return <FavoritesPage onBack={() => setPage("main")} />;
  if (page === "materials") return <MaterialsPage onBack={() => setPage("main")} />;
  if (page === "settings") return <SettingsPage onBack={() => setPage("main")} />;
  if (page === "feedback") return <FeedbackPage onBack={() => setPage("main")} />;
  if (page === "editProfile") return <EditProfilePage onBack={() => setPage("main")} />;

  return (
    <div className="page-content">
      <div className="top-nav">我的</div>

      {/* 用户信息（可点击编辑） */}
      <div className="profile-header" onClick={() => setPage("editProfile")}>
        <div className="profile-avatar">
          <svg viewBox="0 0 24 24" width="36" height="36" fill="#999" stroke="none">
            <circle cx="12" cy="8" r="4" />
            <path d="M4 20c0-4 3.6-8 8-8s8 4 8 8" />
          </svg>
        </div>
        <div className="profile-info">
          <div className="profile-nickname">{mockUser.nickname}</div>
          <div className="profile-bio">{mockUser.bio}</div>
        </div>
        <span className="profile-edit-arrow">›</span>
      </div>

      {/* 统计数据 */}
      <div className="profile-stats">
        {([
          { label: "作品", value: mockUser.stats.designs },
          { label: "粉丝", value: mockUser.stats.followers },
          { label: "关注", value: mockUser.stats.following },
        ] as const).map((stat) => (
          <div key={stat.label} className="profile-stat-item" onClick={() => setPage("designs")}>
            <div className="profile-stat-value">{stat.value}</div>
            <div className="profile-stat-label">{stat.label}</div>
          </div>
        ))}
      </div>

      {/* 菜单列表 */}
      <div className="profile-menu">
        <MenuItem icon="🖼️" label="我的设计" desc="查看和管理已发布的作品" onClick={() => setPage("designs")} />
        <MenuItem icon="📝" label="草稿箱" desc={`${recentDrafts(50).length} 个未完成的设计`} onClick={() => setPage("drafts")} />
        <MenuItem icon="⭐" label="我的收藏" desc="收藏的模板和作品" onClick={() => setPage("favorites")} />
        <MenuItem icon="🎨" label="素材管理" desc="图片、字体、模板 · 45MB/512MB" onClick={() => setPage("materials")} />
        <MenuItem icon="✏️" label="编辑资料" desc="头像、昵称、个人简介" onClick={() => setPage("editProfile")} />
        <MenuItem icon="⚙️" label="设置" desc="账号、通知、存储管理" onClick={() => setPage("settings")} />
        <MenuItem icon="💬" label="客服与反馈" desc="意见、问题反馈" onClick={() => setPage("feedback")} last />
      </div>

      <style>{`
        .profile-header {
          display: flex;
          align-items: center;
          gap: 16px;
          padding: 20px 16px;
          background: var(--bg-card);
          margin: 0 0 8px;
          cursor: pointer;
          -webkit-tap-highlight-color: transparent;
        }
        .profile-header:active { background: var(--bg); }
        .profile-avatar {
          width: 64px;
          height: 64px;
          border-radius: 50%;
          background: var(--border);
          display: flex;
          align-items: center;
          justify-content: center;
          flex-shrink: 0;
        }
        .profile-info { flex: 1; min-width: 0; }
        .profile-nickname { font-weight: 600; font-size: 18px; margin-bottom: 4px; }
        .profile-bio { font-size: 13px; color: var(--text-secondary); }
        .profile-edit-arrow { color: #ccc; font-size: 22px; }
        .profile-stats {
          display: flex;
          justify-content: space-around;
          background: var(--bg-card);
          padding: 16px;
          margin: 0 0 8px;
        }
        .profile-stat-item {
          text-align: center;
          cursor: pointer;
          -webkit-tap-highlight-color: transparent;
        }
        .profile-stat-item:active { opacity: 0.6; }
        .profile-stat-value { font-weight: 700; font-size: 18px; }
        .profile-stat-label { font-size: 12px; color: var(--text-secondary); margin-top: 2px; }
        .profile-menu { margin: 0 0 80px; background: var(--bg-card); }
        .profile-menu-item {
          display: flex;
          align-items: center;
          gap: 12px;
          padding: 16px;
          border-bottom: 1px solid var(--border);
          cursor: pointer;
          -webkit-tap-highlight-color: transparent;
        }
        .profile-menu-item:active { background: var(--bg); }
        .profile-menu-item:last-child { border-bottom: none; }
        .profile-menu-icon { font-size: 20px; width: 28px; text-align: center; }
        .profile-menu-body { flex: 1; min-width: 0; }
        .profile-menu-label { font-size: 15px; font-weight: 500; }
        .profile-menu-desc { font-size: 12px; color: var(--text-secondary); margin-top: 2px; }
        .profile-menu-arrow { color: #ccc; font-size: 18px; }
        .page-content { padding-bottom: calc(56px + env(safe-area-inset-bottom, 0px)); height: 100vh; overflow-y: auto; }
      `}</style>
    </div>
  );
}

function MenuItem({ icon, label, desc, onClick, last }: {
  icon: string; label: string; desc: string; onClick: () => void; last?: boolean;
}) {
  return (
    <div className="profile-menu-item" style={last ? { borderBottom: "none" } : undefined} onClick={onClick}>
      <span className="profile-menu-icon">{icon}</span>
      <div className="profile-menu-body">
        <div className="profile-menu-label">{label}</div>
        <div className="profile-menu-desc">{desc}</div>
      </div>
      <span className="profile-menu-arrow">›</span>
    </div>
  );
}

/* ---- Sub-pages ---- */

/** 我的设计 */
function DesignsPage({ onBack }: { onBack: () => void }) {
  return (
    <div className="page-content">
      <div className="top-nav" style={{ display: "flex", alignItems: "center", gap: 12, justifyContent: "flex-start" }}>
        <button className="subpage-back" onClick={onBack}>‹ 返回</button>
        <span>我的设计</span>
      </div>
      <div className="designs-grid">
        {mockDesigns.map((d) => (
          <div key={d.id} className="designs-item">
            <div className="designs-thumb">
              <svg viewBox="0 0 24 24" width="22" height="22" fill="none" stroke="#999" strokeWidth="1.5">
                <rect x="3" y="3" width="18" height="18" rx="3" />
              </svg>
            </div>
            <div className="designs-title">{d.title}</div>
            <div className="designs-date">{d.date}</div>
          </div>
        ))}
      </div>
      <style>{`
        .subpage-back { background: none; border: none; color: var(--primary); font-size: 15px; cursor: pointer; padding: 4px 0; }
        .designs-grid { display: grid; grid-template-columns: 1fr 1fr 1fr; gap: 6px; padding: 12px 16px 80px; }
        .designs-item { aspect-ratio: 1; background: var(--bg-card); border-radius: 8px; overflow: hidden; border: 1px solid var(--border); display: flex; flex-direction: column; align-items: center; justify-content: center; gap: 4px; }
        .designs-thumb { display: flex; align-items: center; justify-content: center; }
        .designs-title { font-size: 12px; font-weight: 500; text-align: center; padding: 0 4px; }
        .designs-date { font-size: 10px; color: var(--text-secondary); }
        .page-content { padding-bottom: calc(56px + env(safe-area-inset-bottom, 0px)); height: 100vh; overflow-y: auto; }
      `}</style>
    </div>
  );
}

/** 草稿箱 */
function DraftsPage({ onBack, onOpenDraft }: { onBack: () => void; onOpenDraft?: (id: string) => void }) {
  const [drafts, setDrafts] = useState<DraftMeta[]>([]);

  useEffect(() => { setDrafts(recentDrafts(50)); }, []);

  const handleDelete = (id: string, e: React.MouseEvent) => {
    e.stopPropagation();
    deleteDraft(id);
    setDrafts((prev) => prev.filter((d) => d.id !== id));
  };

  return (
    <div className="page-content">
      <div className="top-nav" style={{ display: "flex", alignItems: "center", gap: 12, justifyContent: "flex-start" }}>
        <button className="subpage-back" onClick={onBack}>‹ 返回</button>
        <span>草稿箱 ({drafts.length})</span>
      </div>
      {drafts.length === 0 ? (
        <div className="subpage-empty">
          <p>暂无草稿</p>
          <p className="subpage-empty-hint">创作的设计会自动保存到此处</p>
        </div>
      ) : (
        <div className="draft-list">
          {drafts.map((d) => (
            <div key={d.id} className="draft-item" onClick={() => onOpenDraft?.(d.id)}>
              <div className="draft-thumb">
                <svg viewBox="0 0 24 24" width="22" height="22" fill="none" stroke="#999" strokeWidth="1.5">
                  <rect x="3" y="3" width="18" height="18" rx="3" />
                  <line x1="12" y1="8" x2="12" y2="16" />
                  <line x1="8" y1="12" x2="16" y2="12" />
                </svg>
              </div>
              <div className="draft-info">
                <div className="draft-name">{d.name}</div>
                <div className="draft-meta">{d.canvas.width}×{d.canvas.height}</div>
              </div>
              <button className="draft-delete" onClick={(e) => handleDelete(d.id, e)}>删除</button>
            </div>
          ))}
        </div>
      )}
      <style>{`
        .subpage-back { background: none; border: none; color: var(--primary); font-size: 15px; cursor: pointer; padding: 4px 0; }
        .subpage-empty { text-align: center; padding: 80px 16px; color: var(--text-secondary); font-size: 15px; }
        .subpage-empty-hint { font-size: 12px; color: #bbb; margin-top: 6px; }
        .draft-list { padding: 8px 16px 80px; display: flex; flex-direction: column; gap: 6px; }
        .draft-item { display: flex; align-items: center; gap: 10px; padding: 12px; background: var(--bg-card); border-radius: 10px; border: 1px solid var(--border); cursor: pointer; }
        .draft-item:active { background: var(--bg); }
        .draft-thumb { width: 40px; height: 40px; background: var(--bg); border-radius: 6px; display: flex; align-items: center; justify-content: center; flex-shrink: 0; }
        .draft-info { flex: 1; min-width: 0; }
        .draft-name { font-size: 14px; font-weight: 500; }
        .draft-meta { font-size: 11px; color: var(--text-secondary); margin-top: 2px; }
        .draft-delete { background: none; border: 1px solid #e74c3c; color: #e74c3c; border-radius: 4px; font-size: 11px; padding: 2px 10px; cursor: pointer; }
        .page-content { padding-bottom: calc(56px + env(safe-area-inset-bottom, 0px)); height: 100vh; overflow-y: auto; }
      `}</style>
    </div>
  );
}

/** 我的收藏 */
function FavoritesPage({ onBack }: { onBack: () => void }) {
  return (
    <div className="page-content">
      <div className="top-nav" style={{ display: "flex", alignItems: "center", gap: 12, justifyContent: "flex-start" }}>
        <button className="subpage-back" onClick={onBack}>‹ 返回</button>
        <span>我的收藏</span>
      </div>
      <div className="subpage-empty">
        <p>暂无收藏</p>
        <p className="subpage-empty-hint">收藏的模板和作品会出现在这里</p>
      </div>
      <style>{`
        .subpage-back { background: none; border: none; color: var(--primary); font-size: 15px; cursor: pointer; padding: 4px 0; }
        .subpage-empty { text-align: center; padding: 80px 16px; color: var(--text-secondary); font-size: 15px; }
        .subpage-empty-hint { font-size: 12px; color: #bbb; margin-top: 6px; }
        .page-content { padding-bottom: calc(56px + env(safe-area-inset-bottom, 0px)); height: 100vh; overflow-y: auto; }
      `}</style>
    </div>
  );
}

/** 素材管理 */
function MaterialsPage({ onBack }: { onBack: () => void }) {
  const storageUsed = 45;
  const storageTotal = 512;

  return (
    <div className="page-content">
      <div className="top-nav" style={{ display: "flex", alignItems: "center", gap: 12, justifyContent: "flex-start" }}>
        <button className="subpage-back" onClick={onBack}>‹ 返回</button>
        <span>素材管理</span>
      </div>
      <div className="material-storage">
        <div className="material-storage-header">存储空间</div>
        <div className="material-storage-bar">
          <div className="material-storage-fill" style={{ width: `${(storageUsed / storageTotal) * 100}%` }} />
        </div>
        <div className="material-storage-text">已用 {storageUsed}MB / {storageTotal}MB</div>
      </div>
      <div className="material-types">
        {[
          { label: "上传的图片", count: 23, size: "32MB" },
          { label: "自定义字体", count: 3, size: "8MB" },
          { label: "自定义模板", count: 5, size: "5MB" },
        ].map((m) => (
          <div key={m.label} className="material-type-item">
            <div className="material-type-info">
              <div className="material-type-label">{m.label}</div>
              <div className="material-type-count">{m.count} 项</div>
            </div>
            <span className="material-type-size">{m.size}</span>
          </div>
        ))}
      </div>
      <div className="subpage-empty" style={{ padding: "40px 16px" }}>
        <p className="subpage-empty-hint">素材管理功能即将上线</p>
      </div>
      <style>{`
        .subpage-back { background: none; border: none; color: var(--primary); font-size: 15px; cursor: pointer; padding: 4px 0; }
        .material-storage { background: var(--bg-card); margin: 12px 16px; padding: 20px; border-radius: 12px; }
        .material-storage-header { font-size: 15px; font-weight: 600; margin-bottom: 12px; }
        .material-storage-bar { height: 6px; background: var(--border); border-radius: 3px; overflow: hidden; }
        .material-storage-fill { height: 100%; background: var(--primary); border-radius: 3px; transition: width 0.3s; }
        .material-storage-text { font-size: 12px; color: var(--text-secondary); margin-top: 8px; }
        .material-types { background: var(--bg-card); margin: 0 16px 12px; border-radius: 12px; }
        .material-type-item { display: flex; align-items: center; justify-content: space-between; padding: 14px 16px; border-bottom: 1px solid var(--border); }
        .material-type-item:last-child { border-bottom: none; }
        .material-type-label { font-size: 14px; font-weight: 500; }
        .material-type-count { font-size: 12px; color: var(--text-secondary); margin-top: 2px; }
        .material-type-size { font-size: 13px; color: var(--text-secondary); }
        .subpage-empty { text-align: center; color: var(--text-secondary); font-size: 15px; }
        .subpage-empty-hint { font-size: 12px; color: #bbb; margin-top: 6px; }
        .page-content { padding-bottom: calc(56px + env(safe-area-inset-bottom, 0px)); height: 100vh; overflow-y: auto; }
      `}</style>
    </div>
  );
}

/** 编辑资料 */
function EditProfilePage({ onBack }: { onBack: () => void }) {
  const [name, setName] = useState(mockUser.nickname);
  const [bio, setBio] = useState(mockUser.bio);

  return (
    <div className="page-content">
      <div className="top-nav" style={{ display: "flex", alignItems: "center", gap: 12, justifyContent: "space-between" }}>
        <button className="subpage-back" onClick={onBack}>‹ 返回</button>
        <span>编辑资料</span>
        <button className="subpage-save" onClick={onBack}>保存</button>
      </div>
      <div className="edit-avatar-section">
        <div className="edit-avatar">
          <svg viewBox="0 0 24 24" width="40" height="40" fill="#999" stroke="none">
            <circle cx="12" cy="8" r="4" />
            <path d="M4 20c0-4 3.6-8 8-8s8 4 8 8" />
          </svg>
          <div className="edit-avatar-overlay">更换</div>
        </div>
      </div>
      <div className="edit-form">
        <div className="edit-field">
          <label className="edit-label">昵称</label>
          <input className="edit-input" value={name} onChange={(e) => setName(e.target.value)} maxLength={20} />
        </div>
        <div className="edit-field">
          <label className="edit-label">个人简介</label>
          <textarea className="edit-textarea" value={bio} onChange={(e) => setBio(e.target.value)} maxLength={60} rows={3} />
        </div>
      </div>
      <style>{`
        .subpage-back { background: none; border: none; color: var(--primary); font-size: 15px; cursor: pointer; padding: 4px 0; }
        .subpage-save { background: var(--primary); border: none; color: white; font-size: 13px; padding: 4px 14px; border-radius: 6px; cursor: pointer; }
        .edit-avatar-section { display: flex; justify-content: center; padding: 24px 0; }
        .edit-avatar { width: 80px; height: 80px; border-radius: 50%; background: var(--border); display: flex; align-items: center; justify-content: center; position: relative; overflow: hidden; cursor: pointer; }
        .edit-avatar-overlay { position: absolute; inset: 0; background: rgba(0,0,0,0.4); color: white; font-size: 12px; display: flex; align-items: center; justify-content: center; opacity: 0; transition: opacity 0.2s; }
        .edit-avatar:hover .edit-avatar-overlay { opacity: 1; }
        .edit-form { background: var(--bg-card); margin: 0 16px; border-radius: 12px; padding: 16px; }
        .edit-field { margin-bottom: 16px; }
        .edit-field:last-child { margin-bottom: 0; }
        .edit-label { font-size: 13px; color: var(--text-secondary); display: block; margin-bottom: 6px; }
        .edit-input { width: 100%; padding: 10px 12px; border: 1px solid var(--border); border-radius: 8px; font-size: 15px; outline: none; background: var(--bg); }
        .edit-input:focus { border-color: var(--primary); }
        .edit-textarea { width: 100%; padding: 10px 12px; border: 1px solid var(--border); border-radius: 8px; font-size: 15px; outline: none; background: var(--bg); resize: none; font-family: inherit; }
        .edit-textarea:focus { border-color: var(--primary); }
        .page-content { padding-bottom: calc(56px + env(safe-area-inset-bottom, 0px)); height: 100vh; overflow-y: auto; }
      `}</style>
    </div>
  );
}

/** 设置 */
function SettingsPage({ onBack }: { onBack: () => void }) {
  return (
    <div className="page-content">
      <div className="top-nav" style={{ display: "flex", alignItems: "center", gap: 12, justifyContent: "flex-start" }}>
        <button className="subpage-back" onClick={onBack}>‹ 返回</button>
        <span>设置</span>
      </div>
      <div className="settings-list">
        {[
          { label: "账号管理", desc: "手机号、第三方登录" },
          { label: "通知设置", desc: "消息推送、通知频率" },
          { label: "存储管理", desc: "512MB 已用 45MB" },
          { label: "清除缓存", desc: "当前缓存 12MB" },
          { label: "关于语图", desc: "版本 1.0.0 build 20260430" },
        ].map((item) => (
          <div key={item.label} className="settings-item">
            <div className="settings-item-body">
              <div className="settings-item-label">{item.label}</div>
              <div className="settings-item-desc">{item.desc}</div>
            </div>
            <span className="settings-arrow">›</span>
          </div>
        ))}
      </div>
      <div className="settings-logout">退出登录</div>
      <style>{`
        .subpage-back { background: none; border: none; color: var(--primary); font-size: 15px; cursor: pointer; padding: 4px 0; }
        .settings-list { margin: 12px 0; background: var(--bg-card); }
        .settings-item { display: flex; align-items: center; padding: 16px; border-bottom: 1px solid var(--border); cursor: pointer; }
        .settings-item-body { flex: 1; }
        .settings-item-label { font-size: 15px; font-weight: 500; }
        .settings-item-desc { font-size: 12px; color: var(--text-secondary); margin-top: 2px; }
        .settings-arrow { color: #ccc; font-size: 18px; }
        .settings-logout { text-align: center; padding: 16px; color: #e74c3c; font-size: 15px; margin: 12px 16px; background: var(--bg-card); border-radius: 10px; cursor: pointer; }
        .page-content { padding-bottom: calc(56px + env(safe-area-inset-bottom, 0px)); height: 100vh; overflow-y: auto; }
      `}</style>
    </div>
  );
}

/** 客服与反馈 */
function FeedbackPage({ onBack }: { onBack: () => void }) {
  return (
    <div className="page-content">
      <div className="top-nav" style={{ display: "flex", alignItems: "center", gap: 12, justifyContent: "flex-start" }}>
        <button className="subpage-back" onClick={onBack}>‹ 返回</button>
        <span>客服与反馈</span>
      </div>
      <div className="feedback-list">
        {[
          { label: "意见反馈", desc: "告诉我们你的想法" },
          { label: "常见问题", desc: "使用指南和常见问题解答" },
          { label: "联系客服", desc: "在线客服 09:00-21:00" },
        ].map((item) => (
          <div key={item.label} className="feedback-item">
            <div className="feedback-item-body">
              <div className="feedback-item-label">{item.label}</div>
              <div className="feedback-item-desc">{item.desc}</div>
            </div>
            <span className="feedback-arrow">›</span>
          </div>
        ))}
      </div>
      <style>{`
        .subpage-back { background: none; border: none; color: var(--primary); font-size: 15px; cursor: pointer; padding: 4px 0; }
        .feedback-list { margin: 12px 0 80px; background: var(--bg-card); }
        .feedback-item { display: flex; align-items: center; padding: 16px; border-bottom: 1px solid var(--border); cursor: pointer; }
        .feedback-item-body { flex: 1; }
        .feedback-item-label { font-size: 15px; font-weight: 500; }
        .feedback-item-desc { font-size: 12px; color: var(--text-secondary); margin-top: 2px; }
        .feedback-arrow { color: #ccc; font-size: 18px; }
        .page-content { padding-bottom: calc(56px + env(safe-area-inset-bottom, 0px)); height: 100vh; overflow-y: auto; }
      `}</style>
    </div>
  );
}
