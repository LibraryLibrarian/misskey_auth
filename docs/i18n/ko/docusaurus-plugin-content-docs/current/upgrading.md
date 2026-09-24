---
sidebar_position: 7
title: 업그레이드
---

# 업그레이드

## 요구 사항

- Flutter 3.47.1 이상, Dart 3.13.1 이상 4.0 미만
- Android API 24 이상, compileSdk 37 이상. 예제는 AGP 9.1.1, Gradle 9.3.1, Kotlin Gradle Plugin 2.3.20을 사용합니다. AGP를 실행하려면 JDK 17 이상이 필요합니다.
- iOS 15 이상. Xcode와 Podfile의 배포 대상 버전을 일치시키세요. 예제에는 Flutter의 UIScene 마이그레이션과 Swift Package Manager 통합이 포함되어 있습니다. [Flutter UIScene 마이그레이션 가이드](https://docs.flutter.dev/release/breaking-changes/uiscenedelegate)를 참조하세요.

## Android Gradle 설정

안정 버전 `flutter_web_auth_2`가 Kotlin Android 플러그인을 적용하는 동안에는 `android.builtInKotlin=false`와 `android.newDsl=false`를 유지하세요. 플러그인 적용은 유지하되 JVM 대상을 설정하는 코드를 `android.kotlinOptions`에서 `kotlin.compilerOptions`로 변경합니다. 향후 Flutter 버전에서는 종속성의 내장 Kotlin 지원이 필요할 수 있습니다.

## 0.2.0-beta.1로 업그레이드

### Android에서는 다시 로그인해야 합니다

이 버전은 `flutter_secure_storage`를 9.x에서 11.x로 업그레이드하며 10.x를 거치는 마이그레이션 단계는 제공하지 않습니다. Android에서는 이전 기본 암호화 방식으로 저장한 인증 정보를 직접 이전할 수 없으므로 해당 계정마다 다시 인증해야 합니다.

- Android 저장 데이터 호환성에 관한 하위 호환성이 깨지는 변경입니다. iOS에서도 같은 데이터 손실이 발생한다는 뜻은 아닙니다.
- 호스트 앱은 인증 정보 누락과 저장소 오류를 처리해야 합니다.
- 기기의 인증 정보를 삭제해도 서버 측 토큰은 폐기되지 않습니다.

### 공유 저장 영역

기본 `SecureTokenStore`는 공용 기본 저장 영역을 사용합니다. `flutter_secure_storage` 11에서는 `resetOnError`가 기본으로 활성화되어 있어 복구 과정에서 해당 영역의 다른 값도 삭제될 수 있습니다. 공유 저장 영역을 사용한다면 업그레이드 전에 설정을 확인하세요. [flutter_secure_storage 변경 기록](https://pub.dev/packages/flutter_secure_storage/changelog)과 [토큰 저장](./token-storage.md#shared-storage)도 참조하세요.

모든 변경 사항은 [변경 기록](https://pub.dev/packages/misskey_auth/changelog)을 참조하세요.
