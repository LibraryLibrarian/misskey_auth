import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/src/release_config.dart';
import '../../tool/src/release_project.dart';

/// Checks this repository's own release configuration.
///
/// `release_project_test.dart` exercises the shared tool against synthetic
/// projects. This suite instead points the configured checks at the real files,
/// so a reference file that stops matching `releaseConfig` fails on every CI
/// run rather than at release time.
void main() {
  test('releaseConfig matches the files in this repository', () {
    final root = _packageRoot();
    expect(
      () =>
          verifyRelease(root, readPubspecVersion(root), config: releaseConfig),
      returnsNormally,
    );
  });
}

/// Finds the package root regardless of where the test runner was started.
///
/// Test runners usually set the current directory to the package root, but not
/// when a test file is addressed by a relative path from elsewhere. Walking up
/// keeps the failure meaningful instead of reporting a missing `pubspec.yaml`.
/// A bundled example has its own `pubspec.yaml` but no `CHANGELOG.md`, so both
/// are required to identify the package that is released from this repository.
Directory _packageRoot() {
  var directory = Directory.current.absolute;
  while (true) {
    // 折り返し位置が SDK 間で割れないよう、メソッドチェーンを分ける
    final pubspec = File.fromUri(directory.uri.resolve('pubspec.yaml'));
    final changelog = File.fromUri(directory.uri.resolve('CHANGELOG.md'));
    if (pubspec.existsSync() && changelog.existsSync()) return directory;
    final parent = directory.parent;
    if (parent.path == directory.path) {
      throw StateError(
        'No package with a pubspec.yaml and a CHANGELOG.md was found at or '
        'above ${Directory.current.path}.',
      );
    }
    directory = parent;
  }
}
