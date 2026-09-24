---
sidebar_position: 2
title: client_id Page
---

# client_id Page

Misskey's OAuth 2.0 follows the IndieAuth specification. Instead of registering your app on each server, you publish a web page and use its URL as `client_id`. MiAuth does not need this page.

## Requirements

- `client_id` must be an HTTPS URL, such as `https://yoursite/yourapp/`. The Misskey server fetches this page during authorization.
- The page must list each `redirect_uri` of your app in a `<link>` tag:

  ```html
  <link rel="redirect_uri" href="yourscheme://oauth/callback">
  ```

- The `redirect_uri` in the authorization request must exactly match a URL in a `<link>` tag, including the scheme, letter case, and trailing slash. Write it the same way in both places.
- `redirect_uri` does not need to be HTTPS. Misskey requires HTTPS only for `client_id`, so `redirect_uri` can be your app's custom scheme URL. Misskey then redirects the browser straight back to your app.

## Example Page

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

The `h-app` block tells Misskey the name of your app. Misskey shows it on the authorization screen.

Pass the same values to the library:

```dart
MisskeyOAuthConfig(
  host: 'misskey.io',
  clientId: 'https://yoursite/yourapp/',
  redirectUri: 'yourscheme://oauth/callback',
  scope: 'read:account write:notes',
  callbackScheme: 'yourscheme',
)
```

When `redirectUri` uses a custom scheme, the library waits for that scheme and ignores `callbackScheme`. The parameter is still required.

## Optional: HTTPS Relay Page

You can also use an HTTPS page as `redirect_uri` and forward the result to your custom scheme from there. Misskey does not require this. If you use it:

- List the relay page in the `<link>` tag instead, for example `<link rel="redirect_uri" href="https://yoursite/yourapp/redirect.html">`.
- Set `redirectUri` to the relay page URL.
- Set `callbackScheme` to the scheme that the page forwards to.

```html
<!DOCTYPE html>
<html>
<head>
    <meta name="referrer" content="no-referrer">
</head>
<body>
    <script>
        // Forward only the parameters that are present. Errors carry `state` too.
        const source = new URLSearchParams(window.location.search);
        const forwarded = new URLSearchParams();
        for (const name of ['code', 'state', 'error', 'error_description', 'iss']) {
            // Keep duplicated values so that the library can reject them
            for (const value of source.getAll(name)) forwarded.append(name, value);
        }
        window.location.replace(`yourscheme://oauth/callback?${forwarded}`);
    </script>
</body>
</html>
```

- The library verifies `state` before it reads `error`, so the page must forward `state` on both success and error.
- The URL contains the authorization code. Do not load third-party scripts on this page.

## Common Errors

- **`Invalid redirect_uri`**: the `redirect_uri` in the request does not exactly match any `<link rel="redirect_uri">` on the client_id page. Check the scheme, the letter case of the domain, and trailing slashes.
- **The browser does not return to the app**: the scheme of `redirect_uri` (or the scheme the relay page forwards to) is not registered in the app. See [Platform Setup](./platform-setup.md).
