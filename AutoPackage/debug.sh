#!/bin/zsh

set -e

if [ -z "$1" ]; then
  echo "用法: $0 -d|-t|-p <Flutter项目根目录>"
  echo "  -d  Development(开发环境)  -t  TestFlight(app-store)  -p  AdHoc(可扫码安装)"
  exit 1
fi

if [ -z "$2" ]; then
  echo "请传入 Flutter 项目根目录，例如: $0 -p /path/to/flutter_app"
  exit 1
fi

# 定义变量dev
case $1 in
    -d)
                Dev="Debug"
        ;;
    -t)
                Dev="Test"
        ;;
    -p)
                Dev="Prepare"
        ;;
    *)
        echo "无效的参数，请输入 -d 或 -t 或 -p"
        exit
        ;;
esac

# edit
FLUTTER_PROJECT_DIR="$2"
PUBSPEC_PATH="${FLUTTER_PROJECT_DIR}/pubspec.yaml"

if [ ! -f "${PUBSPEC_PATH}" ]; then
  echo "未找到 pubspec.yaml: ${PUBSPEC_PATH}"
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PARENT_DIR="$(dirname "$SCRIPT_DIR")"

EXPORT_PATH=${SCRIPT_DIR}/Export
EXPORT_PLIST_PATH=${SCRIPT_DIR}/ExportAdHoc.plist
INSTALL_PLIST_PATH=${SCRIPT_DIR}/Install.plist

case $1 in
  -d)
    EXPORT_PLIST_PATH=${SCRIPT_DIR}/ExportDevelopment.plist
    ;;
  -t)
    EXPORT_PLIST_PATH=${SCRIPT_DIR}/ExportAppStore.plist
    ;;
  -p)
    EXPORT_PLIST_PATH=${SCRIPT_DIR}/ExportAdHoc.plist
    ;;
esac

if [ ! -f "${EXPORT_PLIST_PATH}" ]; then
  echo "未找到导出配置: ${EXPORT_PLIST_PATH}"
  exit 1
fi

# 版本号处理：pubspec.yaml 使用 version: x.y.z，每次仅自增 z，并回写到 pubspec.yaml
VERSION_VALUE=$(python3 - "${PUBSPEC_PATH}" <<'PY'
import re, sys
path = sys.argv[1]
version = None
with open(path, "r", encoding="utf-8") as f:
    for line in f:
        m = re.match(r"^\s*version\s*:\s*([0-9]+\.[0-9]+\.[0-9]+)\s*$", line)
        if m:
            version = m.group(1)
            break
if not version:
    # 如果未找到，则给一个默认起始版本
    version = "1.4.0"
print(version)
PY
)

IFS='.' read -r MAJOR MINOR PATCH <<< "$VERSION_VALUE"
PATCH=$((PATCH + 1))
NEW_VERSION="${MAJOR}.${MINOR}.${PATCH}"

echo "版本号自增: ${VERSION_VALUE} -> ${NEW_VERSION}"

python3 - "${PUBSPEC_PATH}" "${NEW_VERSION}" <<'PY'
import re, sys
path = sys.argv[1]
new_ver = sys.argv[2]

out_lines = []
version_line_found = False

with open(path, "r", encoding="utf-8") as f:
    for line in f:
        if not version_line_found and re.match(r"^\s*version\s*:", line):
            indent = re.match(r"^(\s*)version\s*:", line).group(1)
            out_lines.append(f"{indent}version: {new_ver}\n")
            version_line_found = True
        else:
            out_lines.append(line)

if not version_line_found:
    out_lines.append(f"\nversion: {new_ver}\n")

with open(path, "w", encoding="utf-8") as f:
    f.writelines(out_lines)
PY

BUILD_NAME="${NEW_VERSION}"
BUILD_VERSION="${PATCH}"

# flutter build ipa
mkdir -p "${EXPORT_PATH}"
cd "${FLUTTER_PROJECT_DIR}"

flutter pub get

if [ -d "ios" ]; then
  cd ios
  if command -v pod >/dev/null 2>&1; then
    pod install
  fi
  cd ..
fi

flutter build ipa \
  --release \
  --build-name "${BUILD_NAME}" \
  --build-number "${BUILD_VERSION}" \
  --export-options-plist "${EXPORT_PLIST_PATH}"

# upload
IPA_PATH=$(ls "${FLUTTER_PROJECT_DIR}/build/ios/ipa/"*.ipa 2>/dev/null | head -n 1)
if [ -z "${IPA_PATH}" ]; then
  echo "未找到导出的 ipa: ${FLUTTER_PROJECT_DIR}/build/ios/ipa/*.ipa"
  exit 1
