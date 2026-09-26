# リリース手順

misskey_clientと同じく、準備PR → mainへのマージ → タグ → pub.dev公開 → GitHub Release → developへの反映の順で進めます。Flutter 3.47.1を使用します。

## 設定

- GitHub App: 対象リポジトリへのContents／Pull requestsの読み書き権限。
- Actions変数: `RELEASE_APP_CLIENT_ID`。
- Actions Secret: `RELEASE_APP_PRIVATE_KEY`。
- Environment: `pub.dev`。承認者は設定しません。Environment名はOIDCトークンに署名されるため、push権限を持つ者がワークフローを書き換えて公開経路を迂回することを防ぎます。削除すると公開自体が失敗します。
- pub.dev: リポジトリ`LibraryLibrarian/misskey_auth`、タグ`v{{version}}`、pushイベント、Environment `pub.dev`を指定します。
- mainの必須CIチェック: `all checks passed`。

## 通常のリリース

1. developのCI成功を確認し、CHANGELOGの`Unreleased`に利用者向けの変更内容を記載します。
2. Actionsの`Prepare Release`をdevelopから起動し、チャンネルを選びます。通常のリリースは`beta`、プレリリース列を正式版へ昇格する場合は`stable`です。バージョンは`CHANGELOG.md`の`[Unreleased]`から算出されるため入力しません。算出結果を使わない場合だけ`version`を入力します。

   算出規則は次のとおりです。コミットメッセージは参照しません。このプロジェクトの履歴では破壊的変更が`docs:`や`build:`として記録されていた実績があるためです。

   - `### Breaking changes`見出し、`**Breaking:**`、`**BREAKING**:`のいずれかがあればメジャーを上げます。ただしメジャーが`0`の間はマイナーを上げます
   - なければ内容のある`### Added`があればマイナーを上げます
   - どちらでもなければパッチを上げます
   - 影響度は直近の安定版以降に公開した全プレリリースから積み上げます。開いている列に修正だけを足してもコアは動かず、ベータ番号だけが進みます
   - `[Unreleased]`が空の場合、`beta`ではエラーになります。`stable`は昇格なので許容されます
   - 見出しだけで項目がない場合も空として扱います
   - 中身のない`### Breaking changes`見出しはメジャーを上げません。コードブロックの中の記述も判定に使いません
   - 安定版を一度も公開していない場合、コアは動きません。いま組んでいる列が目標そのものなので、破壊的変更が入ってもベータ番号だけが進みます
3. 生成されたmain向けPRを確認します。pubspec、言語別のREADMEとドキュメントサイトの`getting-started.md`のインストール例（`tool/src/release_config.dart`の一覧）、CHANGELOGの日付付き見出しが更新され、実行者がAssigneeになります。
4. PRのCI成功後にマージします。**このマージが公開の起点です。**以降は人の操作を挟まず、タグ作成からpub.dev公開まで自動で進みます。
5. pub.devへの公開、CHANGELOGからのGitHub Release作成、developへのマージバックを確認します。プレリリースはGitHubでもPre-releaseとして作成されます。

リリースPRが開いている間は、develop側で`CHANGELOG.md`の`[Unreleased]`を編集しないでください。リリースPRは`[Unreleased]`の直下に新しい見出しを挿入するため、同じ位置への追記は公開後のマージバックで必ず競合します。

初回は自動化コードを先にdevelopへ取り込んでください。

`Tag Release`はmainへのpushごとに起動しますが、タグを作成するのは次の3条件をすべて満たす場合だけです。

1. 同名タグが存在しない。存在する場合、そのタグがmainから到達できるなら公開済みとして何もせず終了します。バージョンを変更しない通常のmain更新はここで終わります。main上にないタグを指している場合は失敗します。タグは自動では移動しません
2. `pubspec.yaml`を最後に変更したコミットの件名が`chore(release): <version>`である。手でバージョンを書き換えたマージからは公開されません
3. そのコミットがmainを対象とするマージ済みPRに含まれている。必須チェック`all checks passed`はPRに対して強制されるため、PRを一度も経ていない直接pushを弾けます。PRのマージコミットそのものであることまでは保証しません

## プレリリースから正式版への昇格

`0.2.0-beta.1`のようなプレリリースを`0.2.0`として公開する場合も、手順は通常のリリースと同じです。`Prepare Release`のチャンネルに`stable`を選んでください。バージョンは直近の安定版に影響度を適用して決まります。開いているプレリリース列に後から破壊的変更が入った場合は、列のコアより大きい値になります。

このとき`tool/bump_version.dart`は昇格モードで動作します。

- `[Unreleased]`の内容と、直近の安定版より後の全プレリリース（`0.2.0-beta.1`など）の内容を、カテゴリ別に統合して`## [0.2.0]`に書き出します
- カテゴリの順序は`Breaking changes` / `Added` / `Changed` / `Deprecated` / `Removed` / `Fixed` / `Security`、その他は初出順です。カテゴリ内は古い順に並びます
- 完全に同一の行は重複排除されます
- 統合されたプレリリースの見出しと日付は残り、本文は`Included in [0.2.0].`に置き換わります

統合結果は機械的な連結なので、**リリースPRの段階で推敲してください**。ベータ期間中に入れて後から変更した項目は、正式版の利用者にとっては1行で足ります。pub.devの既定の依存解決はプレリリースを拾わないため、大半の利用者にとって昇格版が最初に読むCHANGELOGになります。

なお`bump_version.dart`は、指定バージョンが現在のバージョンおよびCHANGELOG上の既存リリースより小さい場合を拒否します。比較はSemVer 2.0.0の優先順位規則に従います。

## ローカル検証

FVMを使用する場合:

```sh
fvm flutter test test/tool/release_project_test.dart
fvm dart analyze --fatal-infos
fvm dart tool/print_version.dart
fvm flutter pub publish --dry-run
```

`fvm dart tool/bump_version.dart <version>`はファイルを書き換えます。確認用コピーで実行し、`fvm dart tool/verify_release.dart <version>`と`fvm dart tool/release_notes.dart <version>`で結果を検証してください。

## 失敗時

- 準備失敗: バージョン形式、バージョンが後退していないか、`tool/src/release_config.dart`に並べた各ファイルのインストール例、CHANGELOGの見出しと内容、同名ブランチの有無を確認します。既存ブランチは自動で上書きしません。
- タグ作成失敗: 上記「通常のリリース」末尾の3条件のどれを満たしていないかがログに出ます。既存タグとmainの不一致は自動復旧しません。
- 公開前検証失敗: タグがmainに含まれること、各ファイルのバージョンとCHANGELOGの日付・本文を確認します。`pub publish --dry-run`の警告が1件でもあれば公開前に停止します。`--force`は確認を省略するだけで警告を消しません。
- 公開失敗: pub.devで対象バージョンが公開済みか確認します。既に公開済みならpublishジョブを再実行しないでください。公開済みバージョンは再公開できません。
- Release作成／マージバック失敗: GitHub Actionsの「失敗したジョブを再実行」を使い、成功済みの公開ジョブを再実行しません。既存のGitHub Releaseは作成をスキップします。
- マージバックで競合またはブランチ保護に抵触した場合: `chore/merge-back-v<version>`のPRを確認し、必要な解決・CI確認後にdevelopへマージします。自動復旧できなかったことが分かるようジョブは失敗扱いになります。

Secret登録と公開条件の設定だけでは認証成功の証明にはなりません。GitHub AppによるPR／タグ作成とOIDCによる本番公開は、実際のリリースで別途確認します。
