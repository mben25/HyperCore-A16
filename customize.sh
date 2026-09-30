#!/system/bin/sh
# HyperCore-A16 installer

SKIPUNZIP=0

ui_print " "
ui_print "- HyperCore-A16"
ui_print "  source: garnet HyperOS OS3.0.302.0.WNRMIXM (Android 16, SDK 36)"
ui_print " "

# --- architecture ---------------------------------------------------------
ABILIST=$(getprop ro.product.cpu.abilist)
[ -z "$ABILIST" ] && ABILIST=$(getprop ro.system.product.cpu.abilist)
case "$ABILIST" in
  *arm64-v8a*) ;;
  *)
    ui_print "! This module ships arm64-v8a binaries only."
    ui_print "  Detected ABI list: $ABILIST"
    abort
    ;;
esac
ui_print "- arm64-v8a OK"

# --- sdk ------------------------------------------------------------------
# The jars are compiled against SDK 36. SDK 34 is the launcher's minSdk and the
# oldest level where these dex files still verify.
if [ "$API" -lt 34 ]; then
  ui_print "! SDK $API is too old. SDK 34+ required."
  abort
fi
if [ "$API" -lt 36 ]; then
  ui_print "! SDK $API detected, but these libraries came from SDK 36."
  ui_print "  Install anyway, but expect verifier warnings in logcat."
fi
ui_print "- SDK $API"

# --- conflicting modules --------------------------------------------------
# The old MiuiCore port declares the same shared-library names; two providers of
# com.miui.core make PackageManager pick one at random.
for OLD in MiuiCore MIUICore miui_core; do
  if [ -d /data/adb/modules/$OLD ]; then
    ui_print "- Disabling conflicting module: $OLD"
    touch /data/adb/modules/$OLD/remove
  fi
done

# --- permissions ----------------------------------------------------------
set_perm_recursive "$MODPATH" 0 0 0755 0644
set_perm_recursive "$MODPATH/system" 0 0 0755 0644 u:object_r:system_file:s0
set_perm_recursive "$MODPATH/system/lib64" 0 0 0755 0644 u:object_r:system_lib_file:s0

ui_print " "
ui_print "- Installed. Reboot, then install the HyperOS Launcher."
ui_print " "