fi
echo "ipa导出✅${IPA_PATH}"

if [ ! -f "$IPA_PATH" ]; then
  echo "ipa不存在,打包失败"
  exit
fi

# named
APP_NAME=$(basename "${FLUTTER_PROJECT_DIR}")
FILE_NAME="${APP_NAME}(${BUILD_VERSION})_${Dev}"

# TestFlight(app-store) 导出的 ipa 一般用于上传 ASC，这里仅移动到桌面并结束
if [ "$Dev" = "Test" ]; then
  mv -f "${IPA_PATH}" "$HOME/Desktop/${FILE_NAME}.ipa"
  echo "${FILE_NAME}打包✅"
  exit
fi

#echo '传蒲公英'
#result=$(curl -F "file=@$IPA_PATH" -F "_api_key=${PGYER_API_KEY}" https://www.xcxwo.com/apiv2/app/upload)
##result=$(cat ~/Desktop/adoma)
#echo $result
#shortUrl=$(python3 -c "import json; print(json.loads('$result')['data']['buildKey'])")
#qrcodeUrl=$(python3 -c "import json; print(json.loads('$result')['data']['buildQRCodeURL'])")

echo '传腾讯云'
OSS_HOST=https://yutu-eo.shuangyuxingqiu.com
OSS_PATH=download/${Dev}
OSS_BUCKET="yutu-1363209587"
OSS_ENDPOINT="cos.ap-nanjing.myqcloud.com"
OSS_ACCESS_KEY_ID="${OSS_ACCESS_KEY_ID:-}"
OSS_ACCESS_KEY_SECRET="${OSS_ACCESS_KEY_SECRET:-}"

# 传ipa
OSS_FILE_PATH=cos://${OSS_BUCKET}/${OSS_PATH}/${FILE_NAME}.ipa
#$SCRIPT_DIR/ossutilmac64 cp $IPA_PATH $OSS_FILE_PATH -e $OSS_ENDPOINT -i $OSS_ACCESS_KEY_ID -k $OSS_ACCESS_KEY_SECRET -f
$SCRIPT_DIR/coscli cp $IPA_PATH $OSS_FILE_PATH --endpoint $OSS_ENDPOINT

# 改plist
IPA_FILE_URL=${OSS_HOST}/${OSS_PATH}/${FILE_NAME}.ipa
/usr/libexec/PlistBuddy -c "Set :items:0:assets:0:url ${IPA_FILE_URL}" $INSTALL_PLIST_PATH

echo '传plist'
OSS_FILE_PATH=cos://$OSS_BUCKET/${OSS_PATH}/${FILE_NAME}.plist
#$SCRIPT_DIR/ossutilmac64 cp $INSTALL_PLIST_PATH $OSS_FILE_PATH -e $OSS_ENDPOINT -i $OSS_ACCESS_KEY_ID -k $OSS_ACCESS_KEY_SECRET -f
$SCRIPT_DIR/coscli cp $INSTALL_PLIST_PATH $OSS_FILE_PATH --endpoint $OSS_ENDPOINT

# 生成二维码
QRCODE_FILE_PATH=${EXPORT_PATH}/qrcode.png
PLIST_FILE_URL=${OSS_HOST}/${OSS_PATH}/${FILE_NAME}.plist
python3 $SCRIPT_DIR/generate_qr_code.py "itms-services://?action=download-manifest&url=${PLIST_FILE_URL}" $QRCODE_FILE_PATH

echo '传二维码'
OSS_FILE_PATH=cos://${OSS_BUCKET}/${OSS_PATH}/${FILE_NAME}.png
#$SCRIPT_DIR/ossutilmac64 cp $QRCODE_FILE_PATH $OSS_FILE_PATH -e $OSS_ENDPOINT -i $OSS_ACCESS_KEY_ID -k $OSS_ACCESS_KEY_SECRET -f
$SCRIPT_DIR/coscli cp $QRCODE_FILE_PATH $OSS_FILE_PATH --endpoint $OSS_ENDPOINT

QRCODE_FILE_URL=${OSS_HOST}/${OSS_PATH}/${FILE_NAME}.png

#echo '刷新CDN'
#OBJECT_PATH=https://res.shuangyuxingqiu.com/$OSS_FILE_PATH
#python3 $SCRIPT_DIR/refresh_oss_cdn.py -i $OSS_ACCESS_KEY_ID -k $OSS_ACCESS_KEY_SECRET -r $OBJECT_PATH -t clear
    
# echo '发机器人通知'
sh $SCRIPT_DIR/wxsend.sh $BUILD_VERSION $QRCODE_FILE_URL

# clear
rm -rf $EXPORT_PATH

echo "\n${FILE_NAME}打包完成"
