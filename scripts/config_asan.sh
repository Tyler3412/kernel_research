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

mkdir -p "$BUILD_DIR"

pushd "$LINUX_DIR" >/dev/null

# Start from defconfig
make O="$BUILD_DIR" defconfig

# Helper: enable/disable config options in .config
cfg_enable() { scripts/config --file "$BUILD_DIR/.config" -e "$1"; }
cfg_disable(){ scripts/config --file "$BUILD_DIR/.config" -d "$1"; }

# Debug + symbols
cfg_enable DEBUG_INFO
cfg_enable DEBUG_INFO_DWARF4
cfg_enable FRAME_POINTER
cfg_enable GDB_SCRIPTS
cfg_enable KALLSYMS
cfg_enable KALLSYMS_ALL

# Sanitizers / debugging
cfg_enable KASAN
cfg_enable KASAN_INLINE
cfg_enable SLUB_DEBUG
cfg_enable SLUB_DEBUG_ON
cfg_enable STACKTRACE

# Useful for repros / stable logs
cfg_enable PANIC_ON_OOPS

# Optional: reduce noise from mitigations for learning (leave on if you want realism)
cfg_disable RANDOMIZE_BASE   # KASLR (we also pass "nokaslr" in cmdline)

# Finalize
make O="$BUILD_DIR" olddefconfig

echo "[+] Config written to $BUILD_DIR/.config"
popd >/dev/null

