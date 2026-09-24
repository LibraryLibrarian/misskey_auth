---
sidebar_position: 7
title: 升级说明
---

# 升级说明

## 运行要求

- Flutter 3.47.1 或更高版本；Dart 3.13.1 或更高版本且低于 Dart 4。
- Android API 24 或更高版本，compileSdk 37 或更高版本。示例应用使用 AGP 9.1.1、Gradle 9.3.1 和 Kotlin Gradle Plugin 2.3.20。AGP 需要 JDK 17 或更高版本。
- iOS 15 或更高版本。请使 Xcode 和 Podfile 的最低部署目标保持一致。示例应用包含 Flutter 的 UIScene 迁移和 Swift Package Manager 集成。请参阅 [Flutter UIScene 迁移指南](https://docs.flutter.dev/release/breaking-changes/uiscenedelegate)。

## Android Gradle 设置

在稳定版 `flutter_web_auth_2` 仍应用 Kotlin Android 插件期间，请保留 `android.builtInKotlin=false` 和 `android.newDsl=false`。保留该插件，但将 `android.kotlinOptions` 替换为 `kotlin.compilerOptions` 来配置其 JVM 目标。未来的 Flutter 版本可能要求依赖项支持内置 Kotlin。

## 升级到 0.2.0-beta.1

### Android 用户必须重新登录

此版本将 `flutter_secure_storage` 从 9.x 升级到 11.x，不经过 10.x 的迁移。在 Android 上，使用旧默认设置加密的凭据无法直接迁移；用户必须为每个受影响的账号重新进行身份验证。

- 这是 Android 存储兼容性方面的破坏性变更，不代表 iOS 上也会发生相同的数据丢失。
- 宿主应用必须处理凭据缺失和存储空间错误。
- 删除本地凭据不会撤销服务器端令牌。

### 共享存储空间 {#shared-storage}

默认的 `SecureTokenStore` 使用共享的默认存储命名空间。`flutter_secure_storage` 11 默认启用 `resetOnError`，因此恢复过程中也可能删除该命名空间中的其他值。升级前请检查共享存储配置。请参阅 [flutter_secure_storage 更新日志](https://pub.dev/packages/flutter_secure_storage/changelog)和[令牌存储](./token-storage.md#shared-storage)。

所有变更请参阅[更新日志](https://pub.dev/packages/misskey_auth/changelog)。
