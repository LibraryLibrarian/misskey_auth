---
sidebar_position: 2
title: client_id 页面
---

# client_id 页面

Misskey 的 OAuth 2.0 遵循 IndieAuth 规范。无需在每个服务器上注册应用，只需发布一个网页并将其 URL 用作 `client_id`。MiAuth 不需要此页面。

## 要求

- `client_id` 必须是 HTTPS URL，例如 `https://yoursite/yourapp/`。Misskey 服务器会在授权期间获取此页面。
- 页面必须在 `<link>` 标签中列出应用的每个 `redirect_uri`：

  ```html
  <link rel="redirect_uri" href="yourscheme://oauth/callback">
  ```

- 授权请求中的 `redirect_uri` 必须与某个 `<link>` 标签中的 URL 完全一致，包括 scheme、大小写和末尾斜杠。两处必须使用相同的写法。
- `redirect_uri` 无需使用 HTTPS。Misskey 只要求 `client_id` 使用 HTTPS，因此 `redirect_uri` 可以是应用的自定义 scheme URL。此时 Misskey 会将浏览器直接重定向回应用，例如 `yourscheme://oauth/callback?code=...&state=...`。

## 页面示例

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

`h-app` 区块会告知 Misskey 应用名称。Misskey 会在授权页面上显示此名称。

将相同的值传递给库：

```dart
MisskeyOAuthConfig(
  host: 'misskey.io',
  clientId: 'https://yoursite/yourapp/',
  redirectUri: 'yourscheme://oauth/callback',
  scope: 'read:account write:notes',
  callbackScheme: 'yourscheme',
)
```

当 `redirectUri` 使用自定义 scheme 时，库会等待该 scheme 的回调，并忽略 `callbackScheme`。但此参数仍为必需。

## 可选：HTTPS 中继页面

也可以将 HTTPS 页面用作 `redirect_uri`，然后从该页面转发到自定义 scheme。Misskey 并不要求这样做。如需采用这种方式：

- 在 `<link>` 标签中列出中继页面，例如 `<link rel="redirect_uri" href="https://yoursite/yourapp/redirect.html">`。
- 将中继页面 URL 设为 `redirectUri`。
- 将页面转发到的 scheme 设为 `callbackScheme`。

```html
<!DOCTYPE html>
<html>
<head>
    <meta name="referrer" content="no-referrer">
</head>
<body>
    <script>
        // 仅转发存在的参数。错误时也会带有 `state`。
        const source = new URLSearchParams(window.location.search);
        const forwarded = new URLSearchParams();
        for (const name of ['code', 'state', 'error', 'error_description', 'iss']) {
            // 保留并转发重复值，以便库能够拒绝它们
            for (const value of source.getAll(name)) forwarded.append(name, value);
        }
        window.location.replace(`yourscheme://oauth/callback?${forwarded}`);
    </script>
</body>
</html>
```

- 库会先验证 `state`，再读取 `error`，因此成功和失败时页面都必须转发 `state`。
- URL 中包含授权码。请勿在此页面加载第三方脚本。

## 常见错误

- **`Invalid redirect_uri`**：请求中的 `redirect_uri` 与 client_id 页面上的任何 `<link rel="redirect_uri">` 都不完全匹配。请检查 scheme、域名的大小写和末尾斜杠。
- **浏览器未返回应用**：`redirect_uri` 的 scheme（或中继页面转发到的 scheme）未在应用中注册。请参阅[平台配置](./platform-setup.md)。
