#!/usr/bin/env bash
set -euo pipefail

KR="${KR:-$HOME/kernel-research}"
BUILD_DIR="${1:-}"

if [[ -z "$BUILD_DIR" ]]; then
  echo "Usage: $0 <build-dir>"
  echo "Example: $0 $KR/build/v6.6-vuln-kasan"
  exit 1
fi

VMLINUX="$BUILD_DIR/vmlinux"
if [[ ! -f "$VMLINUX" ]]; then
  echo "[-] Missing vmlinux: $VMLINUX"
  exit 1
fi

gdb -q "$VMLINUX" \
  -ex "set pagination off" \
  -ex "target remote :1234" \
  -ex "hbreak start_kernel" \
  -ex "continue"

