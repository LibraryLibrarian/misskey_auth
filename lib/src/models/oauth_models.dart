import 'json_fields.dart';

/// OAuth認証サーバーの情報を表すクラス
class OAuthServerInfo {
  /// OAuth認証エンドポイント
  final String authorizationEndpoint;

  /// トークンエンドポイント
  final String tokenEndpoint;

  /// イントロスペクションエンドポイント（オプション）
  final String? introspectionEndpoint;

  /// リボケーションエンドポイント（オプション）
  final String? revocationEndpoint;

  /// スコープがサポートされているか
  final List<String>? scopesSupported;

  /// レスポンスタイプがサポートされているか
  final List<String>? responseTypesSupported;

  /// コードチャレンジメソッドがサポートされているか
  final List<String>? codeChallengeMethodsSupported;

  const OAuthServerInfo({
    required this.authorizationEndpoint,
    required this.tokenEndpoint,
    this.introspectionEndpoint,
    this.revocationEndpoint,
    this.scopesSupported,
    this.responseTypesSupported,
    this.codeChallengeMethodsSupported,
  });

  /// 欠落・型違いのフィールドがあれば [FormatException]
  factory OAuthServerInfo.fromJson(Map<String, dynamic> json) {
    return OAuthServerInfo(
      authorizationEndpoint: requireField<String>(
        json,
        'authorization_endpoint',
      ),
      tokenEndpoint: requireField<String>(json, 'token_endpoint'),
      introspectionEndpoint: optionalField<String>(
        json,
        'introspection_endpoint',
      ),
      revocationEndpoint: optionalField<String>(json, 'revocation_endpoint'),
      scopesSupported: optionalStringList(json, 'scopes_supported'),
      responseTypesSupported: optionalStringList(
        json,
        'response_types_supported',
      ),
      codeChallengeMethodsSupported: optionalStringList(
        json,
        'code_challenge_methods_supported',
      ),
    );
  }
}

/// OAuthトークンレスポンスを表すクラス
class OAuthTokenResponse {
  /// アクセストークン
  final String accessToken;

  /// トークンタイプ（通常は"Bearer"）
  final String tokenType;

  /// トークンの有効期限（秒）
  final int? expiresIn;

  /// スコープ
  final String? scope;

  /// IDトークン（OpenID Connectの場合）
  final String? idToken;

  const OAuthTokenResponse({
    required this.accessToken,
    required this.tokenType,
    this.expiresIn,
    this.scope,
    this.idToken,
  });

  /// 欠落・型違いのフィールドがあれば [FormatException]
  factory OAuthTokenResponse.fromJson(Map<String, dynamic> json) {
    return OAuthTokenResponse(
      accessToken: requireField<String>(json, 'access_token'),
      tokenType: requireField<String>(json, 'token_type'),
      expiresIn: optionalField<int>(json, 'expires_in'),
      scope: optionalField<String>(json, 'scope'),
      idToken: optionalField<String>(json, 'id_token'),
    );
  }
}

/// OAuth認証の設定
class MisskeyOAuthConfig {
  /// Misskeyサーバーのホスト
  final String host;

  /// クライアントID（アプリ紹介ページのURL）
  final String clientId;

  /// リダイレクトURI
  final String redirectUri;

  /// 要求するスコープ
  final String scope;

  /// カスタムスキーム
  final String callbackScheme;

  const MisskeyOAuthConfig({
    required this.host,
    required this.clientId,
    required this.redirectUri,
    required this.scope,
    required this.callbackScheme,
  });
}
