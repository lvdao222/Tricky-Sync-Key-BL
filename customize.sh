#!/system/bin/sh
SKIPUNZIP=0

T_DIR="/data/adb/tricky_store"
T_FILE="$T_DIR/target.txt"

mkdir -p "$T_DIR" && chmod 755 "$T_DIR"
[ ! -f "$T_FILE" ] && touch "$T_FILE" && chmod 644 "$T_FILE"

set_perm_recursive "$MODPATH" 0 0 0755 0644
set_perm "$MODPATH/service.sh" 0 0 0755
set_perm "$MODPATH/action.sh" 0 0 0755
set_perm "$MODPATH/key.sh" 0 0 0755
set_perm "$MODPATH/sync.sh" 0 0 0755
set_perm "$MODPATH/Hide_BootLoader.sh" 0 0 0755

ui_print "- 核心环境检查完成"
ui_print "- 开机后将自动执行包名同步与弱BL隐藏"
ui_print "- Manager 中执行 Action 可触发在线替换 Keybox"
