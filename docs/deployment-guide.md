# 语图部署与 original 测试流程

本文档覆盖两套项目：

- 当前语图：`template-composition` 分支，Next.js 静态页面 + FastAPI AI 服务。
- original 语图：`original` 分支，Flutter App，用于导入/验证当前语图导出的工程包。

## 1. 当前语图部署流程

### 1.1 拉取代码

```bash
git clone https://github.com/ZhangHJX/yutu.git
cd yutu
git fetch origin
git checkout template-composition
git pull origin template-composition
```

### 1.2 安装前端依赖

```bash
npm ci
```

### 1.3 准备 Python 环境

项目目前没有单独的 `requirements.txt`，按 `server/server.py` 的实际 import 安装：

```bash
python -m venv .venv
source .venv/bin/activate
pip install fastapi uvicorn httpx pydantic pillow numpy opencv-python paddleocr
```

Windows PowerShell：

```powershell
py -3 -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install fastapi uvicorn httpx pydantic pillow numpy opencv-python paddleocr
```

### 1.4 配置 AI 环境变量

生产部署建议使用 `GPT_IMAGE_API_KEY`。`OPENAI_BASE_URL` 默认是 `https://co.yes.vg/v1`，如需换中转或官方地址再覆盖。

macOS/Linux：

```bash
export GPT_IMAGE_API_KEY="你的 key"
export OPENAI_BASE_URL="https://co.yes.vg/v1"
export PORT=3001
```

Windows PowerShell：

```powershell
$env:GPT_IMAGE_API_KEY="你的 key"
$env:OPENAI_BASE_URL="https://co.yes.vg/v1"
$env:PORT="3001"
```

### 1.5 构建前端静态文件

```bash
npm run build
```

当前 `next.config.ts` 使用：

```ts
output: "export"
```

构建结果会生成到 `out/`。

### 1.6 启动线上服务

```bash
python server/server.py
```

服务默认监听：

```text
http://0.0.0.0:3001
```

`server/server.py` 会同时提供：

- 静态页面：读取 `out/index.html` 和 `out/*`
- AI API：`/api/ai/generate-category`、`/api/ai/build-assets` 等
- 生成图片：`/generated/*`

浏览器访问：

```text
http://部署机器 IP:3001
```

### 1.7 本地开发模式

开发时可以前后端分开跑：

```bash
python server/server.py
```

另开一个终端：

```bash
NEXT_PUBLIC_AI_API_BASE=http://localhost:3001 npm run dev
```

Windows PowerShell：

```powershell
$env:NEXT_PUBLIC_AI_API_BASE="http://localhost:3001"
npm run dev
```

访问：

```text
http://localhost:3000
```

注意：`NEXT_PUBLIC_AI_API_BASE` 会在前端构建/启动时读取。生产环境由 `server/server.py` 同源托管页面和 API 时，可以不设置它。

### 1.8 导出 original 工程包

进入当前语图页面后：

```text
编辑器 → 导出 → 导出语图工程包 ZIP
```

导出的 ZIP 结构：

```text
*.original-yutu.zip
├─ draft.json
└─ images/
   ├─ xxx.png
   └─ ...
```

`draft.json` 中图片元素的 `filePath` 只写图片文件名，不带 `images/` 前缀，匹配 original 当前读取逻辑。

## 2. original 分支部署/运行流程

### 2.1 拉取代码

```bash
git clone https://github.com/ZhangHJX/yutu.git yutu-original
cd yutu-original
git fetch origin
git checkout original
git pull origin original
```

注意：`original` 分支里包含一个历史 iOS 沙盒目录，路径名带冒号。Windows 无法完整 checkout 这个分支，建议在 macOS/Linux 上操作 original。

### 2.2 Flutter 版本

`original` 分支 `.fvmrc` 指定：

```text
Flutter 3.38.5
```

推荐用 FVM：

```bash
fvm install 3.38.5
fvm use 3.38.5
fvm flutter --version
```

