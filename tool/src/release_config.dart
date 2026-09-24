import 'release_project.dart';

/// Release settings for this repository.
///
/// `release_project.dart` is shared verbatim across the packages that use this
/// tool. Everything specific to this repository belongs here instead.
const releaseConfig = ReleaseConfig(
  versionReferencePaths: <String>[
    'README.md',
    'README.ja.md',
    'README.de.md',
    'README.fr.md',
    'README.ko.md',
    'README.zh-Hans.md',
    'docs/docs/getting-started.md',
    'docs/i18n/ja/docusaurus-plugin-content-docs/current/getting-started.md',
  ],
);
