import 'dart:io';

/// Files that contain the package dependency version shown to users.
const versionReferencePaths = <String>['README.md'];

// English and Japanese installation examples share one README.
const _expectedReferenceCount = 2;

const _promotionPointerTemplate = 'Included in [{version}].';
const _categoryOrder = <String>[
  'Breaking changes',
  'Added',
  'Changed',
  'Deprecated',
  'Removed',
  'Fixed',
  'Security',
];

final RegExp _semanticVersionPattern = RegExp(
  r'^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)'
  r'(?:-(?:0|[1-9]\d*|\d*[A-Za-z-][0-9A-Za-z-]*)'
  r'(?:\.(?:0|[1-9]\d*|\d*[A-Za-z-][0-9A-Za-z-]*))*)?'
  r'(?:\+[0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*)?$',
);

/// An expected release file or value was missing or inconsistent.
final class ReleaseToolException implements Exception {
  /// Creates an exception with a user-facing [message].
  const ReleaseToolException(this.message);

  /// Describes how the release files are invalid.
  final String message;

  @override
  String toString() => message;
}

/// Returns the package version declared in `pubspec.yaml` under [root].
String readPubspecVersion(Directory root) => _readProject(root).version;

/// Updates every release version reference under [root].
///
/// All inputs are validated before any file is written. The returned paths are
/// relative to [root] and list every updated file.
List<String> bumpVersion(
  Directory root,
  String nextVersion, {
  DateTime? releaseDate,
}) {
  validateReleaseVersion(nextVersion);

  final project = _readProject(root);
  if (project.version == nextVersion) {
    throw ReleaseToolException(
      'Version $nextVersion is already set in pubspec.yaml.',
    );
  }

  if (compareReleaseVersions(nextVersion, project.version) <= 0) {
    throw ReleaseToolException(
      'Version $nextVersion must be greater than ${project.version}.',
    );
  }

  final updates = <String, String>{};
  updates['pubspec.yaml'] = _replacePubspecVersion(
    project.pubspec,
    project.version,
    nextVersion,
  );

  for (final path in versionReferencePaths) {
    final content = _readFile(root, path);
    updates[path] = _replaceVersionReference(
      content,
      path: path,
      packageName: project.name,
      currentVersion: project.version,
      nextVersion: nextVersion,
    );
  }

  final changelog = _readFile(root, 'CHANGELOG.md');
  updates['CHANGELOG.md'] = _addChangelogRelease(
    changelog,
    nextVersion,
    releaseDate ?? DateTime.now(),
  );

  for (final entry in updates.entries) {
    _file(root, entry.key).writeAsStringSync(entry.value);
  }

  return updates.keys.toList(growable: false);
}

/// Verifies that [expectedVersion] matches every release version reference.
void verifyRelease(Directory root, String expectedVersion) {
  validateReleaseVersion(expectedVersion);

  final project = _readProject(root);
  if (project.version != expectedVersion) {
    throw ReleaseToolException(
      'pubspec.yaml has version ${project.version}, expected $expectedVersion.',
    );
  }

  for (final path in versionReferencePaths) {
    final content = _readFile(root, path);
    _readVersionReference(
      content,
      path: path,
      packageName: project.name,
      expectedVersion: expectedVersion,
    );
  }

  final heading = _releaseHeading(
    _readFile(root, 'CHANGELOG.md'),
    expectedVersion,
  );
  extractReleaseNotes(root, expectedVersion);
  final date = heading.group(1)!;
  if (!_isValidDate(date)) {
    throw ReleaseToolException(
      'CHANGELOG.md has an invalid release date for $expectedVersion: $date.',
    );
  }
}

/// Extracts the CHANGELOG body for [version] to use as release notes.
String extractReleaseNotes(Directory root, String version) {
  validateReleaseVersion(version);

  final changelog = _readFile(root, 'CHANGELOG.md');
  final heading = _releaseHeading(changelog, version);
  final nextHeading = RegExp(
    r'^## \[[^\]]+\](?:[ \t]+-[ \t]+.*)?$',
    multiLine: true,
  ).firstMatch(changelog.substring(heading.end));
  final end = nextHeading == null
      ? changelog.length
      : heading.end + nextHeading.start;
  final notes = changelog.substring(heading.end, end).trim();
  if (notes.isEmpty) {
    throw ReleaseToolException(
      'CHANGELOG.md has no release notes for $version.',
    );
  }
  return '$notes\n';
}

