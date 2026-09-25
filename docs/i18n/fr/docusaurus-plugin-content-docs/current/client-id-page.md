---
sidebar_position: 2
title: Page client_id
---

# Page client_id

OAuth 2.0 de Misskey suit la spécification IndieAuth. Au lieu d’enregistrer votre application sur chaque serveur, vous publiez une page Web et utilisez son URL comme `client_id`. Cette page n’est pas nécessaire pour MiAuth.

## Prérequis

- `client_id` doit être une URL HTTPS, telle que `https://yoursite/yourapp/`. Le serveur Misskey récupère cette page pendant l’autorisation.
- La page doit répertorier chaque `redirect_uri` de votre application dans une balise `<link>` :

  ```html
  <link rel="redirect_uri" href="yourscheme://oauth/callback">
  ```

- Le `redirect_uri` de la requête d’autorisation doit correspondre exactement à une URL d’une balise `<link>`, y compris le schéma, la casse et la barre oblique finale. Écrivez-le de la même façon aux deux endroits.
- `redirect_uri` n’a pas besoin d’utiliser HTTPS. Misskey exige HTTPS uniquement pour `client_id`, donc `redirect_uri` peut être l’URL de schéma personnalisé de votre application. Misskey redirige alors directement le navigateur vers l’application, par exemple vers `yourscheme://oauth/callback?code=...&state=...`.

## Exemple de page

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

Le bloc `h-app` indique à Misskey le nom de votre application. Misskey l’affiche sur l’écran d’autorisation.

Transmettez les mêmes valeurs à la bibliothèque :

```dart
MisskeyOAuthConfig(
  host: 'misskey.io',
  clientId: 'https://yoursite/yourapp/',
  redirectUri: 'yourscheme://oauth/callback',
  scope: 'read:account write:notes',
  callbackScheme: 'yourscheme',
)
```

Lorsque `redirectUri` utilise un schéma personnalisé, la bibliothèque attend ce schéma et ignore `callbackScheme`. Ce paramètre reste obligatoire.

## Facultatif : page relais HTTPS

Vous pouvez également utiliser une page HTTPS comme `redirect_uri` et transférer le résultat vers votre schéma personnalisé depuis cette page. Misskey ne l’exige pas. Si vous choisissez cette configuration :

- Répertoriez plutôt la page relais dans la balise `<link>`, par exemple `<link rel="redirect_uri" href="https://yoursite/yourapp/redirect.html">`.
- Définissez `redirectUri` sur l’URL de la page relais.
- Définissez `callbackScheme` sur le schéma vers lequel la page effectue le transfert.

```html
<!DOCTYPE html>
<html>
<head>
    <meta name="referrer" content="no-referrer">
</head>
<body>
    <script>
        // Ne transfère que les paramètres présents. Les erreurs contiennent également `state`.
        const source = new URLSearchParams(window.location.search);
        const forwarded = new URLSearchParams();
        for (const name of ['code', 'state', 'error', 'error_description', 'iss']) {
            // Transfère également les valeurs dupliquées afin que la bibliothèque puisse les rejeter.
            for (const value of source.getAll(name)) forwarded.append(name, value);
        }
        window.location.replace(`yourscheme://oauth/callback?${forwarded}`);
    </script>
</body>
</html>
```

- La bibliothèque vérifie `state` avant de lire `error` ; la page doit donc transférer `state` en cas de succès comme d’erreur.
- L’URL contient le code d’autorisation. Ne chargez pas de scripts tiers sur cette page.

## Erreurs courantes

- **`Invalid redirect_uri`** : le `redirect_uri` de la requête ne correspond exactement à aucune balise `<link rel="redirect_uri">` de la page client_id. Vérifiez le schéma, la casse du domaine et les barres obliques finales.
- **Le navigateur ne revient pas à l’application** : le schéma de `redirect_uri` (ou celui vers lequel la page relais transfère) n’est pas enregistré dans l’application. Consultez [Configuration des plateformes](./platform-setup.md).
