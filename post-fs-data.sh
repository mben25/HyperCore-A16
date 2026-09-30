#!/system/bin/sh
MODPATH=${0%/*}

exec 2>"$MODPATH/debug-pfsd.log"
set -x

# pag-hyperos-release.jar is loaded into the launcher process as a shared java
# library, and its PAGView/PAGImageView call System.loadLibrary("pag.hyperos")
# (and "ffavc.hyperos"). An app process may only dlopen libraries listed in the
# system namespace's public.libraries.txt, so the two .so files we ship have to
# be added there or every PAG-backed animation in the launcher dies with
# UnsatisfiedLinkError.
ETC=/system/etc
DES=public.libraries.txt
MODETC="$MODPATH$ETC"
mkdir -p "$MODETC"

if [ -f "$ETC/$DES" ]; then
  cp -af "$ETC/$DES" "$MODETC/$DES"
else
  : > "$MODETC/$DES"
fi

# " 64" marks the entry as 64-bit-only; this module ships no 32-bit variant.
for LIB in libpag.hyperos.so libffavc.hyperos.so; do
  if ! grep -q "^$LIB" "$MODETC/$DES"; then
    echo "$LIB 64" >> "$MODETC/$DES"
  fi
done

chmod 0644 "$MODETC/$DES"
chown 0:0 "$MODETC/$DES"
chcon u:object_r:system_file:s0 "$MODETC/$DES"

# Magisk labels module files system_file by default; the .so files need
# system_lib_file or the linker refuses to map them into an app process.
chcon -R u:object_r:system_lib_file:s0 "$MODPATH/system/lib64"