RegExpMatch _releaseHeading(String changelog, String version) {
  final headingPattern = RegExp(
    '^## \\[${RegExp.escape(version)}\\] - '
    r'(\d{4}-\d{2}-\d{2})[ \t]*$',
    multiLine: true,
  );
  final headings = headingPattern.allMatches(changelog).toList();
  if (headings.length != 1) {
    throw ReleaseToolException(
      'CHANGELOG.md must contain exactly one release heading for $version.',
    );
  }
  return headings.single;
}

bool _isValidDate(String value) {
  final parts = value.split('-').map(int.parse).toList(growable: false);
  final parsed = DateTime.utc(parts[0], parts[1], parts[2]);
  return parsed.year == parts[0] &&
      parsed.month == parts[1] &&
      parsed.day == parts[2];
}

/// Validates that [version] uses Semantic Versioning syntax.
void validateReleaseVersion(String version) {
  if (!_semanticVersionPattern.hasMatch(version)) {
    throw ReleaseToolException(
      'Invalid version "$version". Expected Semantic Versioning, for example '
      '1.0.0 or 1.0.0-beta.1.',
    );
  }
}

/// Compares valid Semantic Versions by precedence, ignoring build metadata.
int compareReleaseVersions(String a, String b) {
  validateReleaseVersion(a);
  validateReleaseVersion(b);
  final left = _ReleaseVersion(a);
  final right = _ReleaseVersion(b);
  for (var i = 0; i < left.core.length; i++) {
    final order = BigInt.parse(left.core[i])
        .compareTo(BigInt.parse(right.core[i]));
    if (order != 0) return order;
  }
  final leftPre = left.prerelease;
  final rightPre = right.prerelease;
  if (leftPre.isEmpty) return rightPre.isEmpty ? 0 : 1;
  if (rightPre.isEmpty) return -1;
  for (var i = 0; i < leftPre.length && i < rightPre.length; i++) {
    final numeric = RegExp(r'^\d+$');
    final leftNumber = numeric.hasMatch(leftPre[i])
        ? BigInt.parse(leftPre[i])
        : null;
    final rightNumber = numeric.hasMatch(rightPre[i])
        ? BigInt.parse(rightPre[i])
        : null;
    final int order;
    if (leftNumber != null && rightNumber != null) {
      order = leftNumber.compareTo(rightNumber);
    } else if (leftNumber != null) {
      order = -1;
    } else if (rightNumber != null) {
      order = 1;
    } else {
      order = leftPre[i].compareTo(rightPre[i]);
    }
    if (order != 0) return order;
  }
  return leftPre.length.compareTo(rightPre.length);
}

final class _ReleaseVersion {
  _ReleaseVersion(String version) {
    final precedence = version.split('+').first;
    final separator = precedence.indexOf('-');
    core = (separator < 0 ? precedence : precedence.substring(0, separator))
        .split('.');
    prerelease = separator < 0
        ? <String>[]
        : precedence.substring(separator + 1).split('.');
  }

  late final List<String> core;
  late final List<String> prerelease;
}

_Project _readProject(Directory root) {
  final pubspec = _readFile(root, 'pubspec.yaml');
  final name = _readSingleValue(pubspec, path: 'pubspec.yaml', field: 'name');
  final version = _readSingleValue(
    pubspec,
    path: 'pubspec.yaml',
    field: 'version',
  );
  validateReleaseVersion(version);
  return _Project(name: name, version: version, pubspec: pubspec);
}

String _readSingleValue(
  String content, {
  required String path,
  required String field,
}) {
  final pattern = RegExp(
    '^${RegExp.escape(field)}:[ \\t]*([^ \\t\\r\\n#]+)[ \\t]*(?:#.*)?\$',
    multiLine: true,
  );
  final matches = pattern.allMatches(content).toList();
  if (matches.length != 1) {
    throw ReleaseToolException(
      '$path must contain exactly one top-level $field field.',
    );
  }
  return matches.single.group(1)!;
}

