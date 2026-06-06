#!/system/bin/sh

while [ "$(getprop sys.boot_completed)" != "1" ]; do
    sleep 5
done

until pm path android >/dev/null 2>&1; do
    sleep 3
done

sleep 15

TARGET="/data/adb/tricky_store/target.txt"

mkdir -p /data/adb/tricky_store
touch "$TARGET"

generate_list() {
    SPECIAL=$(grep -E '[?!]$' "$TARGET" 2>/dev/null)

    {
        [ -n "$SPECIAL" ] && printf '%s\n' "$SPECIAL"

        pm list packages -3 2>/dev/null | \
        sed 's/^package://g' | \
        sort -u | while read -r pkg
        do
            if ! printf '%s\n' "$SPECIAL" | grep -Fqx "${pkg}!"; then
                if ! printf '%s\n' "$SPECIAL" | grep -Fqx "${pkg}?"; then
                    echo "$pkg"
                fi
            fi
        done
    } | sed '/^$/d' | sort -u
}

sync_now() {
    generate_list > "$TARGET.tmp"

    if ! cmp -s "$TARGET" "$TARGET.tmp" 2>/dev/null; then
        mv -f "$TARGET.tmp" "$TARGET"
        chmod 644 "$TARGET"
    else
        rm -f "$TARGET.tmp"
    fi
}

sync_now

while true
do
    sync_now
    sleep 10
done