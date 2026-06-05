#!/system/bin/sh

TARGET="/data/adb/tricky_store/target.txt"

wait_boot() {
    while [ "$(getprop sys.boot_completed)" != "1" ]; do
        sleep 3
    done
    until pm path android >/dev/null 2>&1; do
        sleep 2
    done
}

get_pkgs() {
    pm list packages -3 2>/dev/null | sed 's/^package://g' | sort -u
}

sync_now() {
    [ -f "$TARGET" ] || : > "$TARGET"

    SPECIAL_LINES=$(grep -E '^[^#].*[!?]$' "$TARGET" 2>/dev/null | sed '/^$/d')
    CUR_PKGS=$(get_pkgs)

    {
        [ -n "$SPECIAL_LINES" ] && printf '%s\n' "$SPECIAL_LINES"

        printf '%s\n' "$CUR_PKGS" | while IFS= read -r pkg; do
            [ -n "$pkg" ] || continue

            if ! printf '%s\n' "$SPECIAL_LINES" | grep -Fqx "${pkg}!" &&                    ! printf '%s\n' "$SPECIAL_LINES" | grep -Fqx "${pkg}?"; then
                printf '%s\n' "$pkg"
            fi
        done
    } | sed '/^$/d' | sort -u > "$TARGET.tmp" && mv "$TARGET.tmp" "$TARGET" && chmod 644 "$TARGET"
}

wait_boot
sleep 10

sync_now
LAST_STATE=$(get_pkgs)

while true; do
    sleep 8
    CURRENT_STATE=$(get_pkgs)

    [ -n "$CURRENT_STATE" ] || continue

    if [ "$CURRENT_STATE" != "$LAST_STATE" ]; then
        sleep 2
        sync_now
        LAST_STATE=$(get_pkgs)
    fi
done
