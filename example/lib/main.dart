import 'package:flutter/material.dart';
import 'package:misskey_auth/misskey_auth.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'i18n/strings.g.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // 端末の言語に合わせる。対応していない言語では英語になる
  LocaleSettings.useDeviceLocaleSync();
  runApp(TranslationProvider(child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Misskey Auth Example',
      locale: TranslationProvider.of(context).flutterLocale,
      supportedLocales: AppLocaleUtils.supportedLocales,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: LoaderOverlay(child: const AuthExamplePage()),
    );
  }
}

class AuthExamplePage extends StatefulWidget {
  const AuthExamplePage({super.key});

  @override
  State<AuthExamplePage> createState() => _AuthExamplePageState();
}

class _AuthExamplePageState extends State<AuthExamplePage> {
  final _auth = MisskeyAuthManager.defaultInstance();
  final _oauthClient = MisskeyOAuthClient(); // サーバー情報の確認用
  int _currentIndex = 0;

  // フォームコントローラー
  final _hostController = TextEditingController();
  final _clientIdController = TextEditingController();
  final _redirectUriController = TextEditingController();
  final _scopeController = TextEditingController();
  final _callbackSchemeController = TextEditingController();

  // MiAuth 用フォーム
  final _miAppNameController = TextEditingController();
  final _miPermissionsController = TextEditingController();
  final _miIconUrlController = TextEditingController();

  // 状態
  OAuthServerInfo? _serverInfo;

  // スコープ入力（カスタムのみを採用）
  final TextEditingController _oauthCustomScopesController =
      TextEditingController();
  final TextEditingController _miCustomScopesController =
      TextEditingController();

  void _addOAuthCustomScopesFromInput() {
    final List<String> items = _oauthCustomScopesController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (items.isEmpty) return;
    _scopeController.text = items.join(' ');
    setState(() {
      _oauthCustomScopesController.clear();
    });
  }

  void _addMiCustomScopesFromInput() {
    final List<String> items = _miCustomScopesController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (items.isEmpty) return;
    _miPermissionsController.text = items.join(' ');
    setState(() {
      _miCustomScopesController.clear();
    });
  }

  String _mapErrorToMessage(Object error) {
    final e = t.errors;
    // MisskeyAuth のカスタム例外をユーザー向けの文言に整形
    if (error is MisskeyAuthException) {
      final details = error.details;
      final suffix = details != null ? ': $details' : '';
      if (error is UserCancelledException) {
        return e.userCancelled;
      }
      if (error is CallbackSchemeErrorException) {
        return e.callbackScheme;
      }
      if (error is AuthorizationLaunchException) {
        return e.authorizationLaunch;
      }
      if (error is NetworkException) {
        return e.network;
      }
      if (error is ResponseParseException) {
        return e.responseParse;
      }
      if (error is SecureStorageException) {
        return e.secureStorage;
      }
      if (error is InvalidAuthConfigException) {
        return e.invalidAuthConfig;
      }
      if (error is ServerInfoException) {
        return '${e.serverInfo}$suffix';
      }
      // OAuth
      if (error is OAuthNotSupportedException) {
        return e.oauthNotSupported;
      }
      if (error is StateMismatchException) {
        return e.stateMismatch;
      }
      if (error is AuthorizationCodeMissingException) {
        return e.authorizationCodeMissing;
      }
      if (error is AuthorizationServerErrorException) {
        return '${e.authorizationServer}$suffix';
      }
      if (error is TokenExchangeException) {
        return '${e.tokenExchange}$suffix';
      }
      // MiAuth
      if (error is MiAuthDeniedException) {
        return e.miAuthDenied;
      }
      if (error is MiAuthCheckFailedException) {
        return '${e.miAuthCheckFailed}$suffix';
      }
      if (error is MiAuthSessionInvalidException) {
        return '${e.miAuthSessionInvalid}$suffix';
      }
      return error.toString();
    }
    // その他の例外はそのまま文字列化
    return error.toString();
  }

  @override
  void initState() {
    super.initState();
    _setDefaultValues();
  }

  @override
  void dispose() {
    _hostController.dispose();
    _clientIdController.dispose();
    _redirectUriController.dispose();
    _scopeController.dispose();
    _callbackSchemeController.dispose();
    _miAppNameController.dispose();
    _miPermissionsController.dispose();
    _miIconUrlController.dispose();
    super.dispose();
  }

  void _setDefaultValues() {
    _hostController.text = 'misskey.io';
    _clientIdController.text =
        'https://librarylibrarian.github.io/misskey_auth/example/';
    _redirectUriController.text =
        'https://librarylibrarian.github.io/misskey_auth/example/redirect.html';
    _scopeController.text = 'read:account write:notes';
    _callbackSchemeController.text = 'misskeyauth';

    // MiAuth
    _miAppNameController.text = 'Misskey Auth Example';
    _miPermissionsController.text = 'read:account write:notes';
    _miIconUrlController.text = '';

    // 候補配列は廃止（カスタム欄から確定時にTextControllerへ反映）
  }

