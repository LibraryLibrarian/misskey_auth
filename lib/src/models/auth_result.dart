/// Misskey認証の結果を表すクラス
class AuthResult {
  /// アクセストークン
  final String accessToken;
  
  /// リフレッシュトークン（OAuth認証の場合）
  final String? refreshToken;
  
  /// トークンの有効期限（秒）
  final int? expiresIn;
  
  /// 認証方式（oauth または miauth）
  final String authType;
  
  /// ユーザー情報
  final Map<String, dynamic>? userInfo;
  
  /// 認証が成功したかどうか
  final bool isSuccess;
  
  /// エラーメッセージ（認証が失敗した場合）
  final String? errorMessage;

  const AuthResult({
    required this.accessToken,
    this.refreshToken,
    this.expiresIn,
    required this.authType,
    this.userInfo,
    this.isSuccess = true,
    this.errorMessage,
  });

  /// 認証失敗時の結果を作成するファクトリメソッド
  factory AuthResult.failure({
    required String errorMessage,
    required String authType,
  }) {
    return AuthResult(
      accessToken: '',
      authType: authType,
      isSuccess: false,
      errorMessage: errorMessage,
    );
  }

  /// OAuth認証成功時の結果を作成するファクトリメソッド
  factory AuthResult.oauthSuccess({
    required String accessToken,
    String? refreshToken,
    int? expiresIn,
    Map<String, dynamic>? userInfo,
  }) {
    return AuthResult(
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresIn: expiresIn,
      authType: 'oauth',
      userInfo: userInfo,
      isSuccess: true,
    );
  }

  /// MiAuth認証成功時の結果を作成するファクトリメソッド
  factory AuthResult.miauthSuccess({
    required String accessToken,
    Map<String, dynamic>? userInfo,
  }) {
    return AuthResult(
      accessToken: accessToken,
      authType: 'miauth',
      userInfo: userInfo,
      isSuccess: true,
    );
  }

  /// OAuth認証開始時の結果を作成するファクトリメソッド
  factory AuthResult.oauthStarted({
    required String authUrl,
    required String codeVerifier,
  }) {
    return AuthResult(
      accessToken: '',
      authType: 'oauth',
      isSuccess: true,
      errorMessage: null,
    );
  }

  @override
  String toString() {
    if (isSuccess) {
      return 'AuthResult(success: true, type: $authType, token: ${accessToken.substring(0, 10)}...)';
    } else {
      return 'AuthResult(success: false, error: $errorMessage)';
    }
  }
}
