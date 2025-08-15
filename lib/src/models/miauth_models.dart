/// MiAuth 認証の設定を表すクラス
class MisskeyMiAuthConfig {
  /// Misskey サーバーのホスト（例: misskey.io）
  final String host;

  /// アプリケーション名（ユーザーに表示）
  final String appName;

  /// カスタム URL スキーム（例: misskeyauth）
  final String callbackScheme;

  /// 要求する権限一覧（例: `read:account`, `write:notes`）
  final List<String> permissions;

  /// アプリアイコンの URL（任意）
  final String? iconUrl;

  const MisskeyMiAuthConfig({
    required this.host,
    required this.appName,
    required this.callbackScheme,
    this.permissions = const <String>[],
    this.iconUrl,
  });

  /// コールバック URL（例: misskeyauth://oauth/callback）
  String get callbackUrl {
    // スキームのみで十分（iOS/Android ともにスキーム一致で復帰可能）
    return '$callbackScheme://';
  }
}

/// MiAuth チェック API のレスポンス
class MiAuthCheckResponse {
  final bool ok;
  final String? token;
  final Map<String, dynamic>? user;

  const MiAuthCheckResponse({
    required this.ok,
    this.token,
    this.user,
  });

  factory MiAuthCheckResponse.fromJson(Map<String, dynamic> json) {
    return MiAuthCheckResponse(
      ok: json['ok'] == true,
      token: json['token'] as String?,
      user: json['user'] as Map<String, dynamic>?,
    );
  }
}

/// MiAuth 成功時の結果（利用側が扱いやすい形）
class MiAuthTokenResponse {
  /// アクセストークン
  final String token;

  /// 付随するユーザー情報（任意）
  final Map<String, dynamic>? user;

  const MiAuthTokenResponse({
    required this.token,
    this.user,
  });
}
