/// Misskeyサーバーの情報を表すクラス
class MisskeyServerInfo {
  /// サーバーのホスト
  final String host;
  
  /// OAuth 2.0がサポートされているかどうか
  final bool supportsOAuth;
  
  /// OAuth認証エンドポイント
  final String? authorizationEndpoint;
  
  /// OAuthトークンエンドポイント
  final String? tokenEndpoint;
  
  /// サーバーのバージョン情報
  final String? version;
  
  /// サーバーの名前
  final String? name;
  
  /// サーバーの説明
  final String? description;

  const MisskeyServerInfo({
    required this.host,
    required this.supportsOAuth,
    this.authorizationEndpoint,
    this.tokenEndpoint,
    this.version,
    this.name,
    this.description,
  });

  /// OAuth認証が利用可能かどうかを判定
  bool get canUseOAuth {
    return supportsOAuth &&
        authorizationEndpoint != null &&
        tokenEndpoint != null;
  }

  /// サーバー情報をJSONから作成するファクトリメソッド
  factory MisskeyServerInfo.fromJson(String host, Map<String, dynamic> json) {
    final hasOAuthEndpoints = json.containsKey('authorization_endpoint') &&
        json.containsKey('token_endpoint');

    return MisskeyServerInfo(
      host: host,
      supportsOAuth: hasOAuthEndpoints,
      authorizationEndpoint: json['authorization_endpoint'] as String?,
      tokenEndpoint: json['token_endpoint'] as String?,
      version: json['version'] as String?,
      name: json['name'] as String?,
      description: json['description'] as String?,
    );
  }

  /// デフォルトのサーバー情報を作成するファクトリメソッド
  factory MisskeyServerInfo.defaultInfo(String host) {
    return MisskeyServerInfo(
      host: host,
      supportsOAuth: false,
    );
  }

  @override
  String toString() {
    return 'MisskeyServerInfo(host: $host, oauth: $supportsOAuth)';
  }
}
