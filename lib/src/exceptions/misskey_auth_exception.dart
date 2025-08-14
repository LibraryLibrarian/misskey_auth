/// Misskey認証処理中に発生する例外を表すクラス
class MisskeyAuthException implements Exception {
  /// エラーメッセージ
  final String message;

  /// エラーの詳細情報
  final String? details;

  /// 元の例外
  final Exception? originalException;

  const MisskeyAuthException(
    this.message, {
    this.details,
    this.originalException,
  });

  @override
  String toString() {
    if (details != null) {
      return 'MisskeyAuthException: $message - $details';
    }
    return 'MisskeyAuthException: $message';
  }
}

/// OAuth認証がサポートされていないサーバーでの例外
class OAuthNotSupportedException extends MisskeyAuthException {
  const OAuthNotSupportedException(String host)
      : super('OAuth認証がサポートされていません: $host');
}

/// 認証設定が無効な場合の例外
class InvalidAuthConfigException extends MisskeyAuthException {
  const InvalidAuthConfigException(super.message);
}

/// トークン交換に失敗した場合の例外
class TokenExchangeException extends MisskeyAuthException {
  const TokenExchangeException(super.message);
}

/// サーバー情報の取得に失敗した場合の例外
class ServerInfoException extends MisskeyAuthException {
  const ServerInfoException(super.message);
}

/// コールバックURLスキーム（カスタムスキーム）が未設定または不一致の場合の例外
class CallbackSchemeErrorException extends MisskeyAuthException {
  const CallbackSchemeErrorException(
      {String? details, Exception? originalException})
      : super('The callback URL scheme is not set or does not match.',
            details: details, originalException: originalException);
}

/// 認証UI（ブラウザ等）の起動に失敗した場合の例外
class AuthorizationLaunchException extends MisskeyAuthException {
  const AuthorizationLaunchException(
      {String? details, Exception? originalException})
      : super('Failed to display the authentication screen.',
            details: details, originalException: originalException);
}

/// ユーザーが認証をキャンセルした場合の例外
class UserCancelledException extends MisskeyAuthException {
  const UserCancelledException({String? details, Exception? originalException})
      : super('The user canceled the authentication.',
            details: details, originalException: originalException);
}

/// ネットワーク層での例外（タイムアウト/オフライン/SSL等）
class NetworkException extends MisskeyAuthException {
  const NetworkException({String? details, Exception? originalException})
      : super('A network error has occurred.',
            details: details, originalException: originalException);
}

/// サーバーレスポンスのパースに失敗した場合の例外
class ResponseParseException extends MisskeyAuthException {
  const ResponseParseException({String? details, Exception? originalException})
      : super('Failed to parse the server response.',
            details: details, originalException: originalException);
}

/// セキュアストレージの操作に失敗した場合の例外
class SecureStorageException extends MisskeyAuthException {
  const SecureStorageException({String? details, Exception? originalException})
      : super('Failed to operate the secure storage.',
            details: details, originalException: originalException);
}

/// OAuthのstate検証に失敗した場合の例外
class StateMismatchException extends MisskeyAuthException {
  const StateMismatchException({String? details, Exception? originalException})
      : super('The state does not match.',
            details: details, originalException: originalException);
}

/// OAuthの認可コードが取得できなかった場合の例外
class AuthorizationCodeMissingException extends MisskeyAuthException {
  const AuthorizationCodeMissingException(
      {String? details, Exception? originalException})
      : super('Failed to get the authorization code.',
            details: details, originalException: originalException);
}

/// 認可サーバーがエラーを返した場合（error, error_description など）
class AuthorizationServerErrorException extends MisskeyAuthException {
  const AuthorizationServerErrorException(
      {String? details, Exception? originalException})
      : super('The authorization server returned an error.',
            details: details, originalException: originalException);
}

/// MiAuth がユーザーによって拒否/キャンセルされた場合の例外
class MiAuthDeniedException extends MisskeyAuthException {
  const MiAuthDeniedException({String? details, Exception? originalException})
      : super('MiAuth authentication was canceled/rejected.',
            details: details, originalException: originalException);
}

/// MiAuth のチェックAPIが失敗（非200）した場合の例外
class MiAuthCheckFailedException extends MisskeyAuthException {
  const MiAuthCheckFailedException(
      {String? details, Exception? originalException})
      : super('MiAuth check failed.',
            details: details, originalException: originalException);
}

/// MiAuth のセッションが見つからない/期限切れなどで無効な場合の例外
class MiAuthSessionInvalidException extends MisskeyAuthException {
  const MiAuthSessionInvalidException(
      {String? details, Exception? originalException})
      : super('MiAuth session is invalid or expired.',
            details: details, originalException: originalException);
}

/// サーバーが MiAuth に対応していない可能性がある場合の例外（必要に応じて使用）
class MiAuthNotSupportedException extends MisskeyAuthException {
  const MiAuthNotSupportedException(
      {String? details, Exception? originalException})
      : super('This server may not support MiAuth.',
            details: details, originalException: originalException);
}
