#!/system/bin/sh
MODPATH=${0%/*}

exec 2>"$MODPATH/debug-service.log"
set -x

# miui.os.Build reads these at class-init time. Without them IS_MIUI_LITE_VERSION
# / IS_INTERNATIONAL_BUILD and friends resolve against empty props, which is what
# produces the launcher's early NoClassDefFoundError / wrong-branch behaviour on
# an AOSP ROM. Values below match the source ROM (garnet, OS3.0.302.0.WNRMIXM).
resetprop -n ro.miui.ui.version.code 816
resetprop -n ro.miui.ui.version.name V816
resetprop -n ro.mi.os.version.code 3
resetprop -n ro.mi.os.version.name OS3.0
resetprop -n ro.mi.os.version.incremental OS3.0.302.0.WNRMIXM
resetprop -n ro.miui.build.region global
resetprop -n ro.miui.region "$(getprop ro.csc.countryiso_code)"

# Window/animation features the launcher's recents and freeform paths check for.
resetprop -n ro.config.miui_magic_window_enable true
resetprop -n ro.config.miui_multiwindow_optimization true
resetprop -n ro.config.miui_multi_window_switch_enable true

until [ "$(getprop sys.boot_completed)" = 1 ]; do
  sleep 5
done

# com.miui.system is installed as a shared-library APK; keep it from being
# hibernated, which would unload the library out from under the launcher.
if appops get com.miui.system >/dev/null 2>&1; then
  appops set com.miui.system AUTO_REVOKE_PERMISSIONS_IF_UNUSED ignore
fi
if appops get com.miui.rom >/dev/null 2>&1; then
  appops set com.miui.rom AUTO_REVOKE_PERMISSIONS_IF_UNUSED ignore
fi
if appops get com.xiaomi.micloud.sdk >/dev/null 2>&1; then
  appops set com.xiaomi.micloud.sdk AUTO_REVOKE_PERMISSIONS_IF_UNUSED ignore
fi
