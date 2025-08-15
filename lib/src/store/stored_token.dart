import 'account_key.dart';

/// 保存済みのトークン情報を表すモデル
///
/// - `tokenType` は `MiAuth` または `OAuth`
class StoredToken {
  /// アクセストークン本体（Bearer）
  final String accessToken;

  /// トークンの種類（`MiAuth` / `OAuth`）
  final String tokenType; // 'MiAuth' | 'OAuth'
  /// 要求スコープ（OAuth のみ）
  final String? scope;

  /// `/api/i` 等で取得したユーザー情報（任意）
  final Map<String, dynamic>? user;

  /// ライブラリが保存した日時（デバッグ/表示用途）
  final DateTime? createdAt;

  const StoredToken({
    required this.accessToken,
    required this.tokenType,
    this.scope,
    this.user,
    this.createdAt,
  });

  /// JSON へ変換
  Map<String, dynamic> toJson() => {
        'accessToken': accessToken,
        'tokenType': tokenType,
        if (scope != null) 'scope': scope,
        if (user != null) 'user': user,
        if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      };

  /// JSON から復元
  factory StoredToken.fromJson(Map<String, dynamic> json) => StoredToken(
        accessToken: json['accessToken'] as String,
        tokenType: json['tokenType'] as String,
        scope: json['scope'] as String?,
        user: json['user'] as Map<String, dynamic>?,
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'] as String)
            : null,
      );
}

/// アカウント一覧に表示するメタ情報
///
/// - `key` が対象アカウントを表す
/// - `userName` は取得できた場合にのみ表示用に保持
/// - `createdAt` は保存日時の目安
class AccountEntry {
  final AccountKey key;
  final String? userName;
  final DateTime? createdAt;

  const AccountEntry(this.key, {this.userName, this.createdAt});
}
