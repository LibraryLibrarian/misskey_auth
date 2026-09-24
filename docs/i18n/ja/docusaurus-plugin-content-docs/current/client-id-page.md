---
sidebar_position: 2
title: client_id ページ
---

# client_id ページ

Misskey の OAuth 2.0 は IndieAuth 仕様に準拠しています。サーバーごとにアプリを登録する代わりに、Web ページを公開して、その URL を `client_id` として使います。MiAuth ではこのページは不要です。

## 要件

- `client_id` は `https://yoursite/yourapp/` のような HTTPS の URL であること。Misskey サーバーは認可の際にこのページを取得します。
- ページに、アプリの各 `redirect_uri` を `<link>` タグで記載すること。

  ```html
  <link rel="redirect_uri" href="yourscheme://oauth/callback">
  ```

- 認可リクエストの `redirect_uri` が、`<link>` タグのいずれかの URL と完全一致すること（スキーム、大文字小文字、末尾スラッシュまで一致）。両方を同じ表記で書いてください。
- `redirect_uri` は HTTPS である必要はありません。Misskey が HTTPS を求めるのは `client_id` だけのため、`redirect_uri` にアプリのカスタムスキームの URL を指定できます。その場合、Misskey はブラウザを直接アプリへ戻します。

## ページの例

```html
<!DOCTYPE html>
<html>
<head>
  <title>My App</title>
  <link rel="redirect_uri" href="yourscheme://oauth/callback">
</head>
<body>
  <div class="h-app">
    <a href="https://yoursite/yourapp/" class="u-url p-name">Your Misskey App</a>
  </div>
</body>
</html>
```

`h-app` のブロックは、Misskey にアプリの名前を伝えます。Misskey はこの名前を認可画面に表示します。

ライブラリにも同じ値を渡します。

```dart
MisskeyOAuthConfig(
  host: 'misskey.io',
  clientId: 'https://yoursite/yourapp/',
  redirectUri: 'yourscheme://oauth/callback',
  scope: 'read:account write:notes',
  callbackScheme: 'yourscheme',
)
```

`redirectUri` がカスタムスキームの場合、ライブラリはそのスキームで戻るのを待ち、`callbackScheme` は使いません。ただし引数としては必須です。

## 任意: HTTPS の中継ページ

HTTPS のページを `redirect_uri` にし、そこからカスタムスキームへ転送する構成も使えます。Misskey の要件ではありません。この構成にする場合は、次のようにします。

- `<link>` タグには中継ページを記載します（例: `<link rel="redirect_uri" href="https://yoursite/yourapp/redirect.html">`）。
- `redirectUri` には中継ページの URL を指定します。
- `callbackScheme` には、中継ページの転送先のスキームを指定します。

```html
<!DOCTYPE html>
<html>
<head>
    <meta name="referrer" content="no-referrer">
</head>
<body>
    <script>
        // 存在するパラメータだけを転送する。エラー時にも `state` が付く
        const source = new URLSearchParams(window.location.search);
        const forwarded = new URLSearchParams();
        for (const name of ['code', 'state', 'error', 'error_description', 'iss']) {
            // 重複した値も落とさず渡し、ライブラリ側の重複拒否を効かせる
            for (const value of source.getAll(name)) forwarded.append(name, value);
        }
        window.location.replace(`yourscheme://oauth/callback?${forwarded}`);
    </script>
</body>
</html>
```

- ライブラリは `error` より先に `state` を照合するため、成功時とエラー時のどちらでも `state` を転送してください。
- URL に認可コードが含まれるため、このページで第三者のスクリプトを読み込まないでください。

## よくあるエラー

- **`Invalid redirect_uri`**: リクエストの `redirect_uri` が、client_id ページのどの `<link rel="redirect_uri">` とも完全一致していません。スキーム、ドメインの大文字小文字、末尾スラッシュを確認してください。
- **ブラウザがアプリに戻らない**: `redirect_uri` のスキーム（または中継ページの転送先のスキーム）がアプリに登録されていません。[プラットフォーム設定](./platform-setup.md)を参照してください。
