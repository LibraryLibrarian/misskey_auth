# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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