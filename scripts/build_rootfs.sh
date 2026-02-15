#!/usr/bin/env bash
set -euo pipefail

KR="${KR:-$HOME/kernel-research}"
BR_DIR="${BR_DIR:-$KR/buildroot}"
OUT_ROOTFS_DIR="$KR/rootfs"

# Optional: pin to a stable tag like "2025.02.1"
BR_TAG="${BR_TAG:-}"

# Buildroot build output dir (kept separate from repo)
BR_OUT="${BR_OUT:-$BR_DIR/output}"

# Where to store our Buildroot defconfig + overlay inside the lab
CFG_DIR="$OUT_ROOTFS_DIR/buildroot"
DEFCONFIG="$CFG_DIR/defconfig"
OVERLAY="$CFG_DIR/overlay"

mkdir -p "$OUT_ROOTFS_DIR" "$CFG_DIR" "$OVERLAY/etc/init.d" "$KR/shared"

# 1) Fetch Buildroot if needed
if [[ ! -d "$BR_DIR/.git" ]]; then
  echo "[*] Cloning Buildroot into: $BR_DIR"
  git clone https://github.com/buildroot/buildroot.git "$BR_DIR"
fi

pushd "$BR_DIR" >/dev/null

# 2) Optionally pin Buildroot to a stable tag
if [[ -n "$BR_TAG" ]]; then
  echo "[*] Checking out Buildroot tag: $BR_TAG"
  git fetch --all --tags
  git checkout "$BR_TAG"
else
  echo "[*] Using Buildroot current branch: $(git rev-parse --abbrev-ref HEAD)"
  git pull --ff-only || true
fi

# 3) Create a small rootfs overlay that mounts 9p (hostshare) if present
cat > "$OVERLAY/etc/init.d/S02hostshare" <<'EOF'
#!/bin/sh
# Mount proc/sys/dev and attempt to mount a 9p host share at /mnt/host.
# Works with QEMU: -virtfs local,path=...,mount_tag=hostshare,...

mkdir -p /proc /sys /dev /mnt/host

mount -t proc none /proc 2>/dev/null || true
mount -t sysfs none /sys 2>/dev/null || true
mount -t devtmpfs none /dev 2>/dev/null || true

# Try to mount hostshare; ignore failures (not always provided)
mount -t 9p -o trans=virtio,version=9p2000.L hostshare /mnt/host 2>/dev/null || true

exit 0
EOF
chmod +x "$OVERLAY/etc/init.d/S02hostshare"

# 4) Generate a Buildroot defconfig (non-interactive)
# Minimal: x86_64 + initramfs (cpio.gz) + root login on console
cat > "$DEFCONFIG" <<EOF
BR2_x86_64=y

# Toolchain (Buildroot defaults are fine)
BR2_TOOLCHAIN_BUILDROOT_GLIBC=y

# System
BR2_TARGET_GENERIC_GETTY=y
BR2_TARGET_GENERIC_GETTY_PORT="ttyS0"
BR2_TARGET_GENERIC_GETTY_BAUDRATE_KEEP=y
BR2_TARGET_GENERIC_ROOT_PASSWD="root"

# Rootfs overlay (adds /etc/init.d/S02hostshare)
BR2_ROOTFS_OVERLAY="$OVERLAY"

# Filesystem image
BR2_TARGET_ROOTFS_CPIO=y
BR2_TARGET_ROOTFS_CPIO_GZIP=y
EOF

echo "[*] Defconfig written: $DEFCONFIG"

# 5) Configure and build
# Use O= output directory so build artifacts don't pollute the git tree
echo "[*] Configuring Buildroot (O=$BR_OUT)"
make O="$BR_OUT" BR2_DEFCONFIG="$DEFCONFIG" defconfig

echo "[*] Building Buildroot rootfs..."
make -j"$(nproc)" O="$BR_OUT"

# 6) Copy artifacts into your lab's rootfs/ as base.cpio(.gz)
IMG_DIR="$BR_OUT/images"
SRC_CPIO_GZ="$IMG_DIR/rootfs.cpio.gz"

if [[ ! -f "$SRC_CPIO_GZ" ]]; then
  echo "[-] Expected Buildroot output not found: $SRC_CPIO_GZ"
  echo "    Check: $IMG_DIR"
  exit 1
fi

mkdir -p "$OUT_ROOTFS_DIR"
cp -f "$SRC_CPIO_GZ" "$OUT_ROOTFS_DIR/base.cpio.gz"
gunzip -c "$SRC_CPIO_GZ" > "$OUT_ROOTFS_DIR/base.cpio"

echo "[+] RootFS ready:"
echo "    $OUT_ROOTFS_DIR/base.cpio.gz"
echo "    $OUT_ROOTFS_DIR/base.cpio"

popd >/dev/null

