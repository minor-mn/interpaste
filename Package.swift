// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "interpaste",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(name: "pbdump", path: "Sources/pbdump"),
        .executableTarget(name: "interpaste", path: "Sources/interpaste"),
    ]
)
