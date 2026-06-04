#!/system/bin/sh

while [ "$(getprop sys.boot_completed)" != "1" ]; do sleep 5; done
while ! dumpsys activity activities 2>/dev/null | grep -A 5 "KeyguardController:" | grep -q "mKeyguardShowing=false"; do sleep 2; done

TARGET="/data/adb/tricky_store/target.txt"

sync_now() {
    [ -f "$TARGET" ] || touch "$TARGET"
    SPECIAL=$(grep -E '[?!]$' "$TARGET" 2>/dev/null)

    {
        [ -n "$SPECIAL" ] && echo "$SPECIAL"
        pm list packages -3 2>/dev/null | sed 's/^package://g' | while read -r pkg; do
            if ! echo "$SPECIAL" | grep -qx "${pkg}[?!]"; then
                echo "$pkg"
            fi
        done
    } | sort -u > "$TARGET.tmp"

    mv "$TARGET.tmp" "$TARGET"
    chmod 644 "$TARGET"
}

sync_now
LAST_STATE=$(ls /data/app | sort)

while true; do
    sleep 15
    CURRENT_STATE=$(ls /data/app | sort)
    if [ "$CURRENT_STATE" != "$LAST_STATE" ]; then
        sleep 5
        sync_now
        LAST_STATE=$(ls /data/app | sort)
    fi
done
