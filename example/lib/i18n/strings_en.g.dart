///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import
// dart format off

part of 'strings.g.dart';

// Path: <root>
typedef TranslationsEn = Translations; // ignore: unused_element
class Translations with BaseTranslations<AppLocale, Translations> {
	/// Returns the current translations of the given [context].
	///
	/// Usage:
	/// final t = Translations.of(context);
	static Translations of(BuildContext context) => InheritedLocaleData.of<AppLocale, Translations>(context).translations;

	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	Translations({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  _meta = meta ?? TranslationMetadata(
		    locale: AppLocale.en,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ) {
		_meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <en>.
	final TranslationMetadata<AppLocale, Translations> _meta;
	@override TranslationMetadata<AppLocale, Translations> get $meta => _meta;

	/// Access flat map
	dynamic operator[](String key) => _meta.getTranslation(key);

	late final Translations _root = this; // ignore: unused_field

	Translations $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => Translations(meta: meta ?? this.$meta);

	// Translations
	late final Translations$nav$en nav = Translations$nav$en.internal(_root);
	late final Translations$common$en common = Translations$common$en.internal(_root);
	late final Translations$oauth$en oauth = Translations$oauth$en.internal(_root);
	late final Translations$miauth$en miauth = Translations$miauth$en.internal(_root);
	late final Translations$serverInfo$en serverInfo = Translations$serverInfo$en.internal(_root);
	late final Translations$accounts$en accounts = Translations$accounts$en.internal(_root);
	late final Translations$validation$en validation = Translations$validation$en.internal(_root);
	late final Translations$errors$en errors = Translations$errors$en.internal(_root);
}

// Path: nav
class Translations$nav$en {
	Translations$nav$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Server info'
	String get serverInfo => 'Server info';

	/// en: 'Accounts'
	String get accounts => 'Accounts';
}

// Path: common
class Translations$common$en {
	Translations$common$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Callback scheme'
	String get callbackScheme => 'Callback scheme';

	/// en: 'Host'
	String get host => 'Host';

	/// en: 'Custom scopes (comma-separated)'
	String get customScopes => 'Custom scopes (comma-separated)';

	/// en: 'e.g. $value'
	String example({required Object value}) => 'e.g. ${value}';
}

// Path: oauth
class Translations$oauth$en {
	Translations$oauth$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'OAuth settings'
	String get title => 'OAuth settings';

	/// en: 'Client ID (URL)'
	String get clientId => 'Client ID (URL)';

	/// en: 'Redirect URI'
	String get redirectUri => 'Redirect URI';

	/// en: 'Must exactly match the URL listed on the client_id page (a custom scheme is allowed)'
	String get redirectUriHelper => 'Must exactly match the URL listed on the client_id page (a custom scheme is allowed)';

	/// en: 'Sign in with OAuth'
	String get submit => 'Sign in with OAuth';

	/// en: 'Signed in successfully!'
	String get success => 'Signed in successfully!';

	/// en: 'Authentication error: $error'
	String failed({required Object error}) => 'Authentication error: ${error}';
}

// Path: miauth
class Translations$miauth$en {
	Translations$miauth$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'MiAuth settings'
	String get title => 'MiAuth settings';

	/// en: 'App name'
	String get appName => 'App name';

	/// en: 'Icon URL (optional)'
	String get iconUrl => 'Icon URL (optional)';

	/// en: 'Sign in with MiAuth'
	String get submit => 'Sign in with MiAuth';

	/// en: 'Signed in with MiAuth!'
	String get success => 'Signed in with MiAuth!';

	/// en: 'MiAuth error: $error'
	String failed({required Object error}) => 'MiAuth error: ${error}';
}

// Path: serverInfo
class Translations$serverInfo$en {
	Translations$serverInfo$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Check server info'
	String get checkTitle => 'Check server info';

	/// en: 'Check server info'
	String get check => 'Check server info';

	/// en: 'This server does not support OAuth (use MiAuth instead)'
	String get oauthNotSupported => 'This server does not support OAuth (use MiAuth instead)';

	/// en: 'Server info'
	String get title => 'Server info';

	/// en: 'Authorization endpoint'
	String get authorizationEndpoint => 'Authorization endpoint';

	/// en: 'Token endpoint'
	String get tokenEndpoint => 'Token endpoint';

	/// en: 'Supported scopes (tap to copy)'
	String get scopesSupported => 'Supported scopes (tap to copy)';

	/// en: 'Copied: $scope'
	String copied({required Object scope}) => 'Copied: ${scope}';
}

// Path: accounts
class Translations$accounts$en {
	Translations$accounts$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Signed-in accounts'
	String get title => 'Signed-in accounts';

	/// en: 'Reload'
	String get reload => 'Reload';

	/// en: 'Could not load account information'
	String get loadFailed => 'Could not load account information';

	/// en: 'No signed-in accounts'
	String get empty => 'No signed-in accounts';

	/// en: 'Saved: $date'
	String savedAt({required Object date}) => 'Saved: ${date}';

	/// en: 'Remove this account'
	String get delete => 'Remove this account';

	/// en: 'Default account changed: $account'
	String activeChanged({required Object account}) => 'Default account changed: ${account}';
}

// Path: validation
class Translations$validation$en {
	Translations$validation$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Enter a host'
	String get hostRequired => 'Enter a host';

	/// en: 'Enter a callback scheme'
	String get callbackSchemeRequired => 'Enter a callback scheme';
}

// Path: errors
class Translations$errors$en {
	Translations$errors$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Authentication was cancelled'
	String get userCancelled => 'Authentication was cancelled';

	/// en: 'The callback scheme is not configured correctly (check AndroidManifest.xml / Info.plist)'
	String get callbackScheme => 'The callback scheme is not configured correctly (check AndroidManifest.xml / Info.plist)';

	/// en: 'Could not open the authentication screen'
	String get authorizationLaunch => 'Could not open the authentication screen';

	/// en: 'A network error occurred'
	String get network => 'A network error occurred';

	/// en: 'Could not parse the server response'
	String get responseParse => 'Could not parse the server response';

	/// en: 'Secure storage operation failed'
	String get secureStorage => 'Secure storage operation failed';

	/// en: 'The authentication settings are invalid'
	String get invalidAuthConfig => 'The authentication settings are invalid';

	/// en: 'Could not fetch server info'
	String get serverInfo => 'Could not fetch server info';

	/// en: 'This server does not support OAuth (use MiAuth instead)'
	String get oauthNotSupported => 'This server does not support OAuth (use MiAuth instead)';

	/// en: 'Security check failed (state mismatch)'
	String get stateMismatch => 'Security check failed (state mismatch)';

	/// en: 'Could not get the authorization code'
	String get authorizationCodeMissing => 'Could not get the authorization code';

	/// en: 'The authorization server returned an error'
	String get authorizationServer => 'The authorization server returned an error';

	/// en: 'Token exchange failed'
	String get tokenExchange => 'Token exchange failed';

	/// en: 'MiAuth was cancelled or denied'
	String get miAuthDenied => 'MiAuth was cancelled or denied';

	/// en: 'MiAuth verification failed'
	String get miAuthCheckFailed => 'MiAuth verification failed';

	/// en: 'The MiAuth session is invalid or has expired'
	String get miAuthSessionInvalid => 'The MiAuth session is invalid or has expired';
}

/// The flat map containing all translations for locale <en>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on Translations {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'nav.serverInfo' => 'Server info',
			'nav.accounts' => 'Accounts',
			'common.callbackScheme' => 'Callback scheme',
			'common.host' => 'Host',
			'common.customScopes' => 'Custom scopes (comma-separated)',
			'common.example' => ({required Object value}) => 'e.g. ${value}',
			'oauth.title' => 'OAuth settings',
			'oauth.clientId' => 'Client ID (URL)',
			'oauth.redirectUri' => 'Redirect URI',
			'oauth.redirectUriHelper' => 'Must exactly match the URL listed on the client_id page (a custom scheme is allowed)',
			'oauth.submit' => 'Sign in with OAuth',
			'oauth.success' => 'Signed in successfully!',
			'oauth.failed' => ({required Object error}) => 'Authentication error: ${error}',
			'miauth.title' => 'MiAuth settings',
			'miauth.appName' => 'App name',
			'miauth.iconUrl' => 'Icon URL (optional)',
			'miauth.submit' => 'Sign in with MiAuth',
			'miauth.success' => 'Signed in with MiAuth!',
			'miauth.failed' => ({required Object error}) => 'MiAuth error: ${error}',
			'serverInfo.checkTitle' => 'Check server info',
			'serverInfo.check' => 'Check server info',
			'serverInfo.oauthNotSupported' => 'This server does not support OAuth (use MiAuth instead)',
			'serverInfo.title' => 'Server info',
			'serverInfo.authorizationEndpoint' => 'Authorization endpoint',
			'serverInfo.tokenEndpoint' => 'Token endpoint',
			'serverInfo.scopesSupported' => 'Supported scopes (tap to copy)',
			'serverInfo.copied' => ({required Object scope}) => 'Copied: ${scope}',
			'accounts.title' => 'Signed-in accounts',
			'accounts.reload' => 'Reload',
			'accounts.loadFailed' => 'Could not load account information',
			'accounts.empty' => 'No signed-in accounts',
			'accounts.savedAt' => ({required Object date}) => 'Saved: ${date}',
			'accounts.delete' => 'Remove this account',
			'accounts.activeChanged' => ({required Object account}) => 'Default account changed: ${account}',
			'validation.hostRequired' => 'Enter a host',
			'validation.callbackSchemeRequired' => 'Enter a callback scheme',
			'errors.userCancelled' => 'Authentication was cancelled',
			'errors.callbackScheme' => 'The callback scheme is not configured correctly (check AndroidManifest.xml / Info.plist)',
			'errors.authorizationLaunch' => 'Could not open the authentication screen',
			'errors.network' => 'A network error occurred',
			'errors.responseParse' => 'Could not parse the server response',
			'errors.secureStorage' => 'Secure storage operation failed',
			'errors.invalidAuthConfig' => 'The authentication settings are invalid',
			'errors.serverInfo' => 'Could not fetch server info',
			'errors.oauthNotSupported' => 'This server does not support OAuth (use MiAuth instead)',
			'errors.stateMismatch' => 'Security check failed (state mismatch)',
			'errors.authorizationCodeMissing' => 'Could not get the authorization code',
			'errors.authorizationServer' => 'The authorization server returned an error',
			'errors.tokenExchange' => 'Token exchange failed',
			'errors.miAuthDenied' => 'MiAuth was cancelled or denied',
			'errors.miAuthCheckFailed' => 'MiAuth verification failed',
			'errors.miAuthSessionInvalid' => 'The MiAuth session is invalid or has expired',
			_ => null,
		};
	}
}
