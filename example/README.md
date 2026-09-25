# misskey_auth_example

An example app for `misskey_auth` that signs in with OAuth or MiAuth.

## Running

The UI text is localized with [slang](https://pub.dev/packages/slang). The generated Dart files are not checked in, so generate them before running the app:

```sh
flutter pub get
dart run build_runner build
flutter run
```

Run `dart run build_runner build` again after editing the translation files in `lib/i18n/`.

## Languages

The app follows the device language: English, Japanese, Simplified Chinese, German, French and Korean. Other languages fall back to English.
