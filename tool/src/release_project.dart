// このファイルは misskey_auth / misskey_client / mastodon_client /
// misskey_mfm_parser / misskey_emoji / misskey_mfm_renderer の6リポジトリで
// バイト単位で同一に保つ。リポジトリごとの違いは release_config.dart に置く。
//
// 変更する場合は6リポジトリすべてへ同じ内容を反映すること。同一性は次で確認する。
//   shasum -a 256 */tool/src/release_project.dart
//
// Flutter 3.38.7 と 3.47.1 の dart format が同じ出力を返すことを確認済み。
// 折り返し位置が SDK 間で割れる書き方を持ち込まないこと。

import 'dart:io';

/// How many times a package depends on itself inside a single reference file.
sealed class VersionReferenceCount {
  const VersionReferenceCount();

  /// Requires exactly [count] references, failing when the number differs.
  const factory VersionReferenceCount.exactly(int count) = _ExactReferences;

  /// Requires at least one reference and updates every one of them.
  const factory VersionReferenceCount.atLeastOne() = _AnyReferences;

  void _check(int found, {required String path, required String packageName});
}

final class _ExactReferences extends VersionReferenceCount {
  const _ExactReferences(this.count);

  final int count;

  @override
  void _check(int found, {required String path, required String packageName}) {
    if (found == count) return;
    final noun = count == 1 ? 'reference' : 'references';
    final amount = count == 1 ? 'one' : '$count';
    throw ReleaseToolException(
      '$path must contain exactly $amount dependency $noun for $packageName.',
    );
  }
}

final class _AnyReferences extends VersionReferenceCount {
  const _AnyReferences();

  @override
  void _check(int found, {required String path, required String packageName}) {
    if (found > 0) return;
    throw ReleaseToolException(
      '$path must contain at least one dependency reference for $packageName.',
    );
  }
}

/// Per-repository release settings.
///
/// Everything that differs between the packages sharing this tool lives here,
/// so that `release_project.dart` itself stays byte-identical across them.
final class ReleaseConfig {
  /// Creates a configuration; every field is optional.
  const ReleaseConfig({
    this.versionReferencePaths = const <String>[],
    this.referenceCount = const VersionReferenceCount.exactly(1),
    this.exampleLockPath,
  });

  /// Files that show the package dependency version to users.
  final List<String> versionReferencePaths;

  /// How many references each of [versionReferencePaths] must contain.
  final VersionReferenceCount referenceCount;

  /// A `pubspec.lock` that pins this package through a path dependency.
  ///
  /// `null` when the repository has no example application to keep in sync.
  final String? exampleLockPath;
}

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

final RegExp _datedHeadingSuffix = RegExp(r' - \d{4}-\d{2}-\d{2}[ \t]*$');

final RegExp _numericIdentifier = RegExp(r'^\d+$');

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
  required ReleaseConfig config,
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

  for (final path in config.versionReferencePaths) {
    updates[path] = _replaceVersionReferences(
      _readFile(root, path),
      path: path,
      packageName: project.name,
      currentVersion: project.version,
      nextVersion: nextVersion,
      count: config.referenceCount,
    );
  }

  final changelog = _readFile(root, 'CHANGELOG.md');
  updates['CHANGELOG.md'] = _addChangelogRelease(
    changelog,
    nextVersion,
    releaseDate ?? DateTime.now(),
  );

  final lockPath = config.exampleLockPath;
  if (lockPath != null) {
    updates[lockPath] = _replaceExampleLockVersion(
      _readFile(root, lockPath),
      path: lockPath,
      packageName: project.name,
      currentVersion: project.version,
      nextVersion: nextVersion,
    );
  }

  for (final entry in updates.entries) {
    _file(root, entry.key).writeAsStringSync(entry.value);
  }

  return updates.keys.toList(growable: false);
}

