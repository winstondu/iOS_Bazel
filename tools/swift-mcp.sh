#!/bin/bash
set -euo pipefail
tooling_root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$tooling_root"
export DEVELOPER_DIR="${DEVELOPER_DIR:-$(xcode-select -p)}"
export SOURCEKIT_LSP_PATH="$tooling_root/tools/sourcekit-lsp.sh"
exec "$tooling_root/.tools/swift-mcp-server/.build/release/swift-mcp-server" --transport stdio --workspace "$tooling_root" "$@"