  Future<void> _checkServerInfo() async {
    setState(() {
      _serverInfo = null;
    });

    if (!mounted) return;
    context.loaderOverlay.show();

    try {
      final host = _hostController.text.trim();
      if (host.isEmpty) {
        throw Exception(t.validation.hostRequired);
      }

      final serverInfo = await _oauthClient.getOAuthServerInfo(host);

      if (!mounted) return;
      setState(() {
        _serverInfo = serverInfo;
      });

      if (serverInfo == null && mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text(t.serverInfo.oauthNotSupported)),
          );
      }
    } on MisskeyAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(_mapErrorToMessage(e))));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) {
        context.loaderOverlay.hide();
      }
    }
  }

  Future<void> _startAuth() async {
    if (!mounted) return;
    context.loaderOverlay.show();

    try {
      // 未確定のカスタムスコープ入力を確定して反映
      _addOAuthCustomScopesFromInput();
      final config = MisskeyOAuthConfig(
        host: _hostController.text.trim(),
        clientId: _clientIdController.text.trim(),
        redirectUri: _redirectUriController.text.trim(),
        scope: _scopeController.text.trim(),
        callbackScheme: _callbackSchemeController.text.trim(),
      );

      await _auth.loginWithOAuth(config, setActive: true);

      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(t.oauth.success)));
        setState(() {
          _currentIndex = 3; // アカウント一覧タブへ
        });
      }
    } on MisskeyAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(_mapErrorToMessage(e))));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(t.oauth.failed(error: e))));
      }
    } finally {
      if (mounted) {
        context.loaderOverlay.hide();
      }
    }
  }

  Future<void> _startMiAuth() async {
    if (!mounted) return;
    context.loaderOverlay.show();

    try {
      // 未確定のカスタムスコープ入力を確定して反映
      _addMiCustomScopesFromInput();
      final host = _hostController.text.trim();
      if (host.isEmpty) {
        throw Exception(t.validation.hostRequired);
      }

      final scheme = _callbackSchemeController.text.trim();
      if (scheme.isEmpty) {
        throw Exception(t.validation.callbackSchemeRequired);
      }

      final permissions = _miPermissionsController.text
          .split(RegExp(r"[ ,]+"))
          .where((e) => e.isNotEmpty)
          .toList();

      final config = MisskeyMiAuthConfig(
        host: host,
        appName: _miAppNameController.text.trim(),
        callbackScheme: scheme,
        permissions: permissions,
        iconUrl: _miIconUrlController.text.trim().isEmpty
            ? null
            : _miIconUrlController.text.trim(),
      );

      await _auth.loginWithMiAuth(config, setActive: true);

      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(t.miauth.success)));
        setState(() {
          _currentIndex = 3; // アカウント一覧タブへ
        });
      }
    } on MisskeyAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(_mapErrorToMessage(e))));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(t.miauth.failed(error: e))));
      }
    } finally {
      if (mounted) {
        context.loaderOverlay.hide();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Misskey Auth Sample'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_currentIndex == 0)
              _buildOAuthForm(context)
            else if (_currentIndex == 1)
              _buildMiAuthForm(context)
            else if (_currentIndex == 2)
              _buildServerInfoTab(context)
            else
              _buildAccountsTab(context),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        destinations: [
          const NavigationDestination(icon: Icon(Icons.lock), label: 'OAuth'),
          const NavigationDestination(
            icon: Icon(Icons.vpn_key),
            label: 'MiAuth',
          ),
          NavigationDestination(
            icon: const Icon(Icons.info_outline),
            label: t.nav.serverInfo,
          ),
          NavigationDestination(
            icon: const Icon(Icons.people),
            label: t.nav.accounts,
          ),
        ],
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }

  Widget _buildOAuthForm(BuildContext context) {
    final t = context.t;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.oauth.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _callbackSchemeController,
              decoration: InputDecoration(
                labelText: t.common.callbackScheme,
                hintText: t.common.example(value: 'misskeyauth'),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _hostController,
              decoration: InputDecoration(
                labelText: t.common.host,
                hintText: t.common.example(value: 'misskey.io'),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _clientIdController,
              decoration: InputDecoration(
                labelText: t.oauth.clientId,
                hintText: t.common.example(value: 'https://example.com/my-app'),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _redirectUriController,
              decoration: InputDecoration(
                labelText: t.oauth.redirectUri,
                hintText: t.common.example(
                  value: 'misskeyauth://oauth/callback',
                ),
                helperText: t.oauth.redirectUriHelper,
                helperMaxLines: 2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              t.common.customScopes,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _oauthCustomScopesController,
              decoration: InputDecoration(
                labelText: t.common.example(
                  value: 'write:drive, read:favorites',
                ),
              ),
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _addOAuthCustomScopesFromInput(),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _startAuth,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
                child: Text(t.oauth.submit),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiAuthForm(BuildContext context) {
    final t = context.t;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.miauth.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _callbackSchemeController,
              decoration: InputDecoration(
                labelText: t.common.callbackScheme,
                hintText: t.common.example(value: 'misskeyauth'),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _hostController,
              decoration: InputDecoration(
                labelText: t.common.host,
                hintText: t.common.example(value: 'misskey.io'),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _miAppNameController,
              decoration: InputDecoration(
                labelText: t.miauth.appName,
                hintText: t.common.example(value: 'Misskey Auth Example'),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              t.common.customScopes,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _miCustomScopesController,
              decoration: InputDecoration(
                labelText: t.common.example(
                  value: 'write:drive, read:favorites',
                ),
              ),
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _addMiCustomScopesFromInput(),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _miIconUrlController,
              decoration: InputDecoration(labelText: t.miauth.iconUrl),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _startMiAuth,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
                child: Text(t.miauth.submit),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServerInfoCard() {
    final t = context.t;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.serverInfo.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(t.serverInfo.authorizationEndpoint),
            const SizedBox(height: 4),
            SelectableText(_serverInfo!.authorizationEndpoint),
            const SizedBox(height: 8),
            Text(t.serverInfo.tokenEndpoint),
            const SizedBox(height: 4),
            SelectableText(_serverInfo!.tokenEndpoint),
            if (_serverInfo!.scopesSupported != null &&
                _serverInfo!.scopesSupported!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(t.serverInfo.scopesSupported),
              const SizedBox(height: 4),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 200),
                child: Scrollbar(
                  child: ListView.separated(
                    itemCount: _serverInfo!.scopesSupported!.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final scope = _serverInfo!.scopesSupported![index];
                      return InkWell(
                        onTap: () async {
                          await Clipboard.setData(ClipboardData(text: scope));
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context)
                            ..hideCurrentSnackBar()
                            ..showSnackBar(
                              SnackBar(
                                content: Text(
                                  t.serverInfo.copied(scope: scope),
                                ),
                              ),
                            );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10.0),
                          child: Text(scope),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildServerInfoTab(BuildContext context) {
    final t = context.t;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.serverInfo.checkTitle,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _hostController,
                  decoration: InputDecoration(
                    labelText: t.common.host,
                    hintText: t.common.example(value: 'misskey.io'),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _checkServerInfo,
                    child: Text(t.serverInfo.check),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_serverInfo != null) ...[
          const SizedBox(height: 16),
          _buildServerInfoCard(),
        ],
      ],
    );
  }

  Widget _buildAccountsTab(BuildContext context) {
    final t = context.t;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    t.accounts.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: t.accounts.reload,
                  onPressed: () {
                    setState(() {}); // FutureBuilder を再評価
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            FutureBuilder<List<Object?>>(
              future: Future.wait<Object?>([
                _auth.listAccounts(),
                _auth.getActive(),
              ]),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                if (!snapshot.hasData) {
                  return Text(t.accounts.loadFailed);
                }
                final accounts = (snapshot.data![0] as List<AccountEntry>);
                final active = snapshot.data![1] as AccountKey?;
                if (accounts.isEmpty) {
                  return Text(t.accounts.empty);
                }
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: accounts.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final entry = accounts[index];
                    final key = entry.key;
                    final isActive = active != null && active == key;
                    final title = entry.userName ?? key.accountId;
                    final saved = entry.createdAt != null
                        ? t.accounts.savedAt(
                            date: entry.createdAt!
                                .toLocal()
                                .toString()
                                .substring(0, 19),
                          )
                        : null;
                    return ListTile(
                      leading: Icon(
                        isActive ? Icons.star : Icons.person_outline,
                        color: isActive ? Colors.amber : null,
                      ),
                      title: Text(title),
                      subtitle: Text(
                        '${key.host} / ${key.accountId}${saved != null ? '\n$saved' : ''}',
                      ),
                      isThreeLine: saved != null,
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          await _auth.signOut(key);
                          if (mounted) setState(() {});
                        },
                        tooltip: t.accounts.delete,
                      ),
                      onTap: () async {
                        await _auth.setActive(key);
                        if (mounted) setState(() {});
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context)
                          ..hideCurrentSnackBar()
                          ..showSnackBar(
                            SnackBar(
                              content: Text(
                                t.accounts.activeChanged(
                                  account: key.accountId,
                                ),
                              ),
                            ),
                          );
                      },
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
