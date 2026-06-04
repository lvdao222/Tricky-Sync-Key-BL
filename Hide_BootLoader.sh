#!/system/bin/sh

bg_guard() {
    while true; do
        resetprop -n persist.sys.usb.config mtp 2>/dev/null
        resetprop -n persist.sys.adb.engineermode 0 2>/dev/null
        resetprop -n init.svc.adbd stopped 2>/dev/null
        resetprop -n sys.usb.config mtp 2>/dev/null
        resetprop -n sys.usb.state mtp 2>/dev/null
        resetprop --delete persist.sys.adb.engineermode 2>/dev/null
        resetprop --delete persist.sys.usb.config 2>/dev/null
        sleep 10
    done
}
bg_guard &

while [ "$(getprop sys.boot_completed)" != "1" ]; do
    sleep 2
done

RESETPROG=""
for candidate in resetprop \
    /data/adb/ksu/bin/resetprop \
    /data/adb/magisk/resetprop \
    /data/adb/modules/hosts/system/bin/resetprop \
    /system/xbin/resetprop \
    /system/bin/resetprop; do
    if command -v "$candidate" >/dev/null 2>&1; then
        RESETPROG="$candidate"
        break
    fi
done
[ -z "$RESETPROG" ] && RESETPROG="setprop"

MAGISKBOOT=""
for candidate in /data/adb/magisk/magiskboot /data/adb/ksu/bin/magiskboot; do
    [ -x "$candidate" ] && { MAGISKBOOT="$candidate"; break; }
done

if [ -n "$MAGISKBOOT" ]; then
    cp /proc/cmdline /data/local/tmp/cmdline.orig 2>/dev/null
    cp /proc/cmdline /data/local/tmp/cmdline.new 2>/dev/null
    sed -i \
        -e 's/androidboot.verifiedbootstate=orange/androidboot.verifiedbootstate=green/g' \
        -e 's/androidboot.verifiedbootstate=yellow/androidboot.verifiedbootstate=green/g' \
        -e 's/androidboot.verifiedbootstate=red/androidboot.verifiedbootstate=green/g' \
        -e 's/androidboot.vbmeta.device_state=unlocked/androidboot.vbmeta.device_state=locked/g' \
        -e 's/androidboot.vbmeta.digest=[^ ]*/androidboot.vbmeta.digest=3fa66bd4532520541a69a7de7b8155895a4ecb8b7a7defbaaf72fc9d2f9c4dd3/g' \
        -e 's/androidboot.flash.locked=0/androidboot.flash.locked=1/g' \
        /data/local/tmp/cmdline.new 2>/dev/null
    mount --bind /data/local/tmp/cmdline.new /proc/cmdline 2>/dev/null
fi

resetprop_if_diff() {
    local NAME=$1 EXPECTED=$2
    [ "$($RESETPROG $NAME)" != "$EXPECTED" ] && $RESETPROG -n "$NAME" "$EXPECTED" 2>/dev/null
}

resetprop_if_match() {
    local NAME=$1 MATCH=$2 NEWVAL=$3
    case "$($RESETPROG $NAME)" in
        *"$MATCH"*) $RESETPROG -n "$NAME" "$NEWVAL" 2>/dev/null ;;
    esac
}

resetprop_if_diff ro.boot.verifiedbootstate green
resetprop_if_diff ro.boot.verifiedbootstate2 green
resetprop_if_diff ro.boot.flash.locked 1
resetprop_if_diff ro.boot.vbmeta.device_state locked
resetprop_if_diff ro.boot.veritymode enforcing
resetprop_if_diff ro.boot.warranty_bit 0
resetprop_if_diff ro.warranty_bit 0
resetprop_if_diff ro.vendor.boot.warranty_bit 0
resetprop_if_diff ro.vendor.warranty_bit 0
resetprop_if_diff vendor.boot.vbmeta.device_state locked
resetprop_if_diff vendor.boot.verifiedbootstate green
resetprop_if_diff sys.oem_unlock_allowed 0
resetprop_if_diff ro.is_ever_orange 0
resetprop_if_diff ro.secureboot.lockstate locked
resetprop_if_diff ro.boot.realmebootstate green
resetprop_if_diff ro.boot.realme.lockstate 1
resetprop_if_diff ro.boot.selinux enforcing

$RESETPROG -n "ro.boot.verifiedbootstate.orange" "green" 2>/dev/null
$RESETPROG -n "ro.boot.vbmeta.digest" "" 2>/dev/null

resetprop_if_match ro.boot.mode recovery unknown
resetprop_if_match ro.bootmode recovery unknown
resetprop_if_match vendor.boot.mode recovery unknown

for PROP in $(resetprop | grep -oE 'ro.*.build.tags'); do
    resetprop_if_diff "$PROP" release-keys
done
for PROP in $(resetprop | grep -oE 'ro.*.build.type'); do
    resetprop_if_diff "$PROP" user
done

resetprop_if_diff ro.debuggable 0
resetprop_if_diff ro.force.debuggable 0
resetprop_if_diff ro.secure 1
resetprop_if_diff ro.adb.secure 1
resetprop_if_diff sys.usb.adb.disabled 1

$RESETPROG -n "init.svc.adbd" "stopped" 2>/dev/null
$RESETPROG -n "persist.sys.usb.config" "mtp" 2>/dev/null
$RESETPROG -n "sys.usb.config" "mtp" 2>/dev/null
$RESETPROG -n "sys.usb.state" "mtp" 2>/dev/null
$RESETPROG -n "persist.sys.adb.engineermode" "0" 2>/dev/null
$RESETPROG --delete "persist.sys.adb.engineermode" 2>/dev/null
$RESETPROG --delete "sys.usb.config" 2>/dev/null
$RESETPROG --delete "sys.usb.state" 2>/dev/null
$RESETPROG --delete "persist.log.tag.LSPosed" 2>/dev/null
$RESETPROG --delete "persist.log.tag.LSPosed-Bridge" 2>/dev/null

for leak in \
    ro.build.version.security_patch_vendor \
    ro.build.version.security_patch_real \
    ro.config.low_ram \
    ro.build.selinux \
    persist.magisk.hide \
    persist.zygisk.changed \
    ro.boot.vbmeta.digest; do
    $RESETPROG --delete "$leak" 2>/dev/null || \
    $RESETPROG -n "$leak" "" 2>/dev/null
done

setprop persist.logd.size "" 2>/dev/null
setprop persist.logd.size.crash "" 2>/dev/null
setprop persist.logd.size.system "" 2>/dev/null
setprop persist.logd.size.main "" 2>/dev/null

if [ "$(toybox cat /sys/fs/selinux/enforce 2>/dev/null)" = "0" ]; then
    chmod 640 /sys/fs/selinux/enforce 2>/dev/null
    chmod 440 /sys/fs/selinux/policy 2>/dev/null
fi