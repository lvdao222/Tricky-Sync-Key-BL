#!/system/bin/sh
MODDIR=${0%/*}

start_bg() {
    script="$1"
    [ -f "$script" ] || return 0
    setsid sh "$script" >/dev/null 2>&1 < /dev/null &
}

while [ "$(getprop sys.boot_completed)" != "1" ]; do
    sleep 3
done

until pm path android >/dev/null 2>&1; do
    sleep 2
done

sleep 5

start_bg "$MODDIR/sync.sh"
start_bg "$MODDIR/Hide_BootLoader.sh"
exit 0
