#!/system/bin/sh

while [ "$(getprop sys.boot_completed)" != "1" ]; do 
    sleep 5
done

if [ -f "$MODDIR/Hide_BootLoader.sh" ]; then
    . "$MODDIR/Hide_BootLoader.sh"
fi

if [ -f "$MODDIR/sync.sh" ]; then
    sh "$MODDIR/sync.sh" &
fi
