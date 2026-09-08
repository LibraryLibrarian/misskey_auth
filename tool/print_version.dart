import 'dart:io';

import 'src/release_project.dart';

void main() {
  try {
    stdout.writeln(readPubspecVersion(Directory.current));
  } on ReleaseToolException catch (error) {
    stderr.writeln('Failed to read version: ${error.message}');
    exitCode = 1;
  } on FileSystemException catch (error) {
    stderr.writeln('Failed to read version: ${error.message}');
    exitCode = 1;
  }
}
