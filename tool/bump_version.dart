import 'dart:io';

import 'src/release_project.dart';

void main(List<String> arguments) {
  if (arguments.length != 1) {
    stderr.writeln(
      'Usage: dart run tool/bump_version.dart <version>\n'
      'Example: dart run tool/bump_version.dart 1.0.0-beta.4',
    );
    exitCode = 64;
    return;
  }

  try {
    final paths = bumpVersion(Directory.current, arguments.single);
    stdout.writeln('Updated version to ${arguments.single}:');
    for (final path in paths) {
      stdout.writeln('- $path');
    }
  } on ReleaseToolException catch (error) {
    stderr.writeln('Version update failed: ${error.message}');
    exitCode = 1;
  } on FileSystemException catch (error) {
    stderr.writeln('Version update failed: ${error.message}');
    exitCode = 1;
  }
}
