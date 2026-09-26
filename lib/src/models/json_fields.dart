/// 必須フィールドを型を確認して取り出す。欠落・型違いは [FormatException]
T requireField<T extends Object>(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is T) return value;
  throw FormatException('Field "$key" is missing or is not a $T');
}

/// 任意フィールドを型を確認して取り出す。型違いは [FormatException]
T? optionalField<T extends Object>(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) return null;
  if (value is T) return value;
  throw FormatException('Field "$key" is not a $T');
}

/// 任意の文字列配列フィールドを取り出す。型違いは [FormatException]
List<String>? optionalStringList(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) return null;
  if (value is List && value.every((e) => e is String)) {
    return List<String>.from(value);
  }
  throw FormatException('Field "$key" is not a list of strings');
}
