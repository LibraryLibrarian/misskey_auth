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
