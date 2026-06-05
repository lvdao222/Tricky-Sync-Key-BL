#!/system/bin/sh

MODDIR=${0%/*}

while [ "$(getprop sys.boot_completed)" != "1" ]; do
    sleep 5
done

if [ -f "$MODDIR/sync.sh" ]; then
    setsid sh "$MODDIR/sync.sh" >/dev/null 2>&1 < /dev/null &
fi
