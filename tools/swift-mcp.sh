#!/bin/bash
set -euo pipefail
tooling_root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$tooling_root"
if [[ ! -f .bsp/skbsp.json || ! -f .sourcekit-lsp/config.json ]]; then
    echo 'Run ./tools/setup-tooling.sh from this checkout before starting the Swift MCP bridge.' >&2
    exit 1
fi
# Bazel's output base is named after the MD5 of the checkout path. The index prefix
# map must point at this checkout's output base, or symbols resolve to nothing.
if ! grep -q "/$(md5 -qs "$(pwd -P)")/" .sourcekit-lsp/config.json; then
    echo 'The SourceKit-LSP index prefix map belongs to another checkout path. Rerun ./tools/setup-tooling.sh.' >&2
    exit 1
fi
export DEVELOPER_DIR="${DEVELOPER_DIR:-$(xcode-select -p)}"
# Use the selected Xcode's SourceKit-LSP, the same one VS Code starts. It finds the
# Bazel BSP through .bsp/skbsp.json and .sourcekit-lsp/config.json.
export SOURCEKIT_LSP_PATH="$(xcrun --find sourcekit-lsp)"
exec "$tooling_root/.tools/swift-mcp-server/.build/release/swift-mcp-server" --transport stdio --workspace "$tooling_root" "$@"
