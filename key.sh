#!/system/bin/sh

DIR=/data/adb/tricky_store
URL=https://raw.githubusercontent.com/Yurii0307/yurikey/main/key
TARGET=$DIR/keybox.xml
TMP=$DIR/keybox.tmp
BAK=$DIR/keybox.xml.bak

[ -d "$DIR" ] || { echo "没目录 请尝试安装Tricky Store 或 TEESimulator 后重试"; exit 1; }

if command -v curl >/dev/null; then
    DL="curl -fsSL -o"
elif command -v wget >/dev/null; then
    DL="wget -qO"
elif command -v toybox >/dev/null; then
    DL="toybox wget -qO"
else
    echo "未找到下载工具"; exit 1
fi

[ -f "$TARGET" ] && cp "$TARGET" "$BAK"

$DL "$TMP" "$URL" || { echo "替换失败 请检查网络"; [ -f "$BAK" ] && cp "$BAK" "$TARGET"; exit 1; }

if head -c5 "$TMP" | grep -q '<?xml'; then
    mv "$TMP" "$TARGET"
else
    base64 -d "$TMP" > "$TARGET" 2>/dev/null || { echo "替换失败 文件解码错误"; [ -f "$BAK" ] && cp "$BAK" "$TARGET"; rm -f "$TMP"; exit 1; }
fi

[ -s "$TARGET" ] && { echo "替换成功"; rm -f "$TMP"; } || { echo "替换失败 文件为空"; [ -f "$BAK" ] && cp "$BAK" "$TARGET"; exit 1; }