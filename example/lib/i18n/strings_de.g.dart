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
class TranslationsDe extends Translations with BaseTranslations<AppLocale, Translations> {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsDe({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  _meta = meta ?? TranslationMetadata(
		    locale: AppLocale.de,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver) {
		_meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <de>.
	final TranslationMetadata<AppLocale, Translations> _meta;
	@override TranslationMetadata<AppLocale, Translations> get $meta => _meta;

	/// Access flat map
	@override dynamic operator[](String key) => _meta.getTranslation(key) ?? super[key];

	late final TranslationsDe _root = this; // ignore: unused_field

	@override 
	TranslationsDe $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsDe(meta: meta ?? this.$meta);

	// Translations
	@override late final _Translations$nav$de nav = _Translations$nav$de._(_root);
	@override late final _Translations$common$de common = _Translations$common$de._(_root);
	@override late final _Translations$oauth$de oauth = _Translations$oauth$de._(_root);
	@override late final _Translations$miauth$de miauth = _Translations$miauth$de._(_root);
	@override late final _Translations$serverInfo$de serverInfo = _Translations$serverInfo$de._(_root);
	@override late final _Translations$accounts$de accounts = _Translations$accounts$de._(_root);
	@override late final _Translations$validation$de validation = _Translations$validation$de._(_root);
	@override late final _Translations$errors$de errors = _Translations$errors$de._(_root);
}

// Path: nav
class _Translations$nav$de extends Translations$nav$en {
	_Translations$nav$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get serverInfo => 'Serverinfo';
	@override String get accounts => 'Konten';
}

// Path: common
class _Translations$common$de extends Translations$common$en {
	_Translations$common$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get callbackScheme => 'Callback-Schema';
	@override String get host => 'Host';
	@override String get customScopes => 'Eigene Scopes (durch Kommas getrennt)';
	@override String example({required Object value}) => 'z. B. ${value}';
}

// Path: oauth
class _Translations$oauth$de extends Translations$oauth$en {
	_Translations$oauth$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'OAuth-Einstellungen';
	@override String get clientId => 'Client-ID (URL)';
	@override String get redirectUri => 'Weiterleitungs-URI';
	@override String get redirectUriHelper => 'Muss exakt mit der auf der client_id-Seite eingetragenen URL übereinstimmen (benutzerdefiniertes Schema erlaubt)';
	@override String get submit => 'Mit OAuth anmelden';
	@override String get success => 'Anmeldung erfolgreich!';
	@override String failed({required Object error}) => 'Authentifizierungsfehler: ${error}';
}

// Path: miauth
class _Translations$miauth$de extends Translations$miauth$en {
	_Translations$miauth$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'MiAuth-Einstellungen';
	@override String get appName => 'App-Name';
	@override String get iconUrl => 'Symbol-URL (optional)';
	@override String get submit => 'Mit MiAuth anmelden';
	@override String get success => 'Anmeldung mit MiAuth erfolgreich!';
	@override String failed({required Object error}) => 'MiAuth-Fehler: ${error}';
}

// Path: serverInfo
class _Translations$serverInfo$de extends Translations$serverInfo$en {
	_Translations$serverInfo$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get checkTitle => 'Serverinformationen prüfen';
	@override String get check => 'Serverinformationen prüfen';
	@override String get oauthNotSupported => 'Dieser Server unterstützt OAuth nicht (verwenden Sie stattdessen MiAuth)';
	@override String get title => 'Serverinformationen';
	@override String get authorizationEndpoint => 'Autorisierungs-Endpunkt';
	@override String get tokenEndpoint => 'Token-Endpunkt';
	@override String get scopesSupported => 'Unterstützte Scopes (zum Kopieren tippen)';
	@override String copied({required Object scope}) => 'Kopiert: ${scope}';
}

// Path: accounts
class _Translations$accounts$de extends Translations$accounts$en {
	_Translations$accounts$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Angemeldete Konten';
	@override String get reload => 'Neu laden';
	@override String get loadFailed => 'Kontoinformationen konnten nicht abgerufen werden';
	@override String get empty => 'Keine angemeldeten Konten';
	@override String savedAt({required Object date}) => 'Gespeichert: ${date}';
	@override String get delete => 'Dieses Konto entfernen';
	@override String activeChanged({required Object account}) => 'Standardkonto geändert: ${account}';
}

// Path: validation
class _Translations$validation$de extends Translations$validation$en {
	_Translations$validation$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get hostRequired => 'Geben Sie einen Host ein';
	@override String get callbackSchemeRequired => 'Geben Sie ein Callback-Schema ein';
}

// Path: errors
class _Translations$errors$de extends Translations$errors$en {
	_Translations$errors$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get userCancelled => 'Die Authentifizierung wurde abgebrochen';
	@override String get callbackScheme => 'Das Callback-Schema ist nicht korrekt konfiguriert (prüfen Sie AndroidManifest.xml / Info.plist)';
	@override String get authorizationLaunch => 'Der Authentifizierungsbildschirm konnte nicht geöffnet werden';
	@override String get network => 'Ein Netzwerkfehler ist aufgetreten';
	@override String get responseParse => 'Die Serverantwort konnte nicht verarbeitet werden';
	@override String get secureStorage => 'Der Zugriff auf den sicheren Speicher ist fehlgeschlagen';
	@override String get invalidAuthConfig => 'Die Authentifizierungseinstellungen sind ungültig';
	@override String get serverInfo => 'Serverinformationen konnten nicht abgerufen werden';
	@override String get oauthNotSupported => 'Dieser Server unterstützt OAuth nicht (verwenden Sie stattdessen MiAuth)';
	@override String get stateMismatch => 'Sicherheitsprüfung fehlgeschlagen (state stimmt nicht überein)';
	@override String get authorizationCodeMissing => 'Der Autorisierungscode konnte nicht abgerufen werden';
	@override String get authorizationServer => 'Der Autorisierungsserver hat einen Fehler zurückgegeben';
	@override String get tokenExchange => 'Der Token-Austausch ist fehlgeschlagen';
	@override String get miAuthDenied => 'MiAuth wurde abgebrochen oder abgelehnt';
	@override String get miAuthCheckFailed => 'Die MiAuth-Prüfung ist fehlgeschlagen';
	@override String get miAuthSessionInvalid => 'Die MiAuth-Sitzung ist ungültig oder abgelaufen';
}

/// The flat map containing all translations for locale <de>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsDe {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'nav.serverInfo' => 'Serverinfo',
			'nav.accounts' => 'Konten',
			'common.callbackScheme' => 'Callback-Schema',
			'common.host' => 'Host',
			'common.customScopes' => 'Eigene Scopes (durch Kommas getrennt)',
			'common.example' => ({required Object value}) => 'z. B. ${value}',
			'oauth.title' => 'OAuth-Einstellungen',
			'oauth.clientId' => 'Client-ID (URL)',
			'oauth.redirectUri' => 'Weiterleitungs-URI',
			'oauth.redirectUriHelper' => 'Muss exakt mit der auf der client_id-Seite eingetragenen URL übereinstimmen (benutzerdefiniertes Schema erlaubt)',
			'oauth.submit' => 'Mit OAuth anmelden',
			'oauth.success' => 'Anmeldung erfolgreich!',
			'oauth.failed' => ({required Object error}) => 'Authentifizierungsfehler: ${error}',
			'miauth.title' => 'MiAuth-Einstellungen',
			'miauth.appName' => 'App-Name',
			'miauth.iconUrl' => 'Symbol-URL (optional)',
			'miauth.submit' => 'Mit MiAuth anmelden',
			'miauth.success' => 'Anmeldung mit MiAuth erfolgreich!',
			'miauth.failed' => ({required Object error}) => 'MiAuth-Fehler: ${error}',
			'serverInfo.checkTitle' => 'Serverinformationen prüfen',
			'serverInfo.check' => 'Serverinformationen prüfen',
			'serverInfo.oauthNotSupported' => 'Dieser Server unterstützt OAuth nicht (verwenden Sie stattdessen MiAuth)',
			'serverInfo.title' => 'Serverinformationen',
			'serverInfo.authorizationEndpoint' => 'Autorisierungs-Endpunkt',
			'serverInfo.tokenEndpoint' => 'Token-Endpunkt',
			'serverInfo.scopesSupported' => 'Unterstützte Scopes (zum Kopieren tippen)',
			'serverInfo.copied' => ({required Object scope}) => 'Kopiert: ${scope}',
			'accounts.title' => 'Angemeldete Konten',
			'accounts.reload' => 'Neu laden',
			'accounts.loadFailed' => 'Kontoinformationen konnten nicht abgerufen werden',
			'accounts.empty' => 'Keine angemeldeten Konten',
			'accounts.savedAt' => ({required Object date}) => 'Gespeichert: ${date}',
			'accounts.delete' => 'Dieses Konto entfernen',
			'accounts.activeChanged' => ({required Object account}) => 'Standardkonto geändert: ${account}',
			'validation.hostRequired' => 'Geben Sie einen Host ein',
			'validation.callbackSchemeRequired' => 'Geben Sie ein Callback-Schema ein',
			'errors.userCancelled' => 'Die Authentifizierung wurde abgebrochen',
			'errors.callbackScheme' => 'Das Callback-Schema ist nicht korrekt konfiguriert (prüfen Sie AndroidManifest.xml / Info.plist)',
			'errors.authorizationLaunch' => 'Der Authentifizierungsbildschirm konnte nicht geöffnet werden',
			'errors.network' => 'Ein Netzwerkfehler ist aufgetreten',
			'errors.responseParse' => 'Die Serverantwort konnte nicht verarbeitet werden',
			'errors.secureStorage' => 'Der Zugriff auf den sicheren Speicher ist fehlgeschlagen',
			'errors.invalidAuthConfig' => 'Die Authentifizierungseinstellungen sind ungültig',
			'errors.serverInfo' => 'Serverinformationen konnten nicht abgerufen werden',
			'errors.oauthNotSupported' => 'Dieser Server unterstützt OAuth nicht (verwenden Sie stattdessen MiAuth)',
			'errors.stateMismatch' => 'Sicherheitsprüfung fehlgeschlagen (state stimmt nicht überein)',
			'errors.authorizationCodeMissing' => 'Der Autorisierungscode konnte nicht abgerufen werden',
			'errors.authorizationServer' => 'Der Autorisierungsserver hat einen Fehler zurückgegeben',
			'errors.tokenExchange' => 'Der Token-Austausch ist fehlgeschlagen',
			'errors.miAuthDenied' => 'MiAuth wurde abgebrochen oder abgelehnt',
			'errors.miAuthCheckFailed' => 'Die MiAuth-Prüfung ist fehlgeschlagen',
			'errors.miAuthSessionInvalid' => 'Die MiAuth-Sitzung ist ungültig oder abgelaufen',
			_ => null,
		};
	}
}
