import '../exceptions/misskey_auth_exception.dart';

/// トークン失効の結果の種類
enum TokenRevocationStatus {
  /// サーバーがトークンを失効させた
  revoked,

  /// サーバーがトークンを認識しなかった（失効済み、またはアカウント削除済み）
  alreadyInvalid,

  /// サーバーがアプリのトークンによる失効に対応していない（Misskey 2026.9.0 未満など）
  unsupported,

  /// 通信の失敗や想定外の応答により、失効できたか分からない
  failed,
}

/// `/api/i/revoke-token` による失効の結果
class TokenRevocationResult {
  /// 結果の種類
  final TokenRevocationStatus status;

  /// HTTP ステータス。応答を受け取れなかった場合は `null`
  final int? statusCode;

  /// エラー応答の `error.code`（例: `RATE_LIMIT_EXCEEDED`）。無い場合は `null`
  final String? errorCode;

  /// [status] が [TokenRevocationStatus.unsupported] または
  /// [TokenRevocationStatus.failed] のときの原因
  ///
  /// 返すだけで投げない。トークンを含めないため `originalException` は持たない
  final MisskeyAuthException? error;

  const TokenRevocationResult({
    required this.status,
    this.statusCode,
    this.errorCode,
    this.error,
  });

  /// サーバー上でトークンが使えない状態になっているか
  ///
  /// [TokenRevocationStatus.revoked] と [TokenRevocationStatus.alreadyInvalid] で `true`
  bool get isInvalidated =>
      status == TokenRevocationStatus.revoked ||
      status == TokenRevocationStatus.alreadyInvalid;

  @override
  String toString() {
    final parts = [
      'status=${status.name}',
      if (statusCode != null) 'statusCode=$statusCode',
      if (errorCode != null) 'errorCode=$errorCode',
    ];
    return 'TokenRevocationResult(${parts.join(', ')})';
  }
}