### 2.3 安装依赖

```bash
fvm flutter pub get
```

如果 `common` 子包依赖没有自动拉好，再执行：

```bash
cd common
fvm flutter pub get
cd ..
```

### 2.4 iOS 运行

```bash
cd ios
pod install
cd ..
fvm flutter devices
fvm flutter run -d <ios-device-id>
```

当前 iOS Bundle ID：

```text
com.heshun.languageatlas
```

Xcode 工程里已有 Team ID：

```text
3ZQ6WP59H7
```

如果真机签名失败，用 Xcode 打开：

```bash
open ios/Runner.xcworkspace
```

然后在 Signing & Capabilities 里确认 Team 和 Bundle ID。

### 2.5 Android 运行

要求：

- JDK 17
- Android SDK
- 可用模拟器或真机

```bash
fvm flutter devices
fvm flutter run -d <android-device-id>
```

当前 Android applicationId：

```text
com.heshun.languageatlas
```

注意：`android/app/build.gradle.kts` 里配置了 release keystore 读取 `android/key.properties`。如果 Gradle 配置阶段因为 `key.properties` 缺失失败，需要补齐签名文件，或临时把 release signing 改回 debug signing 后再本地跑 debug。

## 3. 把当前语图导出的工程包放进 original 测试

当前 original 代码没有应用内导入 ZIP 的入口。它只会从固定沙盒路径读取：

```text
Documents/cavals/draft.json
Documents/cavals/images/<filePath>
```

因此测试步骤是：先解压当前语图导出的 ZIP，再把内容放进 original App 沙盒。

### 3.1 解压工程包

```bash
unzip xxx.original-yutu.zip -d yutu-import
cd yutu-import
```

解压后应看到：

```text
draft.json
images/
```

### 3.2 iOS 模拟器导入

先启动 original App，然后执行：

```bash
APP_DIR=$(xcrun simctl get_app_container booted com.heshun.languageatlas data)
mkdir -p "$APP_DIR/Documents/cavals/images"
cp draft.json "$APP_DIR/Documents/cavals/draft.json"
cp -R images/* "$APP_DIR/Documents/cavals/images/"
```

然后重启 original App，或退出画布后重新进入，让 `DraftManager.loadDraft()` 重新读取 `draft.json`。

### 3.3 Android 调试包导入

推荐先用 Android Studio Device Explorer 操作：

```text
/data/data/com.heshun.languageatlas/app_flutter/cavals/
├─ draft.json
└─ images/
```

如果用 adb，调试包通常可以用 `run-as`：

```bash
adb shell run-as com.heshun.languageatlas mkdir -p app_flutter/cavals/images
adb push draft.json /data/local/tmp/yutu-draft.json
adb push images /data/local/tmp/yutu-images
adb shell run-as com.heshun.languageatlas cp /data/local/tmp/yutu-draft.json app_flutter/cavals/draft.json
adb shell run-as com.heshun.languageatlas cp -R /data/local/tmp/yutu-images/. app_flutter/cavals/images/
```

然后重启 original App。

## 4. 验证点

当前语图部署后：

- 页面能打开。
- AI 生成能返回画布。
- `/generated/*` 图片能访问。
- 编辑器里能导出 `*.original-yutu.zip`。

original 导入后：

- 能加载 `draft.json`。
- 图片组件不丢图。
- 文字层可见。
- 图片层位置、大小、旋转基本符合当前语图导出的画布。

## 5. 已知限制

- current original 没有应用内 ZIP 导入功能，需要外部把文件放入沙盒。
- 当前导出的 ZIP 是为后续 original 应用内导入准备的格式，但 original 还需要补“选择 ZIP、解压、写入 cavals、重载画布”的代码。
- original 分支不建议在 Windows checkout，因为历史文件路径包含 Windows 不支持的冒号。
- Android release 构建需要 `android/key.properties` 和 keystore；没有签名文件时先跑 debug。
