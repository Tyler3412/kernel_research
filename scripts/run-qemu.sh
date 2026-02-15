#!/usr/bin/env bash
set -euo pipefail

KR="${KR:-$HOME/kernel-research}"

BUILD_DIR="${1:-}"
if [[ -z "$BUILD_DIR" ]]; then
  echo "Usage: $0 <build-dir>"
  echo "Example: $0 $KR/build/v6.6-vuln-kasan"
  exit 1
fi

BZIMAGE="$BUILD_DIR/arch/x86/boot/bzImage"
VMLINUX="$BUILD_DIR/vmlinux"
INITRAMFS="$KR/rootfs/rootfs.cpio.gz"
# INITRAMFS="$KR/buildroot-out/images/rootfs.cpio.gz"
SHARED="$KR/shared"

if [[ ! -f "$BZIMAGE" ]]; then
  echo "[-] Missing bzImage: $BZIMAGE"
  exit 1
fi
if [[ ! -f "$INITRAMFS" ]]; then
  echo "[-] Missing initramfs: $INITRAMFS"
  echo "    Run: scripts/build-rootfs-busybox.sh"
  exit 1
fi

mkdir -p "$SHARED"

# QEMU flags:
# -s opens gdbserver on :1234
# -S pauses at start so you can set breakpoints
qemu-system-x86_64 \
  -m 2G \
  -kernel "$BZIMAGE" \
  -initrd "$INITRAMFS" \
  -append "console=ttyS0 nokaslr panic=1 oops=panic loglevel=7" \
  -nographic \
  -s -S \
  -virtfs local,path="$SHARED",mount_tag=hostshare,security_model=passthrough,id=hostshare

echo "[i] Tip: in another terminal run: scripts/attach-gdb.sh $BUILD_DIR"

