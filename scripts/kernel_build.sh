#!/usr/bin/env bash
set -euo pipefail

KR="${KR:-$HOME/kernel-research}"
LINUX_DIR="${LINUX_DIR:-$KR/linux}"

BUILD_DIR="${1:-}"
if [[ -z "$BUILD_DIR" ]]; then
  echo "Usage: $0 <build-dir>"
  echo "Example: $0 $KR/build/v6.6-vuln-kasan"
  exit 1
fi

if [[ ! -f "$BUILD_DIR/.config" ]]; then
  echo "[-] No .config in $BUILD_DIR"
  echo "    Run: scripts/kernel-config-kasan.sh $BUILD_DIR"
  exit 1
fi

pushd "$LINUX_DIR" >/dev/null
make -j"$(nproc)" O="$BUILD_DIR"
echo "[+] Built:"
echo "    bzImage: $BUILD_DIR/arch/x86/boot/bzImage"
echo "    vmlinux: $BUILD_DIR/vmlinux"
popd >/dev/null

