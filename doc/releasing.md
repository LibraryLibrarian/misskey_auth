# リリース手順

misskey_clientと同じく、準備PR → mainへのマージ → タグ → pub.dev公開 → GitHub Release → developへの反映の順で進めます。Flutter 3.47.1を使用します。

## 設定

- GitHub App: 対象リポジトリへのContents／Pull requestsの読み書き権限。
- Actions変数: `RELEASE_APP_CLIENT_ID`。
- Actions Secret: `RELEASE_APP_PRIVATE_KEY`。
- Environment: `pub.dev`。公開前の承認者を設定します。
- pub.dev: リポジトリ`LibraryLibrarian/misskey_auth`、タグ`v{{version}}`、pushイベント、Environment `pub.dev`を指定します。
- mainの必須CIチェック: `all checks passed`。

## 通常のリリース

1. developのCI成功を確認し、CHANGELOGの`Unreleased`に利用者向けの変更内容を記載します。
2. Actionsの`Prepare Release`をdevelopから起動し、未公開のバージョンを入力します。例: `0.1.5-beta.1`。
3. 生成されたmain向けPRを確認します。pubspec、READMEの英語・日本語の2箇所、CHANGELOGの日付付き見出しが更新され、実行者がAssigneeになります。
4. PRのCI成功後にマージします。`Tag Release`がバージョンタグを作成します。同名タグが存在する場合は何もしません。
5. `Publish to pub.dev`の検証成功後、`pub.dev` Environmentの公開を承認します。
6. pub.devへの公開、CHANGELOGからのGitHub Release作成、developへのマージバックを確認します。プレリリースはGitHubでもPre-releaseとして作成されます。

初回は自動化コードを先にdevelopへ取り込んでください。mainへの初回導入時は現在のバージョンタグが既にあればタグ作成はスキップされます。mainへのpush自体はリリース起点になるため、バージョン変更を含むマージは公開の意図を確認して実施してください。

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

- 準備失敗: バージョン形式、READMEの2箇所、CHANGELOGの見出しと内容、同名ブランチの有無を確認します。既存ブランチは自動で上書きしません。
- 公開前検証失敗: タグがmainに含まれること、各ファイルのバージョンとCHANGELOGの日付・本文を確認します。
- 承認待ち: `pub.dev` Environmentの承認待ちはエラーではありません。
- 公開失敗: pub.devで対象バージョンが公開済みか確認します。既に公開済みならpublishジョブを再実行しないでください。公開済みバージョンは再公開できません。
- Release作成／マージバック失敗: GitHub Actionsの「失敗したジョブを再実行」を使い、成功済みの公開ジョブを再実行しません。既存のGitHub Releaseは作成をスキップします。
- マージバックで競合またはブランチ保護に抵触した場合: `chore/merge-back-v<version>`のPRを確認し、必要な解決・CI確認後にdevelopへマージします。自動復旧できなかったことが分かるようジョブは失敗扱いになります。

Secret登録と公開条件の設定だけでは認証成功の証明にはなりません。GitHub AppによるPR／タグ作成とOIDCによる本番公開は、実際のリリースで別途確認します。