String _replacePubspecVersion(
  String pubspec,
  String currentVersion,
  String nextVersion,
) {
  final pattern = RegExp(
    r'^(version:[ \t]*)([^ \t\r\n#]+)([ \t]*(?:#.*)?)$',
    multiLine: true,
  );
  final matches = pattern.allMatches(pubspec).toList();
  if (matches.length != 1) {
    throw const ReleaseToolException(
      'pubspec.yaml must contain exactly one top-level version field.',
    );
  }
  final match = matches.single;
  final foundVersion = match.group(2)!;
  if (foundVersion != currentVersion) {
    throw ReleaseToolException(
      'pubspec.yaml has an inconsistent version: $foundVersion.',
    );
  }
  final versionStart = match.start + match.group(1)!.length;
  return pubspec.replaceRange(
    versionStart,
    versionStart + foundVersion.length,
    nextVersion,
  );
}

String _replaceVersionReference(
  String content, {
  required String path,
  required String packageName,
  required String currentVersion,
  required String nextVersion,
}) {
  final matches = _versionReferenceMatches(
    content,
    path: path,
    packageName: packageName,
  );
  var updated = content;
  for (final match in matches.reversed) {
    final foundVersion = match.group(2)!;
    if (foundVersion != currentVersion) {
      throw ReleaseToolException(
        '$path references $packageName ^$foundVersion, expected ^$currentVersion.',
      );
    }
    final start = match.start + match.group(1)!.length;
    updated = updated.replaceRange(
      start,
      start + foundVersion.length,
      nextVersion,
    );
  }
  return updated;
}

void _readVersionReference(
  String content, {
  required String path,
  required String packageName,
  required String expectedVersion,
}) {
  for (final match in _versionReferenceMatches(
    content,
    path: path,
    packageName: packageName,
  )) {
    final foundVersion = match.group(2)!;
    if (foundVersion != expectedVersion) {
      throw ReleaseToolException(
        '$path references $packageName ^$foundVersion, expected ^$expectedVersion.',
      );
    }
  }
}

List<RegExpMatch> _versionReferenceMatches(
  String content, {
  required String path,
  required String packageName,
}) {
  final pattern = RegExp(
    '^([ \\t]*${RegExp.escape(packageName)}:[ \\t]*\\^)'
    r'([^ \t\r\n#]+)([ \t]*(?:#.*)?)$',
    multiLine: true,
  );
  final matches = pattern.allMatches(content).toList();
  if (matches.length != _expectedReferenceCount) {
    throw ReleaseToolException(
      '$path must contain exactly $_expectedReferenceCount dependency references for $packageName.',
    );
  }
  return matches;
}

