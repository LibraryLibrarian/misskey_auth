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

  factory OAuthServerInfo.fromJson(Map<String, dynamic> json) {
    return OAuthServerInfo(
      authorizationEndpoint: json['authorization_endpoint'] as String,
      tokenEndpoint: json['token_endpoint'] as String,
      introspectionEndpoint: json['introspection_endpoint'] as String?,
      revocationEndpoint: json['revocation_endpoint'] as String?,
      scopesSupported: (json['scopes_supported'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      responseTypesSupported:
          (json['response_types_supported'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList(),
      codeChallengeMethodsSupported:
          (json['code_challenge_methods_supported'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList(),
    );
  }
}

/// OAuthトークンレスポンスを表すクラス
class OAuthTokenResponse {
  /// アクセストークン
  final String accessToken;

  /// トークンタイプ（通常は"Bearer"）
  final String tokenType;

  /// リフレッシュトークン（オプション）
  final String? refreshToken;

  /// トークンの有効期限（秒）
  final int? expiresIn;

  /// スコープ
  final String? scope;

  /// IDトークン（OpenID Connectの場合）
  final String? idToken;

  const OAuthTokenResponse({
    required this.accessToken,
    required this.tokenType,
    this.refreshToken,
    this.expiresIn,
    this.scope,
    this.idToken,
  });

  factory OAuthTokenResponse.fromJson(Map<String, dynamic> json) {
    return OAuthTokenResponse(
      accessToken: json['access_token'] as String,
      tokenType: json['token_type'] as String,
      refreshToken: json['refresh_token'] as String?,
      expiresIn: json['expires_in'] as int?,
      scope: json['scope'] as String?,
      idToken: json['id_token'] as String?,
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
