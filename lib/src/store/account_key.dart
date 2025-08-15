/// Misskey のアカウントを一意に識別するキー
///
/// - 複数アカウントのトークンを扱う際の主キーとして使用
/// - `host` と `accountId` の組み合わせで一意に
class AccountKey {
  /// Misskey サーバーのホスト名（例: `misskey.io`）
  final String host;

  /// Misskey 側で付与されるユーザーID（例: `9arsrr3d8x`）
  final String accountId;

  const AccountKey({required this.host, required this.accountId});

  /// ストレージ用の内部キーを生成する
  ///
  /// `SecureTokenStore` の実装で使用する。アプリ側で直接利用する必要はないが、
  /// デバッグ時の識別子として役立つ場合がある
  String storageKey() => 'misskey_token::$host::$accountId';

  /// JSON へ変換
  Map<String, dynamic> toJson() => {
        'host': host,
        'accountId': accountId,
      };

  /// JSON から復元
  factory AccountKey.fromJson(Map<String, dynamic> json) => AccountKey(
        host: json['host'] as String,
        accountId: json['accountId'] as String,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AccountKey &&
          runtimeType == other.runtimeType &&
          host == other.host &&
          accountId == other.accountId;

  @override
  int get hashCode => Object.hash(host, accountId);

  @override
  String toString() => 'AccountKey(host: $host, accountId: $accountId)';
}
