#!/system/bin/sh

find_resetprop() {
    for candidate in             /data/adb/ksu/bin/resetprop             /data/adb/magisk/resetprop             /data/adb/modules/hosts/system/bin/resetprop             /system/xbin/resetprop             /system/bin/resetprop             resetprop; do
        if [ "$candidate" = "resetprop" ]; then
            command -v resetprop >/dev/null 2>&1 && {
                command -v resetprop
                return 0
            }
        elif [ -x "$candidate" ]; then
            printf '%s' "$candidate"
            return 0
        fi
    done
    return 1
}

RESETPROG=$(find_resetprop)
[ -n "$RESETPROG" ] || RESETPROG="setprop"

setp() {
    "$RESETPROG" -n "$1" "$2" 2>/dev/null
}

delp() {
    "$RESETPROG" --delete "$1" 2>/dev/null
}

if [ "$RESETPROG" != "setprop" ]; then
    bg_guard() {
        while true; do
            setp persist.sys.usb.config mtp
            setp persist.sys.adb.engineermode 0
            setp init.svc.adbd stopped
            setp sys.usb.config mtp
            setp sys.usb.state mtp
            delp persist.sys.adb.engineermode
            delp persist.sys.usb.config
            delp sys.usb.config
            delp sys.usb.state
            sleep 10
        done
    }
    bg_guard &
fi

while [ "$(getprop sys.boot_completed)" != "1" ]; do
    sleep 2
done

MAGISKBOOT=""
for candidate in /data/adb/magisk/magiskboot /data/adb/ksu/bin/magiskboot; do
    [ -x "$candidate" ] && {
        MAGISKBOOT="$candidate"
        break
    }
done

if [ -n "$MAGISKBOOT" ]; then
    cp /proc/cmdline /data/local/tmp/cmdline.orig 2>/dev/null
    cp /proc/cmdline /data/local/tmp/cmdline.new 2>/dev/null

    sed -i             -e 's/androidboot.verifiedbootstate=orange/androidboot.verifiedbootstate=green/g'             -e 's/androidboot.verifiedbootstate=yellow/androidboot.verifiedbootstate=green/g'             -e 's/androidboot.verifiedbootstate=red/androidboot.verifiedbootstate=green/g'             -e 's/androidboot.vbmeta.device_state=unlocked/androidboot.vbmeta.device_state=locked/g'             -e 's/androidboot.vbmeta.digest=[^ ]*/androidboot.vbmeta.digest=3fa66bd4532520541a69a7de7b8155895a4ecb8b7a7defbaaf72fc9d2f9c4dd3/g'             -e 's/androidboot.flash.locked=0/androidboot.flash.locked=1/g'             /data/local/tmp/cmdline.new 2>/dev/null

    mount --bind /data/local/tmp/cmdline.new /proc/cmdline 2>/dev/null ||         mount -o bind /data/local/tmp/cmdline.new /proc/cmdline 2>/dev/null
fi

resetprop_if_diff() {
    name=$1
    expected=$2
    [ "$("$RESETPROG" "$name" 2>/dev/null)" != "$expected" ] && setp "$name" "$expected"
}

resetprop_if_match() {
    name=$1
    match=$2
    newval=$3
    case "$("$RESETPROG" "$name" 2>/dev/null)" in
        *"$match"*) setp "$name" "$newval" ;;
    esac
}

if [ "$RESETPROG" != "setprop" ]; then
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

    setp ro.boot.verifiedbootstate.orange green
    setp ro.boot.vbmeta.digest ""

    resetprop_if_match ro.boot.mode recovery unknown
    resetprop_if_match ro.bootmode recovery unknown
    resetprop_if_match vendor.boot.mode recovery unknown

    for PROP in $($RESETPROG 2>/dev/null | grep -oE 'ro.*\.build\.tags' 2>/dev/null); do
        resetprop_if_diff "$PROP" release-keys
    done
    for PROP in $($RESETPROG 2>/dev/null | grep -oE 'ro.*\.build\.type' 2>/dev/null); do
        resetprop_if_diff "$PROP" user
    done

    resetprop_if_diff ro.debuggable 0
    resetprop_if_diff ro.force.debuggable 0
    resetprop_if_diff ro.secure 1
    resetprop_if_diff ro.adb.secure 1
    resetprop_if_diff sys.usb.adb.disabled 1

    setp init.svc.adbd stopped
    setp persist.sys.usb.config mtp
    setp sys.usb.config mtp
    setp sys.usb.state mtp
    setp persist.sys.adb.engineermode 0
    delp persist.sys.adb.engineermode
    delp sys.usb.config
    delp sys.usb.state
    delp persist.log.tag.LSPosed
    delp persist.log.tag.LSPosed-Bridge

    for leak in             ro.build.version.security_patch_vendor             ro.build.version.security_patch_real             ro.config.low_ram             ro.build.selinux             persist.magisk.hide             persist.zygisk.changed             ro.boot.vbmeta.digest; do
        delp "$leak"
        setp "$leak" ""
    done
fi

setprop persist.logd.size "" 2>/dev/null
setprop persist.logd.size.crash "" 2>/dev/null
setprop persist.logd.size.system "" 2>/dev/null
setprop persist.logd.size.main "" 2>/dev/null

if [ "$(toybox cat /sys/fs/selinux/enforce 2>/dev/null)" = "0" ]; then
    chmod 640 /sys/fs/selinux/enforce 2>/dev/null
    chmod 440 /sys/fs/selinux/policy 2>/dev/null
fi
