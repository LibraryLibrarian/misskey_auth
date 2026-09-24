---
sidebar_position: 2
title: client_id 페이지
---

# client_id 페이지

Misskey의 OAuth 2.0은 IndieAuth 사양을 따릅니다. 서버마다 앱을 등록하는 대신 웹 페이지를 게시하고 해당 URL을 `client_id`로 사용합니다. MiAuth에는 이 페이지가 필요하지 않습니다.

## 요구 사항

- `client_id`는 `https://yoursite/yourapp/`와 같은 HTTPS URL이어야 합니다. Misskey 서버는 인증 과정에서 이 페이지를 가져옵니다.
- 페이지에 앱의 각 `redirect_uri`를 `<link>` 태그로 나열해야 합니다.

  ```html
  <link rel="redirect_uri" href="yourscheme://oauth/callback">
  ```

- 인증 요청의 `redirect_uri`는 `<link>` 태그에 있는 URL과 스킴, 대소문자, 끝의 슬래시까지 완전히 일치해야 합니다. 두 위치에 같은 형식으로 작성하세요.
- `redirect_uri`는 HTTPS일 필요가 없습니다. Misskey는 `client_id`에만 HTTPS를 요구하므로, `redirect_uri`에 앱의 사용자 지정 스킴 URL을 지정할 수 있습니다. 이 경우 Misskey는 브라우저를 앱으로 바로 리디렉션합니다(예: `yourscheme://oauth/callback?code=...&state=...`).

## 페이지 예제

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

`h-app` 블록은 앱 이름을 Misskey에 전달합니다. Misskey는 인증 화면에 이 이름을 표시합니다.

라이브러리에도 같은 값을 전달합니다.

```dart
MisskeyOAuthConfig(
  host: 'misskey.io',
  clientId: 'https://yoursite/yourapp/',
  redirectUri: 'yourscheme://oauth/callback',
  scope: 'read:account write:notes',
  callbackScheme: 'yourscheme',
)
```

`redirectUri`에 사용자 지정 스킴을 사용하면 라이브러리는 해당 스킴으로 돌아오기를 기다리며 `callbackScheme`은 사용하지 않습니다. 하지만 이 매개변수는 필수입니다.

## 선택 사항: HTTPS 중계 페이지

`redirect_uri`에 HTTPS 페이지를 사용하고, 해당 페이지에서 사용자 지정 스킴으로 전달할 수도 있습니다. Misskey가 요구하는 구성은 아닙니다. 이 구성을 사용하는 경우 다음과 같이 설정합니다.

- `<link>` 태그에는 중계 페이지를 나열합니다(예: `<link rel="redirect_uri" href="https://yoursite/yourapp/redirect.html">`).
- `redirectUri`에는 중계 페이지 URL을 지정합니다.
- `callbackScheme`에는 페이지가 전달할 대상 스킴을 지정합니다.

```html
<!DOCTYPE html>
<html>
<head>
    <meta name="referrer" content="no-referrer">
</head>
<body>
    <script>
        // 존재하는 매개변수만 전달합니다. 오류 응답에도 `state`가 포함됩니다.
        const source = new URLSearchParams(window.location.search);
        const forwarded = new URLSearchParams();
        for (const name of ['code', 'state', 'error', 'error_description', 'iss']) {
            // 라이브러리가 중복을 거부할 수 있도록 중복 값도 그대로 전달합니다.
            for (const value of source.getAll(name)) forwarded.append(name, value);
        }
        window.location.replace(`yourscheme://oauth/callback?${forwarded}`);
    </script>
</body>
</html>
```

- 라이브러리는 `error`를 읽기 전에 `state`를 확인하므로, 성공과 오류 모두에서 페이지가 `state`를 전달해야 합니다.
- URL에 인증 코드가 포함됩니다. 이 페이지에서 서드파티 스크립트를 불러오지 마세요.

## 일반적인 오류

- **`Invalid redirect_uri`**: 요청의 `redirect_uri`가 client_id 페이지의 `<link rel="redirect_uri">`와 완전히 일치하지 않습니다. 스킴, 도메인의 대소문자, 끝의 슬래시를 확인하세요.
- **브라우저가 앱으로 돌아오지 않음**: `redirect_uri`의 스킴(또는 중계 페이지가 전달하는 대상 스킴)이 앱에 등록되어 있지 않습니다. [플랫폼 설정](./platform-setup.md)을 참조하세요.
