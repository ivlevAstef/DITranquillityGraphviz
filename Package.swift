// swift-tools-version:5.0
import PackageDescription

let package = Package(
    name: "DITranquillityGraphviz",
    products: [
        .library(name: "DITranquillityGraphviz", targets: ["DITranquillityGraphviz"])
    ],
    dependencies: [
        .package(url: "https://github.com/ivlevAstef/DITranquillity.git", from: "4.1.0")
    ],
    targets: [
        .target(name: "DITranquillityGraphviz", dependencies: [
            "DITranquillity"
        ], path: "./Sources")
    ]
)
