///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import
// dart format off

import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:slang/generated.dart';
import 'strings.g.dart';

// Path: <root>
class TranslationsJa extends Translations with BaseTranslations<AppLocale, Translations> {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsJa({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  _meta = meta ?? TranslationMetadata(
		    locale: AppLocale.ja,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver) {
		_meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <ja>.
	final TranslationMetadata<AppLocale, Translations> _meta;
	@override TranslationMetadata<AppLocale, Translations> get $meta => _meta;

	/// Access flat map
	@override dynamic operator[](String key) => _meta.getTranslation(key) ?? super[key];

	late final TranslationsJa _root = this; // ignore: unused_field

	@override 
	TranslationsJa $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsJa(meta: meta ?? this.$meta);

	// Translations
	@override late final _Translations$nav$ja nav = _Translations$nav$ja._(_root);
	@override late final _Translations$common$ja common = _Translations$common$ja._(_root);
	@override late final _Translations$oauth$ja oauth = _Translations$oauth$ja._(_root);
	@override late final _Translations$miauth$ja miauth = _Translations$miauth$ja._(_root);
	@override late final _Translations$serverInfo$ja serverInfo = _Translations$serverInfo$ja._(_root);
	@override late final _Translations$accounts$ja accounts = _Translations$accounts$ja._(_root);
	@override late final _Translations$validation$ja validation = _Translations$validation$ja._(_root);
	@override late final _Translations$errors$ja errors = _Translations$errors$ja._(_root);
}

// Path: nav
class _Translations$nav$ja extends Translations$nav$en {
	_Translations$nav$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get serverInfo => 'サーバー情報';
	@override String get accounts => 'アカウント一覧';
}

// Path: common
class _Translations$common$ja extends Translations$common$en {
	_Translations$common$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get callbackScheme => 'コールバックスキーム';
	@override String get host => 'ホスト';
	@override String get customScopes => 'カスタムスコープ（カンマ区切り）';
	@override String example({required Object value}) => '例: ${value}';
}

// Path: oauth
class _Translations$oauth$ja extends Translations$oauth$en {
	_Translations$oauth$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get title => 'OAuth認証設定';
	@override String get clientId => 'クライアントID (URL)';
	@override String get redirectUri => 'リダイレクトURI';
	@override String get redirectUriHelper => 'client_idページの登録URLと完全一致（カスタムスキーム可）';
	@override String get submit => 'OAuthで認証';
	@override String get success => '認証に成功しました！';
	@override String failed({required Object error}) => '認証エラー: ${error}';
}

// Path: miauth
class _Translations$miauth$ja extends Translations$miauth$en {
	_Translations$miauth$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get title => 'MiAuth認証設定';
	@override String get appName => 'アプリ名';
	@override String get iconUrl => 'アイコンURL（任意）';
	@override String get submit => 'MiAuthで認証';
	@override String get success => 'MiAuth に成功しました！';
	@override String failed({required Object error}) => 'MiAuth エラー: ${error}';
}

// Path: serverInfo
class _Translations$serverInfo$ja extends Translations$serverInfo$en {
	_Translations$serverInfo$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get checkTitle => 'サーバー情報の確認';
	@override String get check => 'サーバー情報を確認';
	@override String get oauthNotSupported => 'OAuth認証はサポートされていません（MiAuth認証を使用してください）';
	@override String get title => 'サーバー情報';
	@override String get authorizationEndpoint => '認可エンドポイント';
	@override String get tokenEndpoint => 'トークンエンドポイント';
	@override String get scopesSupported => 'サポートされているスコープ（タップでコピー）';
	@override String copied({required Object scope}) => 'コピーしました: ${scope}';
}

// Path: accounts
class _Translations$accounts$ja extends Translations$accounts$en {
	_Translations$accounts$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get title => 'ログイン済みアカウント';
	@override String get reload => '再読込';
	@override String get loadFailed => 'アカウント情報を取得できませんでした';
	@override String get empty => 'ログイン済みのアカウントはありません';
	@override String savedAt({required Object date}) => '保存: ${date}';
	@override String get delete => 'このアカウントを削除';
	@override String activeChanged({required Object account}) => 'デフォルトを変更: ${account}';
}

// Path: validation
class _Translations$validation$ja extends Translations$validation$en {
	_Translations$validation$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get hostRequired => 'ホストを入力してください';
	@override String get callbackSchemeRequired => 'コールバックスキームを入力してください';
}

// Path: errors
class _Translations$errors$ja extends Translations$errors$en {
	_Translations$errors$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get userCancelled => '認証がキャンセルされました';
	@override String get callbackScheme => 'コールバックスキームの設定が正しくありません（AndroidManifest/Info.plist を確認してください）';
	@override String get authorizationLaunch => '認証画面を起動できませんでした';
	@override String get network => 'ネットワークエラーが発生しました';
	@override String get responseParse => 'サーバー応答の解析に失敗しました';
	@override String get secureStorage => 'セキュアストレージの操作に失敗しました';
	@override String get invalidAuthConfig => '認証設定が無効です';
	@override String get serverInfo => 'サーバー情報の取得に失敗しました';
	@override String get oauthNotSupported => 'このサーバーはOAuth認証に対応していません（MiAuthをご利用ください）';
	@override String get stateMismatch => 'セキュリティ検証に失敗しました（state不一致）';
	@override String get authorizationCodeMissing => '認証コードを取得できませんでした';
	@override String get authorizationServer => '認可サーバーでエラーが発生しました';
	@override String get tokenExchange => 'トークン交換に失敗しました';
	@override String get miAuthDenied => 'MiAuth がキャンセル/拒否されました';
	@override String get miAuthCheckFailed => 'MiAuth の検証に失敗しました';
	@override String get miAuthSessionInvalid => 'MiAuth のセッションが無効または期限切れです';
}

/// The flat map containing all translations for locale <ja>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsJa {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'nav.serverInfo' => 'サーバー情報',
			'nav.accounts' => 'アカウント一覧',
			'common.callbackScheme' => 'コールバックスキーム',
			'common.host' => 'ホスト',
			'common.customScopes' => 'カスタムスコープ（カンマ区切り）',
			'common.example' => ({required Object value}) => '例: ${value}',
			'oauth.title' => 'OAuth認証設定',
			'oauth.clientId' => 'クライアントID (URL)',
			'oauth.redirectUri' => 'リダイレクトURI',
			'oauth.redirectUriHelper' => 'client_idページの登録URLと完全一致（カスタムスキーム可）',
			'oauth.submit' => 'OAuthで認証',
			'oauth.success' => '認証に成功しました！',
			'oauth.failed' => ({required Object error}) => '認証エラー: ${error}',
			'miauth.title' => 'MiAuth認証設定',
			'miauth.appName' => 'アプリ名',
			'miauth.iconUrl' => 'アイコンURL（任意）',
			'miauth.submit' => 'MiAuthで認証',
			'miauth.success' => 'MiAuth に成功しました！',
			'miauth.failed' => ({required Object error}) => 'MiAuth エラー: ${error}',
			'serverInfo.checkTitle' => 'サーバー情報の確認',
			'serverInfo.check' => 'サーバー情報を確認',
			'serverInfo.oauthNotSupported' => 'OAuth認証はサポートされていません（MiAuth認証を使用してください）',
			'serverInfo.title' => 'サーバー情報',
			'serverInfo.authorizationEndpoint' => '認可エンドポイント',
			'serverInfo.tokenEndpoint' => 'トークンエンドポイント',
			'serverInfo.scopesSupported' => 'サポートされているスコープ（タップでコピー）',
			'serverInfo.copied' => ({required Object scope}) => 'コピーしました: ${scope}',
			'accounts.title' => 'ログイン済みアカウント',
			'accounts.reload' => '再読込',
			'accounts.loadFailed' => 'アカウント情報を取得できませんでした',
			'accounts.empty' => 'ログイン済みのアカウントはありません',
			'accounts.savedAt' => ({required Object date}) => '保存: ${date}',
			'accounts.delete' => 'このアカウントを削除',
			'accounts.activeChanged' => ({required Object account}) => 'デフォルトを変更: ${account}',
			'validation.hostRequired' => 'ホストを入力してください',
			'validation.callbackSchemeRequired' => 'コールバックスキームを入力してください',
			'errors.userCancelled' => '認証がキャンセルされました',
			'errors.callbackScheme' => 'コールバックスキームの設定が正しくありません（AndroidManifest/Info.plist を確認してください）',
			'errors.authorizationLaunch' => '認証画面を起動できませんでした',
			'errors.network' => 'ネットワークエラーが発生しました',
			'errors.responseParse' => 'サーバー応答の解析に失敗しました',
			'errors.secureStorage' => 'セキュアストレージの操作に失敗しました',
			'errors.invalidAuthConfig' => '認証設定が無効です',
			'errors.serverInfo' => 'サーバー情報の取得に失敗しました',
			'errors.oauthNotSupported' => 'このサーバーはOAuth認証に対応していません（MiAuthをご利用ください）',
			'errors.stateMismatch' => 'セキュリティ検証に失敗しました（state不一致）',
			'errors.authorizationCodeMissing' => '認証コードを取得できませんでした',
			'errors.authorizationServer' => '認可サーバーでエラーが発生しました',
			'errors.tokenExchange' => 'トークン交換に失敗しました',
			'errors.miAuthDenied' => 'MiAuth がキャンセル/拒否されました',
			'errors.miAuthCheckFailed' => 'MiAuth の検証に失敗しました',
			'errors.miAuthSessionInvalid' => 'MiAuth のセッションが無効または期限切れです',
			_ => null,
		};
	}
}
