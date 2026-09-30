# HyperCore-A16

MIUI/HyperOS core shared libraries for AOSP-based ROMs, extracted from the
`garnet` fastboot ROM `OS3.0.302.0.WNRMIXM` (Android 16, SDK 36).

Built for crDroid on Redmi Note 13 Pro 5G (garnet), arm64-v8a only.

## Changelog

- v1.1 — add `RtMiCloudSDK.apk` (`micloud-sdk`) and
  `security-device-credential-sdk.jar` for the HyperGallery modules.
- v1.0 — initial release (launcher libraries).

## Updates

Releases are published at <https://github.com/mben25/HyperCore-A16/releases>.
`module.prop` carries `updateJson`, so KernelSU Next / Magisk / APatch show an
update button once a new release is out.

To ship an update: bump `version` and `versionCode` in `module.prop`, add an
entry to `CHANGELOG.md`, push to `main`. The Release workflow builds the zip,
generates `update.json` and publishes the release.

## What it provides

| `<uses-library>` name | backing file |
|---|---|
| `com.miui.core` | `/system_ext/framework/miui-framework.jar` |
| `miui`, `miuiframework` | `/system_ext/framework/miui-framework.jar` |
| `com.miui.system` | `/system_ext/app/miuisystem/miuisystem.apk` |
| `com.miui.rom` | `/system_ext/framework/framework-ext-res/framework-ext-res.apk` |
| `pag-hyperos-release.jar` | `/system_ext/framework/pag-hyperos-release.jar` |
| `micloud-sdk` (v1.1) | `/system_ext/priv-app/RtMiCloudSDK/RtMiCloudSDK.apk` (declared in its own manifest) |
| `security-device-credential-sdk.jar` (v1.1) | `/system_ext/framework/security-device-credential-sdk.jar` |
| `libpag.hyperos.so`, `libffavc.hyperos.so` | `/system/lib64/` + `public.libraries.txt` |

## How the payload was chosen

The launcher's manifest declares exactly seven `<uses-library>` entries:

```
com.miui.system          required=false
com.miui.core            required=false
libpag.hyperos.so        required=false
libffavc.hyperos.so      required=false
pag-hyperos-release.jar  required=false
androidx.window.extensions / androidx.window.sidecar   (crDroid already has these)
```

Because they are all `required=false`, a missing one does not block install —
it fails later as `NoClassDefFoundError` the first time the class is touched.
So the payload was picked by dex analysis instead of by copying the old module:
`work/a16core/dexdeps.py` lists every class `MiuiHome.apk` references but does
not define, then set-covers those against every jar/apk in the ROM. 74 such
classes exist; the minimal covering set is

- `miui-framework.jar` — 38 classes (`miui.os.Build`, `miui.content.res.*`, …)
- `pag-hyperos-release.jar` — 9 classes (`org.libpag.*`)
- `framework.jar` — 4 classes (**not shippable**, see below)
- `miuisystem.apk` — 3 classes (`miui.os.FileUtils`, `miui.util.HashUtils`, …)

## Differences from MiuiCore-MagiskModule-v6.8

**HyperOS 3 no longer ships `miui.apk`.** In v6.8, `com.miui.core` resolved to a
140-byte stub `miui.apk` while the real classes arrived via `com.miui.system` →
`miuisystem.apk`, which was itself a byte-identical copy of `miui-framework.jar`.
On A16 nothing declares `com.miui.core` at all and `miuisystem.apk` is a genuine
1.6 MB app, so this module points `com.miui.core` straight at
`miui-framework.jar`.

**Stock `platform-miui.xml` does not declare these names.** On a real HyperOS
device `miui-framework.jar` is on the BOOTCLASSPATH, so the ROM's own
`platform-miui.xml` has no `miui` / `com.miui.core` / `com.miui.system` entries.
`hypercore-libraries.xml` adds them; it does not replace the ROM's file.

**Paths follow the stock A16 layout** (`/system_ext/...`), not v6.8's
`/system/framework`, `/system/app`, `/system/priv-app`.

**The v6.8 shell scripts were not reused.** They are built around payload this
module does not ship — `system/bin/shelld`, `libmiuiblur.so`, `libexmedia.so`,
`libcdsprpc.so`, the `system_10/` and `system_15/` legacy-library fallbacks, and
a `miuisystem.apk` assets extraction step. A16 has no blur/exmedia libraries at
those paths at all. The scripts here are written for the actual payload.

**Gallery libraries (v1.1).** `com.xiaomi.micloud.sdk` (`RtMiCloudSDK.apk`) and
`security-device-credential-sdk.jar` are not needed by the launcher, but the
HyperGalleryAI / HyperGalleryEditor modules declare them as *required*
`<uses-library>` entries — without them PackageManager drops the apps at boot.
Both are copied unmodified from the same ROM.

## Known gaps

These classes are referenced by the launcher and **cannot** be provided:

- `com.xiaomi.freeform.MiuiFreeformStub`, `miui.app.IMiuiFreeFormManager`,
  `miui.app.IMiuiFreeFormGuideTipServices` — these live in HyperOS's patched
  `framework.jar` (BOOTCLASSPATH). Shipping that would replace the ROM's own
  framework. Freeform-window entry points in the launcher will throw.
- `miui.R$attr`, `miui.R$styleable`, `com.miui.internal.R$*` — resource R classes
  that HyperOS generates into the boot classpath. `framework-ext-res.apk` carries
  the resources but has no dex, so the R classes themselves are absent. Theming
  code paths that look up MIUI resource IDs will throw.
- `com.xiaomi.analytics.*`, `miui.log.MiuiSlog`,
  `com.miui.newhome.view.gestureview.*` — only bundled inside other Xiaomi apps
  (MIUICloudBackup, MIUIAICR, the MiuiHome feed). Ad-tracking, logging and
  minus-one-screen paths; safe to leave missing.

v6.8 had the same gaps.

## Install

1. Flash `HyperCore-A16-v1.1.zip` in Magisk or KernelSU.
2. Reboot.
3. Install the HyperOS Launcher mod.

`customize.sh` disables an existing `MiuiCore` module if present — two providers
of the same shared-library name make PackageManager pick one non-deterministically.

`system.prop` sets `ro.control_privapp_permissions=log`. This downgrades
privileged-permission enforcement from "kill the boot" to "log a warning" system
wide, which is a real (if small) reduction in enforcement; it is here because the
launcher mod's privapp whitelist is the usual cause of a boot loop. Remove the
line if you would rather find out loudly.

## Verifying

```
adb logcat -b all | grep -iE "NoClassDefFoundError|ClassNotFound|UnsatisfiedLinkError|miui"
```

Pass condition: `com.miui.home` reaches the home screen with no
`NoClassDefFoundError` on `miui/os/Build` or `miui/os/MiuiInit`.

## Rebuilding from the ROM

```bash
cd hyperOSLauncher
tar -xzf garnet_global_images_*.tgz -C work/a16core/super --strip-components=2 \
  garnet_global_images_OS3.0.302.0.WNRMIXM_16.0/images/super.img
python3 work/a16core/lpunpack.py work/a16core/super/super.img --list
python3 work/a16core/lpunpack.py work/a16core/super/super.img work/a16core/parts/ \
  -p system_a -p system_ext_a -p product_a -p mi_ext_a
fsck.erofs --extract=work/a16core/payload/system_ext_a --no-preserve-owner \
  work/a16core/parts/system_ext_a.img
```

`work/a16core/lpunpack.py` reads the sparse image directly, so no ~10 GB raw
`super.raw.img` is ever written — worth keeping, the extraction needs about
16 GB of free space otherwise.
