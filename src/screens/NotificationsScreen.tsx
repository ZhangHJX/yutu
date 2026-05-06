"use client";

const notifications = [
  { id: "n1", type: "like", user: "设计师小王", content: "赞了你的设计「活动海报」", time: "5 分钟前", read: false },
  { id: "n2", type: "follow", user: "创意工坊", content: "关注了你", time: "1 小时前", read: false },
  { id: "n3", type: "system", user: "", content: "你的设计「简约名片」已通过审核", time: "3 小时前", read: true },
  { id: "n4", type: "comment", user: "设计达人", content: "评论了你的作品：「颜色搭配很好！」", time: "昨天", read: true },
  { id: "n5", type: "like", user: "张三", content: "赞了你的设计「渐变头像」", time: "昨天", read: true },
  { id: "n6", type: "system", user: "", content: "存储空间使用提醒：已用 45MB/512MB", time: "2 天前", read: true },
];

export default function NotificationsScreen() {
  return (
    <div className="page-content">
      <div className="top-nav">消息</div>

      {notifications.length === 0 ? (
        <div className="notif-empty">
          <p>暂无消息</p>
        </div>
      ) : (
        <div className="notif-list">
          {notifications.map((n) => (
            <div
              key={n.id}
              className={`notif-item ${n.read ? "" : "unread"}`}
            >
              <div className="notif-icon">
                {n.type === "like" && "❤️"}
                {n.type === "follow" && "👤"}
                {n.type === "comment" && "💬"}
                {n.type === "system" && "🔔"}
              </div>
              <div className="notif-body">
                <div className="notif-content">
                  {n.user && <span className="notif-user">{n.user}</span>}
                  {n.content}
                </div>
                <div className="notif-time">{n.time}</div>
              </div>
              {!n.read && <div className="notif-dot" />}
            </div>
          ))}
        </div>
      )}

      <style>{`
        .notif-empty {
          text-align: center;
          padding: 80px 16px;
          color: var(--text-secondary);
          font-size: 15px;
        }
        .notif-list {
          padding: 8px 0 80px;
        }
        .notif-item {
          display: flex;
          align-items: flex-start;
          gap: 12px;
          padding: 14px 16px;
          border-bottom: 1px solid var(--border);
          position: relative;
        }
        .notif-item.unread {
          background: rgba(108, 92, 231, 0.03);
        }
        .notif-icon {
          font-size: 20px;
          width: 32px;
          text-align: center;
          flex-shrink: 0;
          margin-top: 2px;
        }
        .notif-body {
          flex: 1;
          min-width: 0;
        }
        .notif-content {
          font-size: 14px;
          line-height: 1.4;
          color: var(--text);
        }
        .notif-user {
          font-weight: 600;
          margin-right: 4px;
        }
        .notif-time {
          font-size: 12px;
          color: var(--text-secondary);
          margin-top: 4px;
        }
        .notif-dot {
          width: 8px;
          height: 8px;
          border-radius: 50%;
          background: var(--primary);
          flex-shrink: 0;
          margin-top: 6px;
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
