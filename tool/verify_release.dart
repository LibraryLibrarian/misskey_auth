import 'dart:io';

import 'src/release_project.dart';

void main(List<String> arguments) {
  if (arguments.length != 1) {
    stderr.writeln(
      'Usage: dart run tool/verify_release.dart <version>\n'
      'Example: dart run tool/verify_release.dart 1.0.0-beta.4',
    );
    exitCode = 64;
    return;
  }

  try {
    verifyRelease(Directory.current, arguments.single);
    stdout.writeln('Release version ${arguments.single} is consistent.');
  } on ReleaseToolException catch (error) {
    stderr.writeln('Release verification failed: ${error.message}');
    exitCode = 1;
  } on FileSystemException catch (error) {
    stderr.writeln('Release verification failed: ${error.message}');
    exitCode = 1;
  }
}
