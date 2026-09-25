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
class TranslationsFr extends Translations with BaseTranslations<AppLocale, Translations> {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsFr({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  _meta = meta ?? TranslationMetadata(
		    locale: AppLocale.fr,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver) {
		_meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <fr>.
	final TranslationMetadata<AppLocale, Translations> _meta;
	@override TranslationMetadata<AppLocale, Translations> get $meta => _meta;

	/// Access flat map
	@override dynamic operator[](String key) => _meta.getTranslation(key) ?? super[key];

	late final TranslationsFr _root = this; // ignore: unused_field

	@override 
	TranslationsFr $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsFr(meta: meta ?? this.$meta);

	// Translations
	@override late final _Translations$nav$fr nav = _Translations$nav$fr._(_root);
	@override late final _Translations$common$fr common = _Translations$common$fr._(_root);
	@override late final _Translations$oauth$fr oauth = _Translations$oauth$fr._(_root);
	@override late final _Translations$miauth$fr miauth = _Translations$miauth$fr._(_root);
	@override late final _Translations$serverInfo$fr serverInfo = _Translations$serverInfo$fr._(_root);
	@override late final _Translations$accounts$fr accounts = _Translations$accounts$fr._(_root);
	@override late final _Translations$validation$fr validation = _Translations$validation$fr._(_root);
	@override late final _Translations$errors$fr errors = _Translations$errors$fr._(_root);
}

// Path: nav
class _Translations$nav$fr extends Translations$nav$en {
	_Translations$nav$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get serverInfo => 'Serveur';
	@override String get accounts => 'Comptes';
}

// Path: common
class _Translations$common$fr extends Translations$common$en {
	_Translations$common$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get callbackScheme => 'Schéma de rappel';
	@override String get host => 'Hôte';
	@override String get customScopes => 'Scopes personnalisés (séparés par des virgules)';
	@override String example({required Object value}) => 'ex. : ${value}';
}

// Path: oauth
class _Translations$oauth$fr extends Translations$oauth$en {
	_Translations$oauth$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Paramètres OAuth';
	@override String get clientId => 'ID client (URL)';
	@override String get redirectUri => 'URI de redirection';
	@override String get redirectUriHelper => 'Doit correspondre exactement à l’URL indiquée sur la page client_id (un schéma personnalisé est autorisé)';
	@override String get submit => 'Se connecter avec OAuth';
	@override String get success => 'Connexion réussie !';
	@override String failed({required Object error}) => 'Erreur d’authentification : ${error}';
}

// Path: miauth
class _Translations$miauth$fr extends Translations$miauth$en {
	_Translations$miauth$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Paramètres MiAuth';
	@override String get appName => 'Nom de l’application';
	@override String get iconUrl => 'URL de l’icône (facultatif)';
	@override String get submit => 'Se connecter avec MiAuth';
	@override String get success => 'Connexion avec MiAuth réussie !';
	@override String failed({required Object error}) => 'Erreur MiAuth : ${error}';
}

// Path: serverInfo
class _Translations$serverInfo$fr extends Translations$serverInfo$en {
	_Translations$serverInfo$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get checkTitle => 'Vérifier les informations du serveur';
	@override String get check => 'Vérifier les informations du serveur';
	@override String get oauthNotSupported => 'Ce serveur ne prend pas en charge OAuth (utilisez MiAuth)';
	@override String get title => 'Informations du serveur';
	@override String get authorizationEndpoint => 'Point de terminaison d’autorisation';
	@override String get tokenEndpoint => 'Point de terminaison de jeton';
	@override String get scopesSupported => 'Scopes pris en charge (touchez pour copier)';
	@override String copied({required Object scope}) => 'Copié : ${scope}';
}

// Path: accounts
class _Translations$accounts$fr extends Translations$accounts$en {
	_Translations$accounts$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Comptes connectés';
	@override String get reload => 'Actualiser';
	@override String get loadFailed => 'Impossible de récupérer les informations des comptes';
	@override String get empty => 'Aucun compte connecté';
	@override String savedAt({required Object date}) => 'Enregistré : ${date}';
	@override String get delete => 'Supprimer ce compte';
	@override String activeChanged({required Object account}) => 'Compte par défaut modifié : ${account}';
}

// Path: validation
class _Translations$validation$fr extends Translations$validation$en {
	_Translations$validation$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get hostRequired => 'Saisissez un hôte';
	@override String get callbackSchemeRequired => 'Saisissez un schéma de rappel';
}

// Path: errors
class _Translations$errors$fr extends Translations$errors$en {
	_Translations$errors$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get userCancelled => 'L’authentification a été annulée';
	@override String get callbackScheme => 'Le schéma de rappel n’est pas configuré correctement (vérifiez AndroidManifest.xml / Info.plist)';
	@override String get authorizationLaunch => 'Impossible d’ouvrir l’écran d’authentification';
	@override String get network => 'Une erreur réseau s’est produite';
	@override String get responseParse => 'Impossible d’analyser la réponse du serveur';
	@override String get secureStorage => 'L’opération sur le stockage sécurisé a échoué';
	@override String get invalidAuthConfig => 'Les paramètres d’authentification ne sont pas valides';
	@override String get serverInfo => 'Impossible de récupérer les informations du serveur';
	@override String get oauthNotSupported => 'Ce serveur ne prend pas en charge OAuth (utilisez MiAuth)';
	@override String get stateMismatch => 'La vérification de sécurité a échoué (state ne correspond pas)';
	@override String get authorizationCodeMissing => 'Impossible d’obtenir le code d’autorisation';
	@override String get authorizationServer => 'Le serveur d’autorisation a renvoyé une erreur';
	@override String get tokenExchange => 'L’échange de jeton a échoué';
	@override String get miAuthDenied => 'MiAuth a été annulé ou refusé';
	@override String get miAuthCheckFailed => 'La vérification MiAuth a échoué';
	@override String get miAuthSessionInvalid => 'La session MiAuth n’est pas valide ou a expiré';
}

/// The flat map containing all translations for locale <fr>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsFr {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'nav.serverInfo' => 'Serveur',
			'nav.accounts' => 'Comptes',
			'common.callbackScheme' => 'Schéma de rappel',
			'common.host' => 'Hôte',
			'common.customScopes' => 'Scopes personnalisés (séparés par des virgules)',
			'common.example' => ({required Object value}) => 'ex. : ${value}',
			'oauth.title' => 'Paramètres OAuth',
			'oauth.clientId' => 'ID client (URL)',
			'oauth.redirectUri' => 'URI de redirection',
			'oauth.redirectUriHelper' => 'Doit correspondre exactement à l’URL indiquée sur la page client_id (un schéma personnalisé est autorisé)',
			'oauth.submit' => 'Se connecter avec OAuth',
			'oauth.success' => 'Connexion réussie !',
			'oauth.failed' => ({required Object error}) => 'Erreur d’authentification : ${error}',
			'miauth.title' => 'Paramètres MiAuth',
			'miauth.appName' => 'Nom de l’application',
			'miauth.iconUrl' => 'URL de l’icône (facultatif)',
			'miauth.submit' => 'Se connecter avec MiAuth',
			'miauth.success' => 'Connexion avec MiAuth réussie !',
			'miauth.failed' => ({required Object error}) => 'Erreur MiAuth : ${error}',
			'serverInfo.checkTitle' => 'Vérifier les informations du serveur',
			'serverInfo.check' => 'Vérifier les informations du serveur',
			'serverInfo.oauthNotSupported' => 'Ce serveur ne prend pas en charge OAuth (utilisez MiAuth)',
			'serverInfo.title' => 'Informations du serveur',
			'serverInfo.authorizationEndpoint' => 'Point de terminaison d’autorisation',
			'serverInfo.tokenEndpoint' => 'Point de terminaison de jeton',
			'serverInfo.scopesSupported' => 'Scopes pris en charge (touchez pour copier)',
			'serverInfo.copied' => ({required Object scope}) => 'Copié : ${scope}',
			'accounts.title' => 'Comptes connectés',
			'accounts.reload' => 'Actualiser',
			'accounts.loadFailed' => 'Impossible de récupérer les informations des comptes',
			'accounts.empty' => 'Aucun compte connecté',
			'accounts.savedAt' => ({required Object date}) => 'Enregistré : ${date}',
			'accounts.delete' => 'Supprimer ce compte',
			'accounts.activeChanged' => ({required Object account}) => 'Compte par défaut modifié : ${account}',
			'validation.hostRequired' => 'Saisissez un hôte',
			'validation.callbackSchemeRequired' => 'Saisissez un schéma de rappel',
			'errors.userCancelled' => 'L’authentification a été annulée',
			'errors.callbackScheme' => 'Le schéma de rappel n’est pas configuré correctement (vérifiez AndroidManifest.xml / Info.plist)',
			'errors.authorizationLaunch' => 'Impossible d’ouvrir l’écran d’authentification',
			'errors.network' => 'Une erreur réseau s’est produite',
			'errors.responseParse' => 'Impossible d’analyser la réponse du serveur',
			'errors.secureStorage' => 'L’opération sur le stockage sécurisé a échoué',
			'errors.invalidAuthConfig' => 'Les paramètres d’authentification ne sont pas valides',
			'errors.serverInfo' => 'Impossible de récupérer les informations du serveur',
			'errors.oauthNotSupported' => 'Ce serveur ne prend pas en charge OAuth (utilisez MiAuth)',
			'errors.stateMismatch' => 'La vérification de sécurité a échoué (state ne correspond pas)',
			'errors.authorizationCodeMissing' => 'Impossible d’obtenir le code d’autorisation',
			'errors.authorizationServer' => 'Le serveur d’autorisation a renvoyé une erreur',
			'errors.tokenExchange' => 'L’échange de jeton a échoué',
			'errors.miAuthDenied' => 'MiAuth a été annulé ou refusé',
			'errors.miAuthCheckFailed' => 'La vérification MiAuth a échoué',
			'errors.miAuthSessionInvalid' => 'La session MiAuth n’est pas valide ou a expiré',
			_ => null,
		};
	}
}
