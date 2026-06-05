#!/system/bin/sh

while [ "$(getprop sys.boot_completed)" != "1" ]; do
    sleep 5
done

until pm path android >/dev/null 2>&1; do
    sleep 3
done

sleep 30

TARGET="/data/adb/tricky_store/target.txt"
mkdir -p /data/adb/tricky_store
touch "$TARGET"

sync_now() {
    SPECIAL=$(grep -E '[?!]$' "$TARGET" 2>/dev/null)

    {
        [ -n "$SPECIAL" ] && echo "$SPECIAL"

        pm list packages -3 2>/dev/null |         sed 's/^package://g' |         sort -u | while read -r pkg; do

            if ! printf '%s\n' "$SPECIAL" | grep -Fqx "${pkg}!" &&                ! printf '%s\n' "$SPECIAL" | grep -Fqx "${pkg}?"; then
                echo "$pkg"
            fi
        done
    } | sed '/^$/d' | sort -u > "$TARGET.tmp"

    mv "$TARGET.tmp" "$TARGET"
    chmod 644 "$TARGET"
}

sync_now

LAST_PKGS=""

while true; do
    CUR_PKGS=$(pm list packages -3 2>/dev/null | sed 's/^package://g' | sort)

    if [ "$CUR_PKGS" != "$LAST_PKGS" ]; then
        sync_now
        LAST_PKGS="$CUR_PKGS"
    fi

    sleep 10
done
