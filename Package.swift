// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "KNetworkLayer",
    platforms: [.iOS("12.0")],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "KNetworkLayer",
            targets: ["KNetworkLayer"]),
        .library(
            name: "kPromiseNetworkLayer",
            targets: ["kPromiseNetworkLayer"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/Alamofire/Alamofire", from: "5.4.2"),
        .package(url: "https://github.com/mxcl/PromiseKit", from: "6.0.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "KNetworkLayer",
            dependencies: ["Alamofire"]),
        .target(
            name: "kPromiseNetworkLayer",
            dependencies: ["KNetworkLayer", "PromiseKit"]),
        .testTarget(
            name: "KNetworkLayerTests",
            dependencies: ["KNetworkLayer"]),
    ],
    swiftLanguageVersions: [.v5]
)
