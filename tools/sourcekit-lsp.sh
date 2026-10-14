#!/bin/bash
set -euo pipefail
tooling_root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$tooling_root"
if [[ ! -x .tools/sourcekit-lsp || ! -f .bsp/skbsp.json ]]; then
    echo 'Run ./tools/setup-tooling.sh from this checkout before starting SourceKit-LSP.' >&2
    exit 1
fi
# Bazel's output base is named after the MD5 of the checkout path. The index prefix
# map must point at this checkout's output base, or symbols resolve to nothing.
output_base_hash="$(md5 -qs "$(pwd -P)")"
if ! grep -q "/$output_base_hash/" .sourcekit-lsp/config.json; then
    echo 'The SourceKit-LSP index prefix map belongs to another checkout path. Rerun ./tools/setup-tooling.sh.' >&2
    exit 1
fi
export DEVELOPER_DIR="${DEVELOPER_DIR:-$(xcode-select -p)}"
# Keep LSP and the Bazel compiler on the same selected Apple toolchain.
export SOURCEKIT_TOOLCHAIN_PATH="$DEVELOPER_DIR/Toolchains/XcodeDefault.xctoolchain"
exec "$tooling_root/.tools/sourcekit-lsp" "$@"
