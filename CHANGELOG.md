# HyperCore A16 changelog

## v1.2-OS3.0.302.0.WNRMIXM (3)
- `com.miui.system` and `com.miui.rom` now depend on `com.miui.core`, so apps that only declare those two libraries also get `miui-framework.jar`. Fixes HyperGalleryAI crashing at launch with `NoClassDefFoundError: miui.os.Build`.

## v1.1-OS3.0.302.0.WNRMIXM (2)
- Add `RtMiCloudSDK.apk` (`micloud-sdk`) and `security-device-credential-sdk.jar` for the HyperGallery modules.
- Add `updateJson` so KernelSU Next / Magisk / APatch can update the module from the manager.

## v1.0-OS3.0.302.0.WNRMIXM (1)
- Initial release (HyperOS Launcher libraries).
