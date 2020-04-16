// swift-tools-version:5.2

import PackageDescription

let package = Package(
    name: "SteampressFluent",
    platforms: [
       .macOS(.v10_15)
    ],
    products: [
        .library(
            name: "SteampressFluent",
            targets: ["SteampressFluent"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
         .package(url: "https://github.com/brokenhandsio/SteamPress.git", from: "2.0.0-beta"),
         .package(url: "https://github.com/vapor/fluent.git", from: "4.0.0-rc")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "SteampressFluent",
            dependencies: [
                "SteamPress",
                .product(name: "Fluent", package: "fluent")
            ]),
        .testTarget(
            name: "SteampressFluentTests",
            dependencies: ["SteampressFluent"]),
    ]
)
