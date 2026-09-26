import 'dart:convert';

import 'package:dio/dio.dart';

import '../exceptions/misskey_auth_exception.dart';

/// 応答ボディを JSON オブジェクトとして取り出す
///
/// Dio が JSON として解釈しなかった文字列もここで解釈する。
/// オブジェクト以外は [FormatException]
Map<String, dynamic> jsonObjectOf(Object? data) {
  final decoded = data is String ? jsonDecode(data) : data;
  if (decoded is Map<String, dynamic>) return decoded;
  throw const FormatException('The response body is not a JSON object');
}

/// エラー応答から、例外の詳細に載せる短い説明を取り出す
///
/// トークン等を含み得るため、ボディ全体は載せない
String? errorSummaryOf(Object? data) {
  if (data is! Map) return null;
  final error = data['error'];
  // RFC 6749 形式: {error, error_description}
  if (error is String) {
    final description = data['error_description'];
    return description is String
        ? 'error=$error, description=$description'
        : 'error=$error';
  }
  // Misskey API 形式: {error: {code, message}}
  if (error is Map) {
    final code = error['code'];
    final message = error['message'];
    final parts = [
      if (code is String) 'code=$code',
      if (message is String) 'message=$message',
    ];
    return parts.isEmpty ? null : parts.join(', ');
  }
  final message = data['message'];
  return message is String ? 'message=$message' : null;
}

/// 応答ステータスを伴わない [DioException] をライブラリの例外へ変換する
///
/// 応答ボディの JSON 解釈に失敗した場合は [ResponseParseException]、
/// それ以外は [NetworkException]
MisskeyAuthException transportExceptionOf(DioException e) {
  final cause = e.error;
  if (cause is FormatException) {
    return ResponseParseException(details: cause.message, originalException: e);
  }
  return NetworkException(details: e.message, originalException: e);
}
