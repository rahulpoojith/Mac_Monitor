// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MacTempChecker",
    platforms: [.macOS(.v13)],
    products: [.executable(name: "MacTempChecker", targets: ["MacTempChecker"])],
    targets: [.executableTarget(name: "MacTempChecker")]
)
