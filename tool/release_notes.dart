import 'dart:io';

import 'src/release_project.dart';

void main(List<String> arguments) {
  if (arguments.isEmpty || arguments.length > 2) {
    stderr.writeln(
      'Usage: dart run tool/release_notes.dart <version> [output-path]\n'
      'Example: dart run tool/release_notes.dart 1.0.0-beta.4\n'
      'Example: dart run tool/release_notes.dart 1.0.0-beta.4 notes.md',
    );
    exitCode = 64;
    return;
  }

  final version = arguments.first;
  // dart runはnative assetsのビルド進捗をstdoutへ出すため、出力先が指定された
  // 場合はリダイレクトに頼らずツール側でファイルへ書き出す
  final outputPath = arguments.length == 2 ? arguments[1] : null;

  try {
    final notes = extractReleaseNotes(Directory.current, version);
    if (outputPath == null) {
      stdout.write(notes);
    } else {
      File(outputPath).writeAsStringSync(notes);
    }
  } on ReleaseToolException catch (error) {
    stderr.writeln('Release note extraction failed: ${error.message}');
    exitCode = 1;
  } on FileSystemException catch (error) {
    stderr.writeln('Release note extraction failed: ${error.message}');
    exitCode = 1;
  }
}
