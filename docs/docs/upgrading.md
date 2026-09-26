---
sidebar_position: 7
title: Upgrading
---

# Upgrading

## Requirements

- Flutter 3.47.1 or later; Dart 3.13.1 or later, before Dart 4.
- Android API 24 or later and compileSdk 37 or later. The example uses AGP 9.1.1, Gradle 9.3.1, and Kotlin Gradle Plugin 2.3.20. AGP requires JDK 17 or later.
- iOS 15 or later. Align the Xcode and Podfile deployment targets. The example includes Flutter's UIScene migration and Swift Package Manager integration. See the [Flutter UIScene migration guide](https://docs.flutter.dev/release/breaking-changes/uiscenedelegate).

## Android Gradle Settings

Keep `android.builtInKotlin=false` and `android.newDsl=false` while the stable `flutter_web_auth_2` release still applies the Kotlin Android plugin. Retain that plugin, but replace `android.kotlinOptions` with `kotlin.compilerOptions` to configure its JVM target. Future Flutter versions may require built-in Kotlin support from dependencies.

## Upgrading to 0.2.0-beta.1

### Android Users Must Sign In Again

This version upgrades `flutter_secure_storage` from 9.x to 11.x without a 10.x migration step. On Android, credentials encrypted with the old defaults cannot be carried over directly; users must authenticate again for each affected account.

- This is a breaking change in Android storage compatibility. It does not imply the same data loss on iOS.
- Host apps must handle missing credentials and storage errors.
- Deleting local credentials does not revoke server-side tokens.

### Shared Storage

The default `SecureTokenStore` uses the shared default storage namespace. Version 11 of `flutter_secure_storage` enables `resetOnError` by default, so recovery can also delete other values in that namespace. Review shared-storage configurations before upgrading. See the [flutter_secure_storage changelog](https://pub.dev/packages/flutter_secure_storage/changelog) and [Token Storage](./token-storage.md#shared-storage).

For all changes, see the [changelog](https://pub.dev/packages/misskey_auth/changelog).
