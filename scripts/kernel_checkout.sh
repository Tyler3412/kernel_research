#!/usr/bin/env bash
set -euo pipefail

KR="${KR:-$HOME/kernel-research}"
LINUX_DIR="${LINUX_DIR:-$KR/linux}"

if [[ ! -d "$LINUX_DIR/.git" ]]; then
  echo "[-] Kernel repo not found at $LINUX_DIR"
  echo "    Clone it first:"
  echo "    git clone https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git $LINUX_DIR"
  exit 1
fi

ref="${1:-}"
if [[ -z "$ref" ]]; then
  echo "Usage: $0 <git-ref>   (e.g., v6.6, v6.1, <commit>)"
  exit 1
fi

pushd "$LINUX_DIR" >/dev/null
git fetch --all --tags
git checkout "$ref"
echo "[+] Checked out: $(git rev-parse --short HEAD)  ($(git describe --tags --always --dirty))"
popd >/dev/null

