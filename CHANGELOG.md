# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed
- Raised the minimum supported versions to Flutter 3.47.1, Dart 3.13.1, and iOS 15; Android requires API 24 or later and compileSdk 37 or later.
- Updated stable dependencies, including `flutter_secure_storage` 11.0.0, `dio` 5.11.1, `flutter_lints` 6.0.0, and the example's `loader_overlay` 5.0.0.
- Updated Android builds to AGP 9.1.1, Gradle 9.3.1, and Kotlin 2.3.20 while retaining legacy Kotlin plugin support.
- Migrated the iOS example to UIScene and integrated Swift Package Manager.
- Android credentials stored with the old secure-storage defaults may require reauthentication. No 10.x migration is provided; automatic recovery can reset the shared default storage namespace.
- Upgraded `flutter_web_auth_2` to 5.1.0 and aligned the Android callback Activity configuration with its updated authentication flow

### Fixed
- Android authentication now closes the browser and returns the example app to the foreground after MiAuth or OAuth authorization
- Android release builds of the example app now declare the `INTERNET` permission required for authentication requests
- Corrected the Android callback Activity class name and consolidated the English and Japanese setup guidance around the canonical example Manifest

### Removed
- Unused private `MisskeyServerInfo` model (`lib/src/models/misskey_server_info.dart`)

## [0.1.4-beta] - 2025-08-18

### Added
- Network stability improvements:
  - Introduced `RetryPolicy` and `retry()` utility (`lib/src/net/retry.dart`)
  - Applied retry to OAuth server info fetch, token exchange, MiAuth check API, and `/api/i` user fetch
- Default networking timeouts (overridable): connect 10s / send 20s / receive 20s
  - `MisskeyOAuthClient`, `MisskeyMiAuthClient`, and `MisskeyAuthManager` now accept timeout overrides
- Documentation:
  - Added API doc comments for `AccountKey`, `StoredToken`, `AccountEntry`, `TokenStore`, `SecureTokenStore`, and `MisskeyAuthManager`

### Changed
- `/api/i` request now follows common Misskey style: send token in JSON body with `{"i": "<token>"}` (instead of Authorization header)
- `Dio` now receives Map bodies directly (Dio handles JSON encoding internally)

### Removed
- Unused/duplicated config model: `lib/src/models/auth_config.dart`
- Accidental `lib/main.dart` (prevented dartdoc pollution; example retains its own main)

## [0.1.3-beta] - 2025-08-15

### Added
- Multi-account token management via `TokenStore` abstraction
- Default secure implementation: `SecureTokenStore` (backed by `flutter_secure_storage`)
- High-level API `MisskeyAuthManager` to orchestrate OAuth/MiAuth authentication and token persistence
- Models and types for account/token management: `StoredToken`, `AccountKey`, `AccountEntry`
- Public exports for store/manager types from `misskey_auth.dart`

### Changed
- `MisskeyOAuthClient` and `MisskeyMiAuthClient` no longer persist tokens; they only perform the authentication flow and return results
- Constructors now focus on networking concerns (`Dio` and timeouts)

### Removed
- Storage-related APIs from clients:
  - `MisskeyOAuthClient.getStoredAccessToken()`
  - `MisskeyOAuthClient.clearTokens()`
  - `MisskeyMiAuthClient.getStoredAccessToken()`
  - `MisskeyMiAuthClient.clearTokens()`
- `MisskeyMiAuthClient` constructor parameter for storage injection

### Breaking Changes
- Removed storage APIs from both `MisskeyOAuthClient` and `MisskeyMiAuthClient` (use `MisskeyAuthManager` and `TokenStore` instead)
- `MisskeyMiAuthClient` constructor signature changed (storage parameter removed)
- Token lifecycle (save/read/delete) responsibilities moved from clients to `TokenStore`/`MisskeyAuthManager`

## [0.1.2-beta] - 2025-08-15

### Added
- **MiAuth authentication support** - Alternative authentication method for Misskey servers
- **Comprehensive error handling system** - Granular exception classes for different error scenarios

### Changed
- **Error handling architecture** - Replaced generic exceptions with specific `MisskeyAuthException` subclasses
- **OAuth client improvements** - Enhanced error mapping and better exception handling
- **MiAuth client implementation** - Complete MiAuth authentication flow with proper error handling

### Features
- `MisskeyMiAuthClient` - Main MiAuth authentication client
- `MisskeyMiAuthConfig` - Configuration class for MiAuth authentication
- `MiAuthTokenResponse` - Response model for MiAuth authentication
- Enhanced exception classes including:
  - `OAuthNotSupportedException` - Server doesn't support OAuth 2.0
  - `MiAuthDeniedException` - User denied MiAuth permission
  - `NetworkException` - Network connectivity issues
  - `UserCancelledException` - User cancelled authentication
  - `CallbackSchemeErrorException` - URL scheme configuration errors
  - And 15+ more specific exception classes

## [0.1.1-beta] - 2025-08-12

### Changed
- Platform support is now limited to iOS and Android only.

## [0.1.0-beta] - 2025-08-12

### Added
- Initial beta release
- OAuth 2.0 authentication for Misskey servers (v2023.9.0+)
- External browser authentication (no embedded WebViews)
- Secure token storage using flutter_secure_storage
- PKCE (Proof Key for Code Exchange) implementation
- Custom URL scheme handling for authentication callbacks
- Cross-platform support (iOS/Android)

### Features
- `MisskeyOAuthClient` - Main authentication client
- `MisskeyOAuthConfig` - Configuration class for authentication
- Comprehensive error handling with custom exceptions
- Support for custom callback schemes
