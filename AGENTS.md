# Project instructions

- Keep all new project files, downloaded project tools, scratch files, and any delegated worktrees **inside this repository** (`Documents/Bazel_iOS`). Never create sibling worktree folders elsewhere in Documents. If parallel worktrees are needed, use `.worktrees/<task>` inside this project and clean them up after integration. Normal tool-managed caches may remain in their standard locations.
- Use Bazel/Bzlmod as the source of truth. Keep version pins and lockfiles committed; do not add legacy WORKSPACE dependency setup or hand-maintain the generated Xcode project.
- The app is `//App:HelloWorld`, its widget is `//Widget:HelloWorldWidget`, and Xcode generation is `bazel run //:xcodeproj`.
- App verification means building, installing, and successfully launching the app in an iOS simulator: run `./scripts/run-simulator.sh`. Do not stop at compilation alone. Use computer use only when scripts are complicated or for verification.
- Use `./tools/setup-tooling.sh` after cloning or moving the folder. SourceKit-LSP must receive Bazel settings through Spotify BSP. For code intelligence use the configured Swift MCP or VS Code Swift extension. MCP line/character positions are zero-based.
- Preserve the widget extension and the real NukeUI package dependency when changing the sample.
- Keep generated `.xcodeproj`, `.bsp`, `.sourcekit-lsp`, machine-local VS Code settings, `.tools`, `.artifacts`, and `.worktrees` out of Git.
- Document machine changes, setup commands, limitations, and verification results in READMe.md. Do not silently alter Xcode selection, global editor settings, or signing accounts.
- Use subagents only when requested; keep their scopes separate and integrate their committed work. User instructions take precedence over generic delegation skills.
