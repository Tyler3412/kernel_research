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

# Kernel source tree path (where scripts/gdb/vmlinux-gdb.py lives)
LINUX_SRC="${LINUX_SRC:-$KR/linux}"
VMLINUX_GDB_PY="$LINUX_SRC/scripts/gdb/vmlinux-gdb.py"

# If you ever rename/move your repo, this mapping fixes source lookups.
# Old path is whatever is embedded in DWARF at build time.
OLD_SRC_PREFIX="${OLD_SRC_PREFIX:-/home/tyler/kernel_research}"
NEW_SRC_PREFIX="${NEW_SRC_PREFIX:-$KR}"

GDB_EX=(
  -ex "set pagination off"
  -ex "set confirm off"
  -ex "set print pretty on"
  -ex "set disassemble-next-line on"
  -ex "set substitute-path $OLD_SRC_PREFIX $NEW_SRC_PREFIX"
)

# Load kernel-aware GDB helpers if present
if [[ -f "$VMLINUX_GDB_PY" ]]; then
  GDB_EX+=(-ex "source $VMLINUX_GDB_PY")
else
  echo "[!] Warning: kernel gdb script not found at: $VMLINUX_GDB_PY"
  echo "    (Did you set LINUX_SRC correctly? Current: $LINUX_SRC)"
fi

# Attach and break
GDB_EX+=(
  -ex "target remote :1234"
  -ex "hbreak start_kernel"
  -ex "continue"
)

exec gdb -q "$VMLINUX" "${GDB_EX[@]}"

