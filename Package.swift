// swift-tools-version:4.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftyAWSSNS",
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "SwiftyAWSSNS",
            targets: ["SwiftyAWSSNS"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(url: "https://github.com/IBM-Swift/Kitura.git", .upToNextMajor(from: "2.4.0")),
        
        // .package(url: "https://github.com/benspratling4/SwiftAWSSignatureV4.git", from:"1.0.0")
        .package(url: "https://github.com/crspybits/SwiftAWSSignatureV4.git", .branch("master"))
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "SwiftyAWSSNS",
            dependencies: ["Kitura", "SwiftAWSSignatureV4"]),
        .testTarget(
            name: "SwiftyAWSSNSTests",
            dependencies: ["SwiftyAWSSNS"]),
    ]
)
