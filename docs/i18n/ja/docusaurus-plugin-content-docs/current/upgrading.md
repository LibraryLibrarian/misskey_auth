---
sidebar_position: 7
title: 更新時の注意
---

# 更新時の注意

## 動作要件

- Flutter 3.47.1 以上、Dart 3.13.1 以上 4.0 未満。
- Android API 24 以上、compileSdk 37 以上。example は AGP 9.1.1、Gradle 9.3.1、Kotlin Gradle Plugin 2.3.20 を使用します。AGP の実行には JDK 17 以上が必要です。
- iOS 15 以上。Xcode と Podfile の最低対応バージョンを揃えてください。example には Flutter の UIScene 移行と Swift Package Manager 統合を含めています。[Flutter の UIScene 移行ガイド](https://docs.flutter.dev/release/breaking-changes/uiscenedelegate)を参照してください。

## Android の Gradle 設定

安定版の `flutter_web_auth_2` が Kotlin Android プラグインを適用する間は、`android.builtInKotlin=false` と `android.newDsl=false` を維持してください。プラグインの適用は残し、JVM ターゲットの設定を `android.kotlinOptions` から `kotlin.compilerOptions` へ変更します。将来の Flutter では、依存プラグイン側の内蔵 Kotlin 対応が必要になる可能性があります。

## 0.2.0-beta.1 への更新

### Android では再度のサインインが必要

このバージョンでは `flutter_secure_storage` を 9 系から 11 系へ更新し、10 系を経由する移行処理は提供しません。Android で旧既定の暗号方式により保存された認証情報は直接引き継げず、対象アカウントごとに再認証が必要です。

- これは Android の保存データの互換性に関する破壊的変更です。iOS でも同様にデータが失われるという意味ではありません。
- 利用側のアプリで、認証情報の欠落とストレージのエラーを処理してください。
- 端末上の認証情報を削除しても、サーバー側のトークンは失効しません。

### 共有される保存領域

既定の `SecureTokenStore` は、共通の既定保存領域を使用します。`flutter_secure_storage` の 11 系では `resetOnError` が既定で有効になり、復旧時に同じ領域の別用途の値も削除される可能性があります。同じ保存領域を共有する場合は、更新前に設定を確認してください。[flutter_secure_storage の変更履歴](https://pub.dev/packages/flutter_secure_storage/changelog)と[トークンの保存](./token-storage.md#shared-storage)も参照してください。

すべての変更は[変更履歴](https://pub.dev/packages/misskey_auth/changelog)を参照してください。
