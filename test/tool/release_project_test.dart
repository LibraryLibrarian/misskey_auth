import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/src/release_project.dart';

void main() {
  late Directory root;

  setUp(() {
    root = Directory.systemTemp.createTempSync('misskey_release_tools_');
    _createProject(root);
  });

  tearDown(() {
    root.deleteSync(recursive: true);
  });

  test('readPubspecVersion returns the validated package version', () {
    expect(readPubspecVersion(root), '1.0.0-beta.3');
  });

  test('bumpVersion updates all version references and CHANGELOG', () {
    final updatedPaths = bumpVersion(
      root,
      '1.0.0-beta.4',
      releaseDate: DateTime.utc(2026, 8, 13),
    );

    expect(_read(root, 'pubspec.yaml'), contains('version: 1.0.0-beta.4'));
    expect(
      RegExp(r'misskey_auth: \^1\.0\.0-beta\.4')
          .allMatches(_read(root, 'README.md'))
          .length,
      2,
    );
    for (final path in versionReferencePaths) {
      expect(
        _read(root, path),
        contains('misskey_auth: ^1.0.0-beta.4'),
        reason: path,
      );
    }
    expect(
      _read(root, 'CHANGELOG.md'),
      contains(
        '## [Unreleased]\n\n'
        '## [1.0.0-beta.4] - 2026-08-13\n\n'
        '### Added',
      ),
    );
    expect(
      updatedPaths,
      containsAll(<String>[
        'pubspec.yaml',
        ...versionReferencePaths,
        'CHANGELOG.md',
      ]),
    );
    expect(() => verifyRelease(root, '1.0.0-beta.4'), returnsNormally);
  });

  test('bumpVersion does not write files when a reference is inconsistent', () {
    _write(
      root,
      versionReferencePaths.first,
      'dependencies:\n  misskey_auth: ^1.0.0-beta.2\n',
    );
    final originalPubspec = _read(root, 'pubspec.yaml');
    final originalChangelog = _read(root, 'CHANGELOG.md');

    expect(
      () => bumpVersion(root, '1.0.0-beta.4'),
      throwsA(
        isA<ReleaseToolException>().having(
          (error) => error.message,
          'message',
          contains(versionReferencePaths.first),
        ),
      ),
    );
    expect(_read(root, 'pubspec.yaml'), originalPubspec);
    expect(_read(root, 'CHANGELOG.md'), originalChangelog);
  });

  test('verifyRelease rejects a mismatched documentation version', () {
    _write(
      root,
      versionReferencePaths.last,
      'dependencies:\n  misskey_auth: ^1.0.0-beta.2\n',
    );

    expect(
      () => verifyRelease(root, '1.0.0-beta.3'),
      throwsA(
        isA<ReleaseToolException>().having(
          (error) => error.message,
          'message',
          contains(versionReferencePaths.last),
        ),
      ),
    );
  });

  test('rejects a stale Japanese reference without writing any files', () {
    final readme = _read(root, 'README.md').replaceFirst(
      '# Japanese\n  misskey_auth: ^1.0.0-beta.3',
      '# Japanese\n  misskey_auth: ^1.0.0-beta.2',
    );
    _write(root, 'README.md', readme);
    final before = _read(root, 'pubspec.yaml');
    expect(
      () => bumpVersion(root, '1.0.0-beta.4'),
      throwsA(isA<ReleaseToolException>()),
    );
    expect(
      () => verifyRelease(root, '1.0.0-beta.3'),
      throwsA(isA<ReleaseToolException>()),
    );
    expect(_read(root, 'pubspec.yaml'), before);
    expect(_read(root, 'README.md'), readme);
  });

  test('verifyRelease rejects an invalid CHANGELOG date', () {
    final changelog = _read(
      root,
      'CHANGELOG.md',
    ).replaceFirst('2026-08-05', '2026-02-30');
    _write(root, 'CHANGELOG.md', changelog);

    expect(
      () => verifyRelease(root, '1.0.0-beta.3'),
      throwsA(
        isA<ReleaseToolException>().having(
          (error) => error.message,
          'message',
          contains('invalid release date'),
        ),
      ),
    );
  });

  test('extractReleaseNotes returns only the requested release body', () {
    final notes = extractReleaseNotes(root, '1.0.0-beta.3');

    expect(notes, '### Added\n\n- Released change\n');
    expect(notes, isNot(contains('Pending change')));
    expect(notes, isNot(contains('1.0.0-beta.2')));
  });

  test('extractReleaseNotes rejects a release without notes', () {
    _write(
      root,
      'CHANGELOG.md',
      '# Changelog\n\n'
          '## [Unreleased]\n\n'
          '## [1.0.0-beta.3] - 2026-08-05\n\n'
          '## [1.0.0-beta.2] - 2026-07-01\n\n'
          '### Fixed\n\n'
          '- Older change\n',
    );

    expect(
      () => extractReleaseNotes(root, '1.0.0-beta.3'),
      throwsA(
        isA<ReleaseToolException>().having(
          (error) => error.message,
          'message',
          contains('no release notes'),
        ),
      ),
    );
  });

  test('verifyRelease rejects a release without notes', () {
    _write(
      root,
      'CHANGELOG.md',
      '## [Unreleased]\n\n## [1.0.0-beta.3] - 2026-08-05\n\n',
    );

    expect(
      () => verifyRelease(root, '1.0.0-beta.3'),
      throwsA(
        isA<ReleaseToolException>().having(
          (error) => error.message,
          'message',
          contains('no release notes'),
        ),
      ),
    );
  });

  test('bumpVersion rejects unchanged versions and duplicate headings', () {
    expect(
      () => bumpVersion(root, '1.0.0-beta.3'),
      throwsA(isA<ReleaseToolException>()),
    );
    expect(
      () => bumpVersion(root, '1.0.0-beta.2'),
      throwsA(isA<ReleaseToolException>()),
    );
  });

  test('verifyRelease rejects a mismatched tag version', () {
    expect(
      () => verifyRelease(root, '1.0.0-beta.4'),
      throwsA(isA<ReleaseToolException>()),
    );
  });

  test('bumpVersion preserves CRLF and accepts a stable version', () {
    _write(
      root,
      'CHANGELOG.md',
      _read(root, 'CHANGELOG.md').replaceAll('\n', '\r\n'),
    );
    bumpVersion(root, '1.0.0', releaseDate: DateTime.utc(2026, 9, 8));
    expect(
      _read(root, 'CHANGELOG.md'),
      contains('## [1.0.0] - 2026-09-08\r\n'),
    );
    final changelog = _read(root, 'CHANGELOG.md');
    expect(changelog.replaceAll('\r\n', ''), isNot(contains('\n')));
    final notes = extractReleaseNotes(root, '1.0.0');
    expect(notes, contains('- Released change\r\n'));
    expect(notes, contains('- Pending change\r\n'));
    expect(notes, contains('- Older change'));
    expect(
      changelog,
      contains(
        '## [1.0.0-beta.3] - 2026-08-05\r\n\r\n'
        'Included in [1.0.0].\r\n',
      ),
    );
    expect(() => verifyRelease(root, '1.0.0'), returnsNormally);
  });

  test('promotion merges categories from oldest beta through Unreleased', () {
    _write(
      root,
      'CHANGELOG.md',
      '# Changelog\n\n'
          '## [Unreleased]\n\n'
          '### Fixed\n\n- Pending fix\n\n'
          '### Added\n\n- Pending addition\n\n'
          '## [1.0.0-beta.2] - 2026-08-02\n\n'
          '### Added\n\n- Second addition\n\n'
          '### Security\n\n- Security update\n\n'
          '### Deprecated\n\n- Deprecated API\n\n'
          '## [1.0.0-beta.1] - 2026-08-01\n\n'
          '### Fixed\n\n- First fix\n\n'
          '### Removed\n\n- Removed API\n\n'
          '### Changed\n\n- Changed API\n\n'
          '### Added\n\n- First addition\n\n'
          '### Breaking changes\n\n- Breaking API\n\n'
          '## [0.9.0] - 2026-07-01\n\n- Old stable notes\n',
    );

    bumpVersion(root, '1.0.0', releaseDate: DateTime.utc(2026, 9, 8));

    final notes = extractReleaseNotes(root, '1.0.0');
    _expectInOrder(notes, <String>[
      '### Breaking changes',
      '### Added',
      '- First addition',
      '- Second addition',
      '- Pending addition',
      '### Changed',
      '### Deprecated',
      '### Removed',
      '### Fixed',
      '- First fix',
      '- Pending fix',
      '### Security',
    ]);
    final changelog = _read(root, 'CHANGELOG.md');
    expect(changelog, contains('## [Unreleased]\n\n## [1.0.0] - 2026-09-08\n'));
    for (final beta in <int>[1, 2]) {
      expect(
        changelog,
        contains(
          '## [1.0.0-beta.$beta] - 2026-08-0$beta\n\n'
          'Included in [1.0.0].\n',
        ),
      );
      expect(
        extractReleaseNotes(root, '1.0.0-beta.$beta'),
        'Included in [1.0.0].\n',
      );
    }
    expect(extractReleaseNotes(root, '0.9.0'), '- Old stable notes\n');
    expect(() => verifyRelease(root, '1.0.0'), returnsNormally);
  });

  test('promotion succeeds with empty Unreleased and returns beta notes', () {
    _write(
      root,
      'CHANGELOG.md',
      _read(
        root,
        'CHANGELOG.md',
      ).replaceFirst('### Added\n\n- Pending change\n\n', ''),
    );

    bumpVersion(root, '1.0.0');

    expect(
      extractReleaseNotes(root, '1.0.0'),
      '### Added\n\n- Released change\n\n### Fixed\n\n- Older change\n',
    );
    expect(() => verifyRelease(root, '1.0.0'), returnsNormally);
  });

  test(
    'promotion deduplicates trimmed lines and keeps the first occurrence',
    () {
      _write(
        root,
        'CHANGELOG.md',
        '## [Unreleased]\n\n### Added\n\n- Shared change  \n- New change\n\n'
            '## [1.0.0-beta.2] - 2026-08-02\n\n'
            '### Added\n\n  - Shared change\n\n'
            '### Fixed\n\n- Shared change\n- Unique fix\n\n'
            '## [1.0.0-beta.1] - 2026-08-01\n\n'
            '### Added\n\n- Shared change\n- First change\n',
      );

      bumpVersion(root, '1.0.0');

      final notes = extractReleaseNotes(root, '1.0.0');
      expect('Shared change'.allMatches(notes), hasLength(1));
      _expectInOrder(notes, <String>[
        '- Shared change',
        '- First change',
        '- New change',
      ]);
    },
  );

  test('promotion preserves unknown categories and introductory prose', () {
    _write(
      root,
      'CHANGELOG.md',
      '## [Unreleased]\n\nFinal introduction.\n\n'
          '### Documentation\n\n- Updated docs\n\n'
          '## [1.0.0-beta.2] - 2026-08-02\n\nSecond introduction.\n\n'
          '### Maintenance\n\n- New maintenance\n\n'
          '### Added\n\n- New feature\n\n'
          '## [1.0.0-beta.1] - 2026-08-01\n\n'
          'The upcoming release migrates persistence from Isar to Drift.\n\n'
          '### Migration\n\n- Migration guide\n\n'
          '### Maintenance\n\n- Old maintenance\n',
    );

    bumpVersion(root, '1.0.0');

    _expectInOrder(extractReleaseNotes(root, '1.0.0'), <String>[
      'The upcoming release migrates persistence from Isar to Drift.',
      'Second introduction.',
      'Final introduction.',
      '### Added',
      '### Migration',
      '### Maintenance',
      '- Old maintenance',
      '- New maintenance',
      '### Documentation',
    ]);
  });

  test('promotion orders beta.9 before beta.10 regardless of file order', () {
    _write(
      root,
      'CHANGELOG.md',
      '## [Unreleased]\n\n'
          '## [1.0.0-beta.9] - 2026-08-09\n\n### Added\n\n- Ninth\n\n'
          '## [1.0.0-beta.10] - 2026-08-10\n\n### Added\n\n- Tenth\n',
    );

    bumpVersion(root, '1.0.0');

    _expectInOrder(extractReleaseNotes(root, '1.0.0'), <String>[
      '- Ninth',
      '- Tenth',
    ]);
  });

  test(
    'stable bump without matching prereleases leaves older notes intact',
    () {
      final original = _read(root, 'CHANGELOG.md');
      bumpVersion(root, '1.1.0', releaseDate: DateTime.utc(2026, 9, 8));

      expect(
        _read(root, 'CHANGELOG.md'),
        original.replaceFirst(
          '## [Unreleased]\n\n',
          '## [Unreleased]\n\n## [1.1.0] - 2026-09-08\n\n',
        ),
      );
      expect(
        extractReleaseNotes(root, '1.1.0'),
        '### Added\n\n- Pending change\n',
      );
    },
  );

  test('bump rejects downgrades and equal precedence without any writes', () {
    final before = <String, String>{
      for (final path in <String>[
        'pubspec.yaml',
        ...versionReferencePaths,
        'CHANGELOG.md',
      ])
        path: _read(root, path),
    };
    for (final next in <String>['0.9.0', '1.0.0-beta.3+build.1']) {
      expect(
        () => bumpVersion(root, next),
        throwsA(isA<ReleaseToolException>()),
      );
      for (final entry in before.entries) {
        expect(_read(root, entry.key), entry.value, reason: entry.key);
      }
    }
  });

  test('bump must exceed every CHANGELOG release before writing files', () {
    for (final existing in <String>['2.0.0', '1.0.0-beta.4+other']) {
      _write(
        root,
        'CHANGELOG.md',
        '## [Unreleased]\n\n### Added\n\n- Pending\n\n'
            '## [$existing] - 2026-08-01\n\n- Existing\n',
      );
      final before = <String, String>{
        for (final path in <String>[
          'pubspec.yaml',
          ...versionReferencePaths,
          'CHANGELOG.md',
        ])
          path: _read(root, path),
      };
      expect(
        () => bumpVersion(root, '1.0.0-beta.4'),
        throwsA(isA<ReleaseToolException>()),
      );
      for (final entry in before.entries) {
        expect(_read(root, entry.key), entry.value, reason: entry.key);
      }
    }
  });

  test('compareReleaseVersions follows SemVer precedence', () {
    final ordered = <String>[
      '1.0.0-1',
      '1.0.0-alpha',
      '1.0.0-alpha.1',
      '1.0.0-alpha.beta',
      '1.0.0-beta',
      '1.0.0-beta.2',
      '1.0.0-beta.9',
      '1.0.0-beta.10',
      '1.0.0-rc.1',
      '1.0.0',
      '1.0.1',
      '1.1.0',
      '2.0.0',
      '10.0.0',
    ];
    for (var i = 0; i < ordered.length - 1; i++) {
      expect(compareReleaseVersions(ordered[i], ordered[i + 1]), lessThan(0));
      expect(
        compareReleaseVersions(ordered[i + 1], ordered[i]),
        greaterThan(0),
      );
    }
    expect(compareReleaseVersions('1.0.0+one', '1.0.0+two'), 0);
    expect(compareReleaseVersions('1.0.0-beta.1+x', '1.0.0-beta.1'), 0);
    expect(compareReleaseVersions('1.0.0', '1.0.0'), 0);
    expect(compareReleaseVersions('1.0.0-1', '1.0.0--1'), lessThan(0));
    expect(
      () => compareReleaseVersions('1.0', '1.0.0'),
      throwsA(isA<ReleaseToolException>()),
    );
  });

  test('release tools reject invalid Semantic Versions', () {
    expect(
      () => bumpVersion(root, '1.0'),
      throwsA(isA<ReleaseToolException>()),
    );
    expect(
      () => verifyRelease(root, '1.0.0-01'),
      throwsA(isA<ReleaseToolException>()),
    );
  });
}