/// Verifies that [expectedVersion] matches every release version reference.
void verifyRelease(
  Directory root,
  String expectedVersion, {
  required ReleaseConfig config,
}) {
  validateReleaseVersion(expectedVersion);

  final project = _readProject(root);
  if (project.version != expectedVersion) {
    throw ReleaseToolException(
      'pubspec.yaml has version ${project.version}, expected $expectedVersion.',
    );
  }

  for (final path in config.versionReferencePaths) {
    _readVersionReferences(
      _readFile(root, path),
      path: path,
      packageName: project.name,
      expectedVersion: expectedVersion,
      count: config.referenceCount,
    );
  }

  final lockPath = config.exampleLockPath;
  if (lockPath != null) {
    _readExampleLockVersion(
      _readFile(root, lockPath),
      path: lockPath,
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
    final leftCore = BigInt.parse(left.core[i]);
    final rightCore = BigInt.parse(right.core[i]);
    final order = leftCore.compareTo(rightCore);
    if (order != 0) return order;
  }
  final leftPre = left.prerelease;
  final rightPre = right.prerelease;
  if (leftPre.isEmpty) return rightPre.isEmpty ? 0 : 1;
  if (rightPre.isEmpty) return -1;
  for (var i = 0; i < leftPre.length && i < rightPre.length; i++) {
    final leftNumber = _numericIdentifier.hasMatch(leftPre[i])
        ? BigInt.parse(leftPre[i])
        : null;
    final rightNumber = _numericIdentifier.hasMatch(rightPre[i])
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

String _replaceVersionReferences(
  String content, {
  required String path,
  required String packageName,
  required String currentVersion,
  required String nextVersion,
  required VersionReferenceCount count,
}) {
  final matches = _versionReferenceMatches(
    content,
    path: path,
    packageName: packageName,
    count: count,
  );
  var updated = content;
  // Replace backwards so that the earlier offsets stay valid.
  for (final match in matches.reversed) {
    final foundVersion = match.group(2)!;
    if (foundVersion != currentVersion) {
      throw ReleaseToolException(
        '$path references $packageName ^$foundVersion, expected '
        '^$currentVersion.',
      );
    }
    final versionStart = match.start + match.group(1)!.length;
    updated = updated.replaceRange(
      versionStart,
      versionStart + foundVersion.length,
      nextVersion,
    );
  }
  return updated;
}

void _readVersionReferences(
  String content, {
  required String path,
  required String packageName,
  required String expectedVersion,
  required VersionReferenceCount count,
}) {
  final matches = _versionReferenceMatches(
    content,
    path: path,
    packageName: packageName,
    count: count,
  );
  for (final match in matches) {
    final foundVersion = match.group(2)!;
    if (foundVersion != expectedVersion) {
      throw ReleaseToolException(
        '$path references $packageName ^$foundVersion, expected '
        '^$expectedVersion.',
      );
    }
  }
}

List<RegExpMatch> _versionReferenceMatches(
  String content, {
  required String path,
  required String packageName,
  required VersionReferenceCount count,
}) {
  final pattern = RegExp(
    '^([ \\t]*${RegExp.escape(packageName)}:[ \\t]*\\^)'
    r'([^ \t\r\n#]+)([ \t]*(?:#.*)?)$',
    multiLine: true,
  );
  final matches = pattern.allMatches(content).toList();
  count._check(matches.length, path: path, packageName: packageName);
  return matches;
}

String _replaceExampleLockVersion(
  String content, {
  required String path,
  required String packageName,
  required String currentVersion,
  required String nextVersion,
}) {
  final match = _exampleLockVersionMatch(
    content,
    path: path,
    packageName: packageName,
  );
  final foundVersion = match.group(2)!;
  if (foundVersion != currentVersion) {
    throw ReleaseToolException(
      '$path has $packageName version $foundVersion, expected $currentVersion.',
    );
  }
  final versionStart = match.start + match.group(1)!.length;
  return content.replaceRange(
    versionStart,
    versionStart + foundVersion.length,
    nextVersion,
  );
}

void _readExampleLockVersion(
  String content, {
  required String path,
  required String packageName,
  required String expectedVersion,
}) {
  final match = _exampleLockVersionMatch(
    content,
    path: path,
    packageName: packageName,
  );
  final foundVersion = match.group(2)!;
  if (foundVersion != expectedVersion) {
    throw ReleaseToolException(
      '$path has $packageName version $foundVersion, expected '
      '$expectedVersion.',
    );
  }
}

RegExpMatch _exampleLockVersionMatch(
  String content, {
  required String path,
  required String packageName,
}) {
  final pattern = RegExp(
    '^(  ${RegExp.escape(packageName)}:\\r?\\n'
    r'(?:    [^\r\n]*(?:\r?\n|$))*?'
    r'    source: path\r?\n'
    r'    version: ")([^"]+)"[ \t]*$',
    multiLine: true,
  );
  final matches = pattern.allMatches(content).toList();
  if (matches.length != 1) {
    throw ReleaseToolException(
      '$path must contain exactly one $packageName package entry '
      'with a version.',
    );
  }
  return matches.single;
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
          _datedHeadingSuffix.hasMatch(heading.group(0)!)) {
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
