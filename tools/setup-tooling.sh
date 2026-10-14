#!/bin/bash
# Run from any directory. All downloaded dependencies stay in this checkout.
set -euo pipefail
tooling_root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$tooling_root"
mcp_revision=b5b99b3ea8b28e8b46545a2f3ace2a0114ed5514
mkdir -p .tools .vscode
# Bazel owns the release URL and checksum in MODULE.bazel. Reuse its download
# for both the BSP and LSP instead of maintaining a second version pin here.
bazelisk run //tools:setup_sourcekit_bsp
lsp_file="$(bazelisk cquery @sourcekit_bsp_prebuilt//:sourcekit-lsp --output=files)"
execution_root="$(bazelisk info execution_root)"
install -m 755 "$execution_root/$lsp_file" .tools/sourcekit-lsp.new
mv -f .tools/sourcekit-lsp.new .tools/sourcekit-lsp
# Write editor settings before the MCP bridge build so a failure there cannot leave
# VS Code on its default toolchain LSP. The template uses ${workspaceFolder}, so the
# settings never contain this checkout's absolute path.
python3 - "$tooling_root" <<'PY'
import json, pathlib, sys
root = pathlib.Path(sys.argv[1])
path = root / '.vscode/settings.json'
settings = json.loads(path.read_text()) if path.exists() else {}
settings.update(json.loads((root / 'tools/vscode-settings.json').read_text()))
path.write_text(json.dumps(settings, indent=2) + '\n')
PY
if [[ ! -d .tools/swift-mcp-server/.git ]]; then
    git clone https://github.com/anvyxhq/swift-mcp-server.git .tools/swift-mcp-server
fi
git -C .tools/swift-mcp-server checkout --detach "$mcp_revision"
if git -C .tools/swift-mcp-server apply --check "$tooling_root/tools/swift-mcp-diagnostics.patch" 2>/dev/null; then
    git -C .tools/swift-mcp-server apply "$tooling_root/tools/swift-mcp-diagnostics.patch"
elif ! git -C .tools/swift-mcp-server apply --reverse --check "$tooling_root/tools/swift-mcp-diagnostics.patch" 2>/dev/null; then
    echo 'Swift MCP source differs from the pinned diagnostics patch.' >&2
    exit 1
fi
mcp_build() { xcrun swift build --package-path .tools/swift-mcp-server --configuration release; }
# SwiftPM can fail on an existing build database ("accessing build database ...
# disk I/O error"). A build from a clean scratch directory does not.
if ! mcp_build; then
    echo 'Retrying the Swift MCP bridge build from a clean .build directory.' >&2
    rm -rf .tools/swift-mcp-server/.build
    mcp_build
fi
echo 'Tooling ready. Restart the Swift LSP server in VS Code and restart Codex MCP servers.'
