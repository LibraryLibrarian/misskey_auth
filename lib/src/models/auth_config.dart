import '../exceptions/misskey_auth_exception.dart';

/// Misskey認証の設定を表すクラス
class AuthConfig {
  /// Misskeyサーバーのホスト（例: misskey.io）
  final String host;
  
  /// アプリケーションのクライアントID
  final String clientId;
  
  /// アプリケーションのクライアントシークレット
  final String clientSecret;
  
  /// 認証完了後のリダイレクトURI
  final String redirectUri;
  
  /// 要求するスコープ（カンマ区切り）
  final String scopes;
  
  /// アプリケーション名
  final String appName;
  
  /// アプリケーションの説明
  final String? appDescription;
  
  /// アプリケーションのアイコンURL
  final String? appIconUrl;
  
  /// アプリケーションの権限
  final List<String>? permissions;

  const AuthConfig({
    required this.host,
    required this.clientId,
    required this.clientSecret,
    required this.redirectUri,
    this.scopes = 'read:account,write:notes',
    required this.appName,
    this.appDescription,
    this.appIconUrl,
    this.permissions,
  });

  /// 設定が有効かどうかを検証する
  bool get isValid {
    return host.isNotEmpty &&
        clientId.isNotEmpty &&
        clientSecret.isNotEmpty &&
        redirectUri.isNotEmpty &&
        appName.isNotEmpty;
  }

  /// 設定の検証を行い、無効な場合は例外を投げる
  void validate() {
    if (!isValid) {
      throw const InvalidAuthConfigException(
        '認証設定が無効です。host、clientId、clientSecret、redirectUri、appNameは必須です。',
      );
    }
  }

  /// サーバーのベースURLを取得
  String get serverUrl {
    return 'https://$host';
  }

  /// OAuth認証エンドポイントのURLを取得
  String get oauthWellKnownUrl {
    return '$serverUrl/.well-known/oauth-authorization-server';
  }

  /// MiAuth認証エンドポイントのURLを取得
  String get miauthUrl {
    return '$serverUrl/miauth';
  }
}
