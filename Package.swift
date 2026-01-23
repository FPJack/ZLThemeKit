// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ZLThemeKit",
    
    // 對應 podspec 中的 ios.deployment_target = '10.0'
    platforms: [
        .iOS(.v12),
        // 如果之後要支援 macOS、tvOS 等，可以再加上
        // .macOS(.v10_15),
    ],
    
    products: [
        // 通常會做成 library，名字建議跟 pod 名稱一致
        .library(
            name: "ZLThemeKit",
            targets: ["ZLThemeKit"]
        ),
    ],
    
    dependencies: [
        // 如果原本 podspec 有 s.dependency 'XXX' 在這裡加
        // 你的 podspec 目前沒有外部依賴，所以這邊留空
        // .package(url: "https://github.com/xxx/yyy.git", from: "1.0.0"),
    ],
    
    targets: [
        .target(
            name: "ZLThemeKit",
            dependencies: [],
            path: "ZLThemeKit/Classes",
            
            // 如果有公開的 .h 檔需要被其他專案 import
            // publicHeadersPath: "."
            
            // 資源檔（xcprivacy 通常會自動被辨識為隱私資訊檔）
            resources: [
                .process("../Resources/PrivacyInfo.xcprivacy")
                // 如果之後有圖片、xib、storyboard 等，也可以加在這邊
                // .process("Assets")
            ]
        ),
        
        // 如果有單元測試，可以加上 test target
        // .testTarget(
        //     name: "ZLPopViewTests",
        //     dependencies: ["ZLPopView"],
        //     path: "ZLPopView/Tests"
        // ),
    ]
)
