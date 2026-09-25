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
class TranslationsKo extends Translations with BaseTranslations<AppLocale, Translations> {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsKo({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  _meta = meta ?? TranslationMetadata(
		    locale: AppLocale.ko,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver) {
		_meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <ko>.
	final TranslationMetadata<AppLocale, Translations> _meta;
	@override TranslationMetadata<AppLocale, Translations> get $meta => _meta;

	/// Access flat map
	@override dynamic operator[](String key) => _meta.getTranslation(key) ?? super[key];

	late final TranslationsKo _root = this; // ignore: unused_field

	@override 
	TranslationsKo $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsKo(meta: meta ?? this.$meta);

	// Translations
	@override late final _Translations$nav$ko nav = _Translations$nav$ko._(_root);
	@override late final _Translations$common$ko common = _Translations$common$ko._(_root);
	@override late final _Translations$oauth$ko oauth = _Translations$oauth$ko._(_root);
	@override late final _Translations$miauth$ko miauth = _Translations$miauth$ko._(_root);
	@override late final _Translations$serverInfo$ko serverInfo = _Translations$serverInfo$ko._(_root);
	@override late final _Translations$accounts$ko accounts = _Translations$accounts$ko._(_root);
	@override late final _Translations$validation$ko validation = _Translations$validation$ko._(_root);
	@override late final _Translations$errors$ko errors = _Translations$errors$ko._(_root);
}

// Path: nav
class _Translations$nav$ko extends Translations$nav$en {
	_Translations$nav$ko._(TranslationsKo root) : this._root = root, super.internal(root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get serverInfo => '서버 정보';
	@override String get accounts => '계정';
}

// Path: common
class _Translations$common$ko extends Translations$common$en {
	_Translations$common$ko._(TranslationsKo root) : this._root = root, super.internal(root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get callbackScheme => '콜백 스킴';
	@override String get host => '호스트';
	@override String get customScopes => '사용자 지정 스코프(쉼표로 구분)';
	@override String example({required Object value}) => '예: ${value}';
}

// Path: oauth
class _Translations$oauth$ko extends Translations$oauth$en {
	_Translations$oauth$ko._(TranslationsKo root) : this._root = root, super.internal(root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get title => 'OAuth 설정';
	@override String get clientId => '클라이언트 ID(URL)';
	@override String get redirectUri => '리디렉션 URI';
	@override String get redirectUriHelper => 'client_id 페이지에 등록한 URL과 정확히 일치해야 합니다(사용자 지정 스킴 사용 가능)';
	@override String get submit => 'OAuth로 로그인';
	@override String get success => '로그인했습니다!';
	@override String failed({required Object error}) => '인증 오류: ${error}';
}

// Path: miauth
class _Translations$miauth$ko extends Translations$miauth$en {
	_Translations$miauth$ko._(TranslationsKo root) : this._root = root, super.internal(root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get title => 'MiAuth 설정';
	@override String get appName => '앱 이름';
	@override String get iconUrl => '아이콘 URL(선택 사항)';
	@override String get submit => 'MiAuth로 로그인';
	@override String get success => 'MiAuth로 로그인했습니다!';
	@override String failed({required Object error}) => 'MiAuth 오류: ${error}';
}

// Path: serverInfo
class _Translations$serverInfo$ko extends Translations$serverInfo$en {
	_Translations$serverInfo$ko._(TranslationsKo root) : this._root = root, super.internal(root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get checkTitle => '서버 정보 확인';
	@override String get check => '서버 정보 확인';
	@override String get oauthNotSupported => '이 서버는 OAuth를 지원하지 않습니다(MiAuth를 사용하세요)';
	@override String get title => '서버 정보';
	@override String get authorizationEndpoint => '인가 엔드포인트';
	@override String get tokenEndpoint => '토큰 엔드포인트';
	@override String get scopesSupported => '지원하는 스코프(탭하여 복사)';
	@override String copied({required Object scope}) => '복사했습니다: ${scope}';
}

// Path: accounts
class _Translations$accounts$ko extends Translations$accounts$en {
	_Translations$accounts$ko._(TranslationsKo root) : this._root = root, super.internal(root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get title => '로그인한 계정';
	@override String get reload => '새로고침';
	@override String get loadFailed => '계정 정보를 가져오지 못했습니다';
	@override String get empty => '로그인한 계정이 없습니다';
	@override String savedAt({required Object date}) => '저장됨: ${date}';
	@override String get delete => '이 계정 삭제';
	@override String activeChanged({required Object account}) => '활성 계정을 변경했습니다: ${account}';
}

// Path: validation
class _Translations$validation$ko extends Translations$validation$en {
	_Translations$validation$ko._(TranslationsKo root) : this._root = root, super.internal(root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get hostRequired => '호스트를 입력하세요';
	@override String get callbackSchemeRequired => '콜백 스킴을 입력하세요';
}

// Path: errors
class _Translations$errors$ko extends Translations$errors$en {
	_Translations$errors$ko._(TranslationsKo root) : this._root = root, super.internal(root);

	final TranslationsKo _root; // ignore: unused_field

	// Translations
	@override String get userCancelled => '인증이 취소되었습니다';
	@override String get callbackScheme => '콜백 스킴 설정이 올바르지 않습니다(AndroidManifest.xml / Info.plist를 확인하세요)';
	@override String get authorizationLaunch => '인증 화면을 열지 못했습니다';
	@override String get network => '네트워크 오류가 발생했습니다';
	@override String get responseParse => '서버 응답을 해석하지 못했습니다';
	@override String get secureStorage => '보안 저장소 작업에 실패했습니다';
	@override String get invalidAuthConfig => '인증 설정이 올바르지 않습니다';
	@override String get serverInfo => '서버 정보를 가져오지 못했습니다';
	@override String get oauthNotSupported => '이 서버는 OAuth를 지원하지 않습니다(MiAuth를 사용하세요)';
	@override String get stateMismatch => '보안 검증에 실패했습니다(state 불일치)';
	@override String get authorizationCodeMissing => '인가 코드를 가져오지 못했습니다';
	@override String get authorizationServer => '인가 서버에서 오류가 발생했습니다';
	@override String get tokenExchange => '토큰 교환에 실패했습니다';
	@override String get miAuthDenied => 'MiAuth가 취소되었거나 거부되었습니다';
	@override String get miAuthCheckFailed => 'MiAuth 검증에 실패했습니다';
	@override String get miAuthSessionInvalid => 'MiAuth 세션이 올바르지 않거나 만료되었습니다';
}

/// The flat map containing all translations for locale <ko>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsKo {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'nav.serverInfo' => '서버 정보',
			'nav.accounts' => '계정',
			'common.callbackScheme' => '콜백 스킴',
			'common.host' => '호스트',
			'common.customScopes' => '사용자 지정 스코프(쉼표로 구분)',
			'common.example' => ({required Object value}) => '예: ${value}',
			'oauth.title' => 'OAuth 설정',
			'oauth.clientId' => '클라이언트 ID(URL)',
			'oauth.redirectUri' => '리디렉션 URI',
			'oauth.redirectUriHelper' => 'client_id 페이지에 등록한 URL과 정확히 일치해야 합니다(사용자 지정 스킴 사용 가능)',
			'oauth.submit' => 'OAuth로 로그인',
			'oauth.success' => '로그인했습니다!',
			'oauth.failed' => ({required Object error}) => '인증 오류: ${error}',
			'miauth.title' => 'MiAuth 설정',
			'miauth.appName' => '앱 이름',
			'miauth.iconUrl' => '아이콘 URL(선택 사항)',
			'miauth.submit' => 'MiAuth로 로그인',
			'miauth.success' => 'MiAuth로 로그인했습니다!',
			'miauth.failed' => ({required Object error}) => 'MiAuth 오류: ${error}',
			'serverInfo.checkTitle' => '서버 정보 확인',
			'serverInfo.check' => '서버 정보 확인',
			'serverInfo.oauthNotSupported' => '이 서버는 OAuth를 지원하지 않습니다(MiAuth를 사용하세요)',
			'serverInfo.title' => '서버 정보',
			'serverInfo.authorizationEndpoint' => '인가 엔드포인트',
			'serverInfo.tokenEndpoint' => '토큰 엔드포인트',
			'serverInfo.scopesSupported' => '지원하는 스코프(탭하여 복사)',
			'serverInfo.copied' => ({required Object scope}) => '복사했습니다: ${scope}',
			'accounts.title' => '로그인한 계정',
			'accounts.reload' => '새로고침',
			'accounts.loadFailed' => '계정 정보를 가져오지 못했습니다',
			'accounts.empty' => '로그인한 계정이 없습니다',
			'accounts.savedAt' => ({required Object date}) => '저장됨: ${date}',
			'accounts.delete' => '이 계정 삭제',
			'accounts.activeChanged' => ({required Object account}) => '활성 계정을 변경했습니다: ${account}',
			'validation.hostRequired' => '호스트를 입력하세요',
			'validation.callbackSchemeRequired' => '콜백 스킴을 입력하세요',
			'errors.userCancelled' => '인증이 취소되었습니다',
			'errors.callbackScheme' => '콜백 스킴 설정이 올바르지 않습니다(AndroidManifest.xml / Info.plist를 확인하세요)',
			'errors.authorizationLaunch' => '인증 화면을 열지 못했습니다',
			'errors.network' => '네트워크 오류가 발생했습니다',
			'errors.responseParse' => '서버 응답을 해석하지 못했습니다',
			'errors.secureStorage' => '보안 저장소 작업에 실패했습니다',
			'errors.invalidAuthConfig' => '인증 설정이 올바르지 않습니다',
			'errors.serverInfo' => '서버 정보를 가져오지 못했습니다',
			'errors.oauthNotSupported' => '이 서버는 OAuth를 지원하지 않습니다(MiAuth를 사용하세요)',
			'errors.stateMismatch' => '보안 검증에 실패했습니다(state 불일치)',
			'errors.authorizationCodeMissing' => '인가 코드를 가져오지 못했습니다',
			'errors.authorizationServer' => '인가 서버에서 오류가 발생했습니다',
			'errors.tokenExchange' => '토큰 교환에 실패했습니다',
			'errors.miAuthDenied' => 'MiAuth가 취소되었거나 거부되었습니다',
			'errors.miAuthCheckFailed' => 'MiAuth 검증에 실패했습니다',
			'errors.miAuthSessionInvalid' => 'MiAuth 세션이 올바르지 않거나 만료되었습니다',
			_ => null,
		};
	}
}
