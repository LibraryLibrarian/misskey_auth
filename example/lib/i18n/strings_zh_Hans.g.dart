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
class TranslationsZhHans extends Translations with BaseTranslations<AppLocale, Translations> {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsZhHans({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  _meta = meta ?? TranslationMetadata(
		    locale: AppLocale.zhHans,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver) {
		_meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <zh-Hans>.
	final TranslationMetadata<AppLocale, Translations> _meta;
	@override TranslationMetadata<AppLocale, Translations> get $meta => _meta;

	/// Access flat map
	@override dynamic operator[](String key) => _meta.getTranslation(key) ?? super[key];

	late final TranslationsZhHans _root = this; // ignore: unused_field

	@override 
	TranslationsZhHans $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsZhHans(meta: meta ?? this.$meta);

	// Translations
	@override late final _Translations$nav$zh_Hans nav = _Translations$nav$zh_Hans._(_root);
	@override late final _Translations$common$zh_Hans common = _Translations$common$zh_Hans._(_root);
	@override late final _Translations$oauth$zh_Hans oauth = _Translations$oauth$zh_Hans._(_root);
	@override late final _Translations$miauth$zh_Hans miauth = _Translations$miauth$zh_Hans._(_root);
	@override late final _Translations$serverInfo$zh_Hans serverInfo = _Translations$serverInfo$zh_Hans._(_root);
	@override late final _Translations$accounts$zh_Hans accounts = _Translations$accounts$zh_Hans._(_root);
	@override late final _Translations$validation$zh_Hans validation = _Translations$validation$zh_Hans._(_root);
	@override late final _Translations$errors$zh_Hans errors = _Translations$errors$zh_Hans._(_root);
}

// Path: nav
class _Translations$nav$zh_Hans extends Translations$nav$en {
	_Translations$nav$zh_Hans._(TranslationsZhHans root) : this._root = root, super.internal(root);

	final TranslationsZhHans _root; // ignore: unused_field

	// Translations
	@override String get serverInfo => '服务器信息';
	@override String get accounts => '账号';
}

// Path: common
class _Translations$common$zh_Hans extends Translations$common$en {
	_Translations$common$zh_Hans._(TranslationsZhHans root) : this._root = root, super.internal(root);

	final TranslationsZhHans _root; // ignore: unused_field

	// Translations
	@override String get callbackScheme => '回调 scheme';
	@override String get host => '主机';
	@override String get customScopes => '自定义作用域（逗号分隔）';
	@override String example({required Object value}) => '例如：${value}';
}

// Path: oauth
class _Translations$oauth$zh_Hans extends Translations$oauth$en {
	_Translations$oauth$zh_Hans._(TranslationsZhHans root) : this._root = root, super.internal(root);

	final TranslationsZhHans _root; // ignore: unused_field

	// Translations
	@override String get title => 'OAuth 设置';
	@override String get clientId => '客户端 ID（URL）';
	@override String get redirectUri => '重定向 URI';
	@override String get redirectUriHelper => '必须与 client_id 页面中登记的 URL 完全一致（可以使用自定义 scheme）';
	@override String get submit => '使用 OAuth 登录';
	@override String get success => '登录成功！';
	@override String failed({required Object error}) => '身份验证错误：${error}';
}

// Path: miauth
class _Translations$miauth$zh_Hans extends Translations$miauth$en {
	_Translations$miauth$zh_Hans._(TranslationsZhHans root) : this._root = root, super.internal(root);

	final TranslationsZhHans _root; // ignore: unused_field

	// Translations
	@override String get title => 'MiAuth 设置';
	@override String get appName => '应用名称';
	@override String get iconUrl => '图标 URL（可选）';
	@override String get submit => '使用 MiAuth 登录';
	@override String get success => 'MiAuth 登录成功！';
	@override String failed({required Object error}) => 'MiAuth 错误：${error}';
}

// Path: serverInfo
class _Translations$serverInfo$zh_Hans extends Translations$serverInfo$en {
	_Translations$serverInfo$zh_Hans._(TranslationsZhHans root) : this._root = root, super.internal(root);

	final TranslationsZhHans _root; // ignore: unused_field

	// Translations
	@override String get checkTitle => '查看服务器信息';
	@override String get check => '查看服务器信息';
	@override String get oauthNotSupported => '此服务器不支持 OAuth（请改用 MiAuth）';
	@override String get title => '服务器信息';
	@override String get authorizationEndpoint => '授权端点';
	@override String get tokenEndpoint => '令牌端点';
	@override String get scopesSupported => '支持的作用域（点击复制）';
	@override String copied({required Object scope}) => '已复制：${scope}';
}

// Path: accounts
class _Translations$accounts$zh_Hans extends Translations$accounts$en {
	_Translations$accounts$zh_Hans._(TranslationsZhHans root) : this._root = root, super.internal(root);

	final TranslationsZhHans _root; // ignore: unused_field

	// Translations
	@override String get title => '已登录的账号';
	@override String get reload => '重新加载';
	@override String get loadFailed => '无法获取账号信息';
	@override String get empty => '没有已登录的账号';
	@override String savedAt({required Object date}) => '保存时间：${date}';
	@override String get delete => '删除此账号';
	@override String activeChanged({required Object account}) => '已更改活动账号：${account}';
}

// Path: validation
class _Translations$validation$zh_Hans extends Translations$validation$en {
	_Translations$validation$zh_Hans._(TranslationsZhHans root) : this._root = root, super.internal(root);

	final TranslationsZhHans _root; // ignore: unused_field

	// Translations
	@override String get hostRequired => '请输入主机';
	@override String get callbackSchemeRequired => '请输入回调 scheme';
}

// Path: errors
class _Translations$errors$zh_Hans extends Translations$errors$en {
	_Translations$errors$zh_Hans._(TranslationsZhHans root) : this._root = root, super.internal(root);

	final TranslationsZhHans _root; // ignore: unused_field

	// Translations
	@override String get userCancelled => '身份验证已取消';
	@override String get callbackScheme => '回调 scheme 配置不正确（请检查 AndroidManifest.xml / Info.plist）';
	@override String get authorizationLaunch => '无法打开身份验证页面';
	@override String get network => '发生网络错误';
	@override String get responseParse => '无法解析服务器响应';
	@override String get secureStorage => '安全存储操作失败';
	@override String get invalidAuthConfig => '身份验证设置无效';
	@override String get serverInfo => '无法获取服务器信息';
	@override String get oauthNotSupported => '此服务器不支持 OAuth（请改用 MiAuth）';
	@override String get stateMismatch => '安全验证失败（state 不匹配）';
	@override String get authorizationCodeMissing => '无法获取授权码';
	@override String get authorizationServer => '授权服务器返回了错误';
	@override String get tokenExchange => '令牌交换失败';
	@override String get miAuthDenied => 'MiAuth 已取消或被拒绝';
	@override String get miAuthCheckFailed => 'MiAuth 验证失败';
	@override String get miAuthSessionInvalid => 'MiAuth 会话无效或已过期';
}

/// The flat map containing all translations for locale <zh-Hans>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsZhHans {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'nav.serverInfo' => '服务器信息',
			'nav.accounts' => '账号',
			'common.callbackScheme' => '回调 scheme',
			'common.host' => '主机',
			'common.customScopes' => '自定义作用域（逗号分隔）',
			'common.example' => ({required Object value}) => '例如：${value}',
			'oauth.title' => 'OAuth 设置',
			'oauth.clientId' => '客户端 ID（URL）',
			'oauth.redirectUri' => '重定向 URI',
			'oauth.redirectUriHelper' => '必须与 client_id 页面中登记的 URL 完全一致（可以使用自定义 scheme）',
			'oauth.submit' => '使用 OAuth 登录',
			'oauth.success' => '登录成功！',
			'oauth.failed' => ({required Object error}) => '身份验证错误：${error}',
			'miauth.title' => 'MiAuth 设置',
			'miauth.appName' => '应用名称',
			'miauth.iconUrl' => '图标 URL（可选）',
			'miauth.submit' => '使用 MiAuth 登录',
			'miauth.success' => 'MiAuth 登录成功！',
			'miauth.failed' => ({required Object error}) => 'MiAuth 错误：${error}',
			'serverInfo.checkTitle' => '查看服务器信息',
			'serverInfo.check' => '查看服务器信息',
			'serverInfo.oauthNotSupported' => '此服务器不支持 OAuth（请改用 MiAuth）',
			'serverInfo.title' => '服务器信息',
			'serverInfo.authorizationEndpoint' => '授权端点',
			'serverInfo.tokenEndpoint' => '令牌端点',
			'serverInfo.scopesSupported' => '支持的作用域（点击复制）',
			'serverInfo.copied' => ({required Object scope}) => '已复制：${scope}',
			'accounts.title' => '已登录的账号',
			'accounts.reload' => '重新加载',
			'accounts.loadFailed' => '无法获取账号信息',
			'accounts.empty' => '没有已登录的账号',
			'accounts.savedAt' => ({required Object date}) => '保存时间：${date}',
			'accounts.delete' => '删除此账号',
			'accounts.activeChanged' => ({required Object account}) => '已更改活动账号：${account}',
			'validation.hostRequired' => '请输入主机',
			'validation.callbackSchemeRequired' => '请输入回调 scheme',
			'errors.userCancelled' => '身份验证已取消',
			'errors.callbackScheme' => '回调 scheme 配置不正确（请检查 AndroidManifest.xml / Info.plist）',
			'errors.authorizationLaunch' => '无法打开身份验证页面',
			'errors.network' => '发生网络错误',
			'errors.responseParse' => '无法解析服务器响应',
			'errors.secureStorage' => '安全存储操作失败',
			'errors.invalidAuthConfig' => '身份验证设置无效',
			'errors.serverInfo' => '无法获取服务器信息',
			'errors.oauthNotSupported' => '此服务器不支持 OAuth（请改用 MiAuth）',
			'errors.stateMismatch' => '安全验证失败（state 不匹配）',
			'errors.authorizationCodeMissing' => '无法获取授权码',
			'errors.authorizationServer' => '授权服务器返回了错误',
			'errors.tokenExchange' => '令牌交换失败',
			'errors.miAuthDenied' => 'MiAuth 已取消或被拒绝',
			'errors.miAuthCheckFailed' => 'MiAuth 验证失败',
			'errors.miAuthSessionInvalid' => 'MiAuth 会话无效或已过期',
			_ => null,
		};
	}
}