void _expectInOrder(String text, List<String> values) {
  var previous = -1;
  for (final value in values) {
    final index = text.indexOf(value);
    expect(index, greaterThan(previous), reason: value);
    previous = index;
  }
}

void _createProject(Directory root) {
  _write(
    root,
    'pubspec.yaml',
    'name: misskey_auth\n'
        'version: 1.0.0-beta.3\n',
  );
  for (final path in versionReferencePaths) {
    _write(
      root,
      path,
      '# Usage\n\n'
      'dependencies:\n'
      '  misskey_auth: ^1.0.0-beta.3\n'
      '# Japanese\n'
      '  misskey_auth: ^1.0.0-beta.3\n',
    );
  }
  _write(
    root,
    'CHANGELOG.md',
    '# Changelog\n\n'
        '## [Unreleased]\n\n'
        '### Added\n\n'
        '- Pending change\n\n'
        '## [1.0.0-beta.3] - 2026-08-05\n\n'
        '### Added\n\n'
        '- Released change\n\n'
        '## [1.0.0-beta.2] - 2026-07-01\n\n'
        '### Fixed\n\n'
        '- Older change\n',
  );
}

void _write(Directory root, String path, String content) {
  final file = File.fromUri(root.uri.resolve(path));
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(content);
}

String _read(Directory root, String path) =>
    File.fromUri(root.uri.resolve(path)).readAsStringSync();
