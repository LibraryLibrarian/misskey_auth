---
sidebar_position: 2
title: client_id-Seite
---

# client_id-Seite

Misskeys OAuth 2.0 entspricht der IndieAuth-Spezifikation. Statt eine App auf jedem Server zu registrieren, veröffentlichen Sie eine Webseite und verwenden deren URL als `client_id`. Für MiAuth ist diese Seite nicht erforderlich.

## Anforderungen

- `client_id` muss eine HTTPS-URL wie `https://yoursite/yourapp/` sein. Der Misskey-Server ruft diese Seite während der Autorisierung ab.
- Tragen Sie jede `redirect_uri` der App mit einem `<link>`-Tag auf der Seite ein.

  ```html
  <link rel="redirect_uri" href="yourscheme://oauth/callback">
  ```

- Die `redirect_uri` der Autorisierungsanfrage muss exakt mit einer der URLs der `<link>`-Tags übereinstimmen (einschließlich Schema, Groß-/Kleinschreibung und abschließendem Schrägstrich). Verwenden Sie in beiden Fällen dieselbe Schreibweise.
- `redirect_uri` muss nicht HTTPS verwenden. Nur für `client_id` verlangt Misskey HTTPS. Sie können daher als `redirect_uri` eine URL mit dem benutzerdefinierten Schema der App angeben. In diesem Fall leitet Misskey den Browser direkt zur App zurück (Beispiel: `yourscheme://oauth/callback?code=...&state=...`).

## Beispielseite

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

Der `h-app`-Block teilt Misskey den Namen der App mit. Misskey zeigt diesen Namen auf dem Autorisierungsbildschirm an.

Übergeben Sie denselben Wert auch an die Bibliothek.

```dart
MisskeyOAuthConfig(
  host: 'misskey.io',
  clientId: 'https://yoursite/yourapp/',
  redirectUri: 'yourscheme://oauth/callback',
  scope: 'read:account write:notes',
  callbackScheme: 'yourscheme',
)
```

Wenn `redirectUri` ein benutzerdefiniertes Schema verwendet, wartet die Bibliothek auf die Rückkehr über dieses Schema und verwendet `callbackScheme` nicht. Das Argument ist dennoch erforderlich.

## Optional: HTTPS-Zwischenseite

Sie können auch eine HTTPS-Seite als `redirect_uri` verwenden, die anschließend zur benutzerdefinierten URL weiterleitet. Dies ist keine Anforderung von Misskey. Wenn Sie diese Variante wählen, gehen Sie wie folgt vor.

- Geben Sie im `<link>`-Tag die Zwischenseite an (Beispiel: `<link rel="redirect_uri" href="https://yoursite/yourapp/redirect.html">`).
- Geben Sie als `redirectUri` die URL der Zwischenseite an.
- Geben Sie als `callbackScheme` das Schema des Weiterleitungsziels der Zwischenseite an.

Beispiel für `redirect.html`.

```html
<!DOCTYPE html>
<html>
<head>
    <meta name="referrer" content="no-referrer">
</head>
<body>
    <script>
        // Nur vorhandene Parameter weiterleiten; `state` ist auch bei Fehlern enthalten
        const source = new URLSearchParams(window.location.search);
        const forwarded = new URLSearchParams();
        for (const name of ['code', 'state', 'error', 'error_description', 'iss']) {
            // Doppelte Werte beibehalten, damit die Bibliothek sie zurückweisen kann
            for (const value of source.getAll(name)) forwarded.append(name, value);
        }
        window.location.replace(`yourscheme://oauth/callback?${forwarded}`);
    </script>
</body>
</html>
```

- Die Bibliothek überprüft `state` vor `error`. Leiten Sie `state` daher sowohl bei Erfolg als auch bei Fehlern weiter.
- Laden Sie auf dieser Seite keine Skripte von Drittanbietern, da die URL den Autorisierungscode enthält.

## Häufige Fehler

- **`Invalid redirect_uri`**: Die `redirect_uri` der Anfrage stimmt nicht exakt mit einem der `<link rel="redirect_uri">`-Tags auf der client_id-Seite überein. Prüfen Sie Schema, Groß-/Kleinschreibung des Domainnamens und abschließenden Schrägstrich.
- **Der Browser kehrt nicht zur App zurück**: Das Schema der `redirect_uri` (oder das Schema des Weiterleitungsziels der Zwischenseite) ist nicht in der App registriert. Weitere Informationen finden Sie unter [Plattformkonfiguration](./platform-setup.md).
