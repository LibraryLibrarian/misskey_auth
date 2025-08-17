import 'dart:math';

import 'package:dio/dio.dart';

/// ネットワークリクエストのリトライポリシー。
class RetryPolicy {
  /// 最大試行回数（初回含む）。
  final int maxAttempts;

  /// 初回遅延。
  final Duration initialDelay;

  /// 指数バックオフの倍率。
  final double backoffFactor;

  /// 遅延の上限。
  final Duration maxDelay;

  /// リトライ対象の Dio 例外タイプ。
  final Set<DioExceptionType> retryOnTypes;

  /// リトライ対象のHTTPステータス。
  final Set<int> retryOnStatusCodes;

  const RetryPolicy({
    this.maxAttempts = 3,
    this.initialDelay = const Duration(milliseconds: 500),
    this.backoffFactor = 2.0,
    this.maxDelay = const Duration(seconds: 5),
    this.retryOnTypes = const {
      DioExceptionType.connectionTimeout,
      DioExceptionType.sendTimeout,
      DioExceptionType.receiveTimeout,
      DioExceptionType.connectionError,
      DioExceptionType.unknown,
    },
    this.retryOnStatusCodes = const {429, 500, 502, 503, 504},
  });

  /// 応答/例外からリトライすべきかを判定。
  bool shouldRetry(DioException e) {
    if (retryOnTypes.contains(e.type)) {
      return true;
    }
    final status = e.response?.statusCode;
    if (status != null && retryOnStatusCodes.contains(status)) {
      return true;
    }
    return false;
  }

  /// 指数バックオフで次の遅延を計算（上限あり、軽いジッター）。
  Duration nextDelay(int attemptIndexZeroBased) {
    final baseMs =
        initialDelay.inMilliseconds * pow(backoffFactor, attemptIndexZeroBased);
    final cappedMs = min(baseMs.round(), maxDelay.inMilliseconds);
    final jitterMs = Random().nextInt(100); // 0-99ms の軽いジッター
    return Duration(
        milliseconds: min(cappedMs + jitterMs, maxDelay.inMilliseconds));
  }
}

/// 与えられた非同期処理をリトライ付きで実行します。
Future<T> retry<T>(Future<T> Function() action, RetryPolicy policy) async {
  DioException? last;
  for (int attempt = 0; attempt < policy.maxAttempts; attempt++) {
    try {
      return await action();
    } on DioException catch (e) {
      last = e;
      final should = policy.shouldRetry(e);
      final isLast = attempt == policy.maxAttempts - 1;
      if (!should || isLast) {
        rethrow;
      }
      await Future.delayed(policy.nextDelay(attempt));
      continue;
    }
  }
  // 通常ここには到達しない
  if (last != null) throw last;
  throw StateError('Retry failed with unknown error');
}
