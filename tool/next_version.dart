import 'dart:io';

import 'src/release_project.dart';

void main(List<String> arguments) {
  if (arguments.isEmpty || arguments.length > 2) {
    stderr.writeln(
      'Usage: dart run tool/next_version.dart <beta|stable> [output-path]\n'
      'Example: dart run tool/next_version.dart beta\n'
      'Example: dart run tool/next_version.dart stable version.txt',
    );
    exitCode = 64;
    return;
  }

  final ReleaseChannel channel;
  switch (arguments.first) {
    case 'beta':
      channel = ReleaseChannel.beta;
    case 'stable':
      channel = ReleaseChannel.stable;
    default:
      stderr.writeln(
        'Unknown channel "${arguments.first}". Use beta or stable.',
      );
      exitCode = 64;
      return;
  }

  // dart runはnative assetsのビルド進捗をstdoutへ出すため、出力先が指定された
  // 場合はリダイレクトに頼らずツール側でファイルへ書き出す
  final outputPath = arguments.length == 2 ? arguments[1] : null;

  try {
    final version = nextReleaseVersion(Directory.current, channel: channel);
    if (outputPath == null) {
      stdout.writeln(version);
    } else {
      File(outputPath).writeAsStringSync('$version\n');
    }
  } on ReleaseToolException catch (error) {
    stderr.writeln('Version derivation failed: ${error.message}');
    exitCode = 1;
  } on FileSystemException catch (error) {
    stderr.writeln('Version derivation failed: ${error.message}');
    exitCode = 1;
  }
}
