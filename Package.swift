// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "BazelHelloWorldDependencies",
    platforms: [.iOS(.v17)],
    dependencies: [
        .package(url: "https://github.com/kean/Nuke.git", exact: "13.2.0"),
        .package(
            url: "https://github.com/Aeastr/SwiftMacros.git",
            revision: "a603ec87d17cf6dd7d9d0c1a4289784ca6cae63e"
        ),
    ]
)
