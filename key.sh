#!/system/bin/sh

DIR=/data/adb/tricky_store
URLS="https://raw.githubusercontent.com/Yurii0307/yurikey/main/key https://cdn.jsdelivr.net/gh/Yurii0307/yurikey@main/key"
TARGET=$DIR/keybox.xml
TMP=$DIR/keybox.tmp
BAK=$DIR/keybox.xml.bak

[ -d "$DIR" ] || { echo "没目录 请尝试安装Tricky Store 或 TEESimulator 后重试"; exit 1; }

if command -v curl >/dev/null 2>&1; then
    DL_MODE=curl
elif command -v wget >/dev/null 2>&1; then
    DL_MODE=wget
elif command -v busybox >/dev/null 2>&1; then
    DL_MODE=busybox
elif command -v toybox >/dev/null 2>&1; then
    DL_MODE=toybox
else
    echo "未找到下载工具"; exit 1
fi

download_file() {
    src="$1"
    case "$DL_MODE" in
        curl) curl -fsSL --retry 2 --connect-timeout 10 -o "$TMP" "$src" ;;
        wget) wget -qO "$TMP" "$src" ;;
        busybox) busybox wget -qO "$TMP" "$src" ;;
        toybox) toybox wget -qO "$TMP" "$src" ;;
    esac
}

[ -f "$TARGET" ] && cp "$TARGET" "$BAK"

: > "$TMP"
for URL in $URLS; do
    download_file "$URL" && break
done || {
    echo "替换失败 请检查网络"
    [ -f "$BAK" ] && cp "$BAK" "$TARGET"
    rm -f "$TMP"
    exit 1
}

if grep -aq '<' "$TMP"; then
    mv "$TMP" "$TARGET"
else
    base64 -d "$TMP" > "$TARGET" 2>/dev/null || {
        echo "替换失败 文件解码错误"
        [ -f "$BAK" ] && cp "$BAK" "$TARGET"
        rm -f "$TMP"
        exit 1
    }
fi

[ -s "$TARGET" ] && { echo "替换成功"; rm -f "$TMP"; } || {
    echo "替换失败 文件为空"
    [ -f "$BAK" ] && cp "$BAK" "$TARGET"
    exit 1
}
