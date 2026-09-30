#!/system/bin/sh
# Nothing outside the module directory is written at install time, so removal is
# just Magisk deleting the module. Drop the cached dexopt artefacts for the
# shared libraries so a later reinstall does not reuse stale odex.
rm -rf /data/dalvik-cache/arm64/system_ext@framework@miui-framework.jar*
rm -rf /data/dalvik-cache/arm64/system_ext@framework@pag-hyperos-release.jar*
rm -rf /data/dalvik-cache/arm64/system_ext@framework@security-device-credential-sdk.jar*
