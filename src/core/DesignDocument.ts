/** DesignDocument — 语图业务主数据格式 */
export interface DesignDocument {
  version: 1;
  canvas: CanvasConfig;
  components: DesignComponent[];
  meta: DesignMeta;
}

export interface CanvasConfig {
  width: number;
  height: number;
  background: string; // hex / gradient / image URL
}

export type ComponentType = "text" | "image" | "shape" | "group";

export interface DesignComponent {
  id: string;
  type: ComponentType;
  editable: boolean;
  editableProperties: string[];
  slot: string | null; // "nickname" | "avatar" | "title" | "background" 等模板槽位
  x: number;
  y: number;
  width: number;
  height: number;
  rotation?: number;
  opacity?: number;
  style: Record<string, unknown>;
  content: string;
}

export interface DesignMeta {
  name: string;
  scene: "avatar" | "background" | "live_decoration" | "poster" | "custom";
  tags: string[];
  createdAt: string;
  thumbnail?: string;
}