String _addChangelogRelease(
  String changelog,
  String nextVersion,
  DateTime releaseDate,
) {
  final existingHeading = RegExp(
    '^## \\[${RegExp.escape(nextVersion)}\\](?:[ \\t]+-[ \\t]+.*)?\$',
    multiLine: true,
  );
  if (existingHeading.hasMatch(changelog)) {
    throw ReleaseToolException(
      'CHANGELOG.md already contains a heading for $nextVersion.',
    );
  }

  final headings = RegExp(
    r'^## \[([^\]]+)\][^\r\n]*',
    multiLine: true,
  ).allMatches(changelog).toList();
  for (final heading in headings) {
    final version = heading.group(1)!;
    if (_semanticVersionPattern.hasMatch(version) &&
        compareReleaseVersions(nextVersion, version) <= 0) {
      throw ReleaseToolException(
        'Version $nextVersion must be greater than CHANGELOG.md version '
        '$version.',
      );
    }
  }

  final unreleasedPattern = RegExp(
    r'^## \[Unreleased\][ \t]*(?:\r?\n)+',
    multiLine: true,
  );
  final unreleasedMatches = unreleasedPattern.allMatches(changelog).toList();
  if (unreleasedMatches.length != 1) {
    throw const ReleaseToolException(
      'CHANGELOG.md must contain exactly one Unreleased heading.',
    );
  }

  final newline = changelog.contains('\r\n') ? '\r\n' : '\n';
  final date = _formatDate(releaseDate);
  final replacement =
      '## [Unreleased]$newline$newline'
      '## [$nextVersion] - $date$newline$newline';
  final match = unreleasedMatches.single;
  final next = _ReleaseVersion(nextVersion);
  final prereleases = <RegExpMatch>[];
  if (next.prerelease.isEmpty) {
    for (final heading in headings) {
      final version = heading.group(1)!;
      if (!_semanticVersionPattern.hasMatch(version)) continue;
      final parsed = _ReleaseVersion(version);
      if (parsed.prerelease.isNotEmpty &&
          parsed.core.join('.') == next.core.join('.') &&
          RegExp(r' - \d{4}-\d{2}-\d{2}[ \t]*$').hasMatch(heading.group(0)!)) {
        prereleases.add(heading);
      }
    }
  }
  if (prereleases.isEmpty) {
    return changelog.replaceRange(match.start, match.end, replacement);
  }

  int bodyEnd(RegExpMatch heading) {
    final index = headings.indexOf(heading);
    return index + 1 < headings.length
        ? headings[index + 1].start
        : changelog.length;
  }

  // Break precedence ties by file order, with older entries first.
  prereleases.sort((a, b) {
    final order = compareReleaseVersions(a.group(1)!, b.group(1)!);
    return order == 0 ? b.start.compareTo(a.start) : order;
  });
  final unreleased = headings.singleWhere(
    (heading) => heading.start == match.start,
  );
  final sources = <String>[
    for (final heading in prereleases)
      changelog.substring(heading.end, bodyEnd(heading)),
    changelog.substring(unreleased.end, bodyEnd(unreleased)),
  ];
  final merged = _mergeReleaseBodies(sources, newline);
  final pointer = _promotionPointerTemplate.replaceAll(
    '{version}',
    nextVersion,
  );
  var updated = changelog;
  // Apply replacements backwards so the original offsets remain valid.
  final replaced = <RegExpMatch>[...prereleases, unreleased]
    ..sort((a, b) => b.start.compareTo(a.start));
  for (final heading in replaced) {
    if (heading == unreleased) {
      updated = updated.replaceRange(
        heading.start,
        bodyEnd(heading),
        '$replacement$merged$newline$newline',
      );
    } else {
      updated = updated.replaceRange(
        heading.end,
        bodyEnd(heading),
        '$newline$newline$pointer$newline$newline',
      );
    }
  }
  return updated;
}

String _mergeReleaseBodies(List<String> sources, String newline) {
  final seen = <String>{};
  final preamble = _ReleaseLines(seen);
  final categories = <String, _ReleaseLines>{};
  final categoryPattern = RegExp(r'^###[ \t]+(.+?)\s*$');
  for (final source in sources) {
    var lines = preamble;
    for (final line in source.trim().split(RegExp(r'\r?\n'))) {
      final category = categoryPattern.firstMatch(line);
      if (category != null) {
        lines = categories.putIfAbsent(
          category.group(1)!,
          () => _ReleaseLines(seen),
        );
      } else {
        lines.add(line);
      }
    }
  }
  final sections = <String>[];
  final introduction = preamble.render(newline);
  if (introduction.isNotEmpty) sections.add(introduction);
  final names = <String>{..._categoryOrder, ...categories.keys};
  for (final name in names) {
    final lines = categories[name];
    if (lines == null) continue;
    sections.add(
      '### $name$newline$newline${lines.render(newline)}'.trimRight(),
    );
  }
  return sections.join('$newline$newline');
}

final class _ReleaseLines {
  _ReleaseLines(this._seen);

  final _lines = <String>[];
  final Set<String> _seen;

  void add(String line) {
    if (line.trim().isEmpty || _seen.add(line.trim())) _lines.add(line);
  }

  String render(String newline) => _lines.join(newline).trim();
}

String _formatDate(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}

String _readFile(Directory root, String path) {
  final file = _file(root, path);
  if (!file.existsSync()) {
    throw ReleaseToolException('Required file is missing: $path.');
  }
  return file.readAsStringSync();
}

File _file(Directory root, String path) => File.fromUri(root.uri.resolve(path));

final class _Project {
  const _Project({
    required this.name,
    required this.version,
    required this.pubspec,
  });

  final String name;
  final String version;
  final String pubspec;
}
