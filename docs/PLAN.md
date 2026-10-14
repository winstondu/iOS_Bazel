# Implementation plan

1. Inspect Xcode, Swift, simulator runtimes, package manager, and repository state.
2. Check current upstream versions and compatibility before choosing pinned Bazel/Bzlmod dependencies. Use `MODULE.bazel`, not legacy WORKSPACE dependency macros.
3. Implement the app and widget separately from build configuration and editor tooling, using isolated Git worktrees.
4. Build a SwiftUI Hello World app that actually imports and uses NukeUI, embedding a WidgetKit extension. Target iOS 17 or later; simulator builds must not require a developer account.
5. Generate an openable Xcode project using rules_xcodeproj, with Bazel remaining the source of truth.
6. Configure Spotify sourcekit-bazel-bsp and the official Swift VS Code extension. Connect Codex to SourceKit through an MCP bridge, and verify semantic responses rather than only successful server startup.
7. Integrate committed work, build app and extension, generate and inspect the Xcode project, install and launch in a simulator, and inspect a screenshot.
8. Write READMe.md with exact commands, version rationale, verified results, limitations, and machine changes. Keep generated/local artifacts ignored and clean up temporary worktrees.

## Initial environment

- Empty repository, initialized on `main`.
- Apple Silicon Mac; selected Xcode 27.0 beta (27A5228h), Swift 6.4.
- Xcode developer directory: `/Applications/Xcode-beta.app/Contents/Developer`.
- iOS 26.5 and 27.0 simulator runtimes available; iPhone 17e on iOS 27 booted.
- Homebrew and VS Code CLI available; Bazel/Bazelisk initially absent.

## General machine changes

- Installed Homebrew `bazelisk` 1.29.0, exposing `bazelisk` and `bazel` commands.
- Homebrew automatically refreshed its taps and cleaned old cached downloads/logs as part of that installation. Existing formulae were not upgraded.
- Xcode selection and signing accounts are not modified.
- Additional tooling installation and final verification are recorded in READMe.md.

## Final integration

Completed the app, widget, Bazel/Xcode generation, BSP, VS Code, and Codex MCP setup. All work is consolidated into `Documents/Bazel_iOS`; the three temporary sibling worktrees and branches were removed. `AGENTS.md` requires future worktrees under this repository’s `.worktrees/`. Installed the official Build iOS Apps Codex plugin. App installation and simulator launch passed; SourceKit hover/definitions/diagnostics and VS Code F12 into NukeUI passed. See READMe.md for versions, commands, and machine changes.
