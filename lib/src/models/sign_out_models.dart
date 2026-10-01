import '../store/account_key.dart';
import 'token_revocation_models.dart';

/// サインアウト時に、サーバー上のトークンをどう扱うか
enum SignOutMode {
  /// 失効させず、端末上のトークンだけを削除する
  localOnly,

  /// 失効を試み、結果にかかわらず端末上のトークンを削除する
  revokeAndDelete,

  /// 失効を試み、失効を確認できた場合だけ端末上のトークンを削除する
  ///
  /// [TokenRevocationStatus.unsupported] と [TokenRevocationStatus.failed] では
  /// 削除しない。失効に対応していないサーバーのアカウントは、
  /// [SignOutMode.localOnly] で削除する
  revokeOrKeep,
}

/// 失効を試みなかった理由
enum RevocationSkipReason {
  /// [SignOutMode.localOnly] が指定された
  localOnly,

  /// 端末にトークンが保存されていなかった
  noStoredToken,

  /// 保存されたトークンを読み出せなかった（破損など）
  unreadableToken,
}

/// 1アカウント分のサインアウトの結果
class SignOutResult {
  /// 対象のアカウント
  final AccountKey key;

  /// 失効の結果。失効を試みなかった場合は `null`（理由は [skipReason]）
  final TokenRevocationResult? revocation;

  /// 失効を試みなかった理由。試みた場合は `null`
  final RevocationSkipReason? skipReason;

  /// 端末上のトークンを削除したか
  ///
  /// `false` になるのは、[SignOutMode.revokeOrKeep] で失効を確認できなかった
  /// 場合と、失効を待つ間に同じアカウントのトークンが保存し直された場合
  final bool deleted;

  const SignOutResult({
    required this.key,
    this.revocation,
    this.skipReason,
    required this.deleted,
  });

  @override
  String toString() {
    final parts = [
      'key=$key',
      if (revocation != null) 'revocation=$revocation',
      if (skipReason != null) 'skipReason=${skipReason!.name}',
      'deleted=$deleted',
    ];
    return 'SignOutResult(${parts.join(', ')})';
  }
}
