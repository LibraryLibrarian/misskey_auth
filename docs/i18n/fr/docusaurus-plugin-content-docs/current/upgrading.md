---
sidebar_position: 7
title: Mise à niveau
---

# Mise à niveau

## Prérequis

- Flutter 3.47.1 ou version ultérieure ; Dart 3.13.1 ou version ultérieure, avant Dart 4.
- Android API 24 ou version ultérieure et compileSdk 37 ou version ultérieure. L’exemple utilise AGP 9.1.1, Gradle 9.3.1 et Kotlin Gradle Plugin 2.3.20. AGP nécessite JDK 17 ou version ultérieure.
- iOS 15 ou version ultérieure. Harmonisez les versions minimales de Xcode et de Podfile. L’exemple inclut la migration Flutter vers UIScene et l’intégration de Swift Package Manager. Consultez le [guide de migration Flutter vers UIScene](https://docs.flutter.dev/release/breaking-changes/uiscenedelegate).

## Paramètres Gradle Android

Conservez `android.builtInKotlin=false` et `android.newDsl=false` tant que la version stable de `flutter_web_auth_2` applique le plugin Kotlin Android. Gardez ce plugin, mais remplacez `android.kotlinOptions` par `kotlin.compilerOptions` pour configurer sa cible JVM. Les futures versions de Flutter pourraient exiger la prise en charge de Kotlin intégré par les dépendances.

## Mise à niveau vers 0.2.0-beta.1

### Les utilisateurs Android doivent se reconnecter

Cette version met à niveau `flutter_secure_storage` de la version 9.x à la version 11.x sans étape de migration via la version 10.x. Sur Android, les identifiants chiffrés avec les anciennes valeurs par défaut ne peuvent pas être transférés directement ; les utilisateurs doivent s’authentifier à nouveau pour chaque compte concerné.

- Il s’agit d’une rupture de compatibilité des données de stockage sur Android. Cela n’implique pas la même perte de données sur iOS.
- Les applications hôtes doivent gérer les identifiants manquants et les erreurs de stockage.
- La suppression des identifiants locaux ne révoque pas les jetons côté serveur.

### Espace de stockage partagé

Le `SecureTokenStore` par défaut utilise l’espace de stockage par défaut partagé. La version 11 de `flutter_secure_storage` active `resetOnError` par défaut ; le rétablissement peut donc aussi supprimer d’autres valeurs dans cet espace. Vérifiez la configuration des espaces de stockage partagés avant la mise à niveau. Consultez le [journal des modifications de flutter_secure_storage](https://pub.dev/packages/flutter_secure_storage/changelog) et [Stockage des jetons](./token-storage.md#shared-storage).

Pour consulter toutes les modifications, voir le [journal des modifications](https://pub.dev/packages/misskey_auth/changelog).
