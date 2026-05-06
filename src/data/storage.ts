/** Draft storage — localStorage 封装 */

import type { DesignDocument } from "@/core/DesignDocument";

export interface DraftMeta {
  id: string;
  name: string;
  canvas: { width: number; height: number };
  updatedAt: string;
  createdAt: string;
}

const DRAFT_INDEX_KEY = "yutu_draft_index";
const DRAFT_DATA_PREFIX = "yutu_draft_";

/** 获取所有草稿元数据列表 */
export function listDrafts(): DraftMeta[] {
  try {
    const raw = localStorage.getItem(DRAFT_INDEX_KEY);
    if (!raw) return [];
    return JSON.parse(raw) as DraftMeta[];
  } catch {
    return [];
  }
}

/** 保存草稿 */
export function saveDraft(doc: DesignDocument): string {
  const drafts = listDrafts();
  const existing = drafts.find(
    (d) => d.name === doc.meta.name && d.canvas.width === doc.canvas.width
  );
  const id = existing?.id ?? `draft_${Date.now()}_${Math.random().toString(36).slice(2, 8)}`;

  // 保存完整文档数据
  localStorage.setItem(DRAFT_DATA_PREFIX + id, JSON.stringify(doc));

  // 更新索引
  const now = new Date().toISOString();
  const meta: DraftMeta = {
    id,
    name: doc.meta.name || "未命名设计",
    canvas: { width: doc.canvas.width, height: doc.canvas.height },
    updatedAt: now,
    createdAt: existing?.createdAt ?? now,
  };

  const newIndex = existing
    ? drafts.map((d) => (d.id === id ? meta : d))
    : [meta, ...drafts];

  localStorage.setItem(DRAFT_INDEX_KEY, JSON.stringify(newIndex));
  return id;
}

/** 加载指定草稿 */
export function loadDraft(id: string): DesignDocument | null {
  try {
    const raw = localStorage.getItem(DRAFT_DATA_PREFIX + id);
    if (!raw) return null;
    return JSON.parse(raw) as DesignDocument;
  } catch {
    return null;
  }
}

/** 删除草稿 */
export function deleteDraft(id: string): void {
  localStorage.removeItem(DRAFT_DATA_PREFIX + id);
  const drafts = listDrafts().filter((d) => d.id !== id);
  localStorage.setItem(DRAFT_INDEX_KEY, JSON.stringify(drafts));
}

/** 获取最近使用的草稿（按 updatedAt 排序） */
export function recentDrafts(limit = 10): DraftMeta[] {
  return listDrafts()
    .sort((a, b) => new Date(b.updatedAt).getTime() - new Date(a.updatedAt).getTime())
    .slice(0, limit);
}
