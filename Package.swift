// swift-tools-version: 5.10
import PackageDescription

let package = Package(
  name: "Unmissable",
  platforms: [
    .macOS(.v14)
  ],
  products: [
    .executable(
      name: "Unmissable",
      targets: ["Unmissable"]
    )
  ],
  dependencies: [
    // OAuth 2.0 for Google Calendar
    .package(url: "https://github.com/openid/AppAuth-iOS.git", from: "1.7.5"),
    // SQLite database
    .package(url: "https://github.com/groue/GRDB.swift.git", from: "6.29.2"),
    // Keychain access
    .package(url: "https://github.com/kishikawakatsumi/KeychainAccess.git", from: "4.2.2"),
    // Global keyboard shortcuts
    .package(url: "https://github.com/Clipy/Magnet.git", from: "3.4.0"),
    // Snapshot testing
    .package(url: "https://github.com/pointfreeco/swift-snapshot-testing.git", from: "1.17.7"),
    // Code formatting
    .package(url: "https://github.com/nicklockwood/SwiftFormat.git", from: "0.55.3"),
    // Linting
    .package(url: "https://github.com/realm/SwiftLint.git", from: "0.57.1"),
  ],
  targets: [
    .executableTarget(
      name: "Unmissable",
      dependencies: [
        .product(name: "AppAuth", package: "AppAuth-iOS"),
        .product(name: "GRDB", package: "GRDB.swift"),
        .product(name: "KeychainAccess", package: "KeychainAccess"),
        .product(name: "Magnet", package: "Magnet"),
      ],
      path: "Sources/Unmissable",
      exclude: [
        "Config/Config.plist.example"
      ],
      resources: [
        .process("Resources")
      ]
    ),
    .testTarget(
      name: "UnmissableTests",
      dependencies: [
        "Unmissable",
        .product(name: "SnapshotTesting", package: "swift-snapshot-testing"),
      ],
      path: "Tests/UnmissableTests"
    ),
  ]
)
