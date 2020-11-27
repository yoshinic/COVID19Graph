// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "COVID19Graph",
    platforms: [
        .macOS(.v10_15)
    ],
    products: [
        .executable(name: "COVID19Graph", targets: ["COVID19Graph"]),
    ],
    dependencies: [
        .package(url: "https://github.com/swift-server/swift-aws-lambda-runtime.git", .upToNextMajor(from:"0.3.0")),
        .package(url: "https://github.com/soto-project/soto.git", from: "5.0.0-rc"),
        .package(url: "https://github.com/swift-server/async-http-client.git", from: "1.0.0"),
        .package(url: "https://github.com/vapor/async-kit.git", from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "COVID19Graph",
            dependencies: [
                .product(name: "AWSLambdaRuntime", package: "swift-aws-lambda-runtime"),
                .product(name: "AWSLambdaEvents", package: "swift-aws-lambda-runtime"),
                .product(name: "AsyncHTTPClient", package: "async-http-client"),
                .product(name: "SotoDynamoDB", package: "soto"),
                .product(name: "AsyncKit", package: "async-kit"),
            ]
        ),
        .testTarget(
            name: "COVID19GraphTests",
            dependencies: ["COVID19Graph"]),
    ]
)
