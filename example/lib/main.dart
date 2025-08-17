import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:misskey_auth/misskey_auth.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Misskey Auth Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: LoaderOverlay(
        child: const AuthExamplePage(),
      ),
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
    // MisskeyAuth のカスタム例外をユーザー向け日本語に整形
    if (error is MisskeyAuthException) {
      final details = error.details;
      if (error is UserCancelledException) {
        return '認証がキャンセルされました';
      }
      if (error is CallbackSchemeErrorException) {
        return 'コールバックスキームの設定が正しくありません（AndroidManifest/Info.plist を確認してください）';
      }
      if (error is AuthorizationLaunchException) {
        return '認証画面を起動できませんでした';
      }
      if (error is NetworkException) {
        return 'ネットワークエラーが発生しました';
      }
      if (error is ResponseParseException) {
        return 'サーバー応答の解析に失敗しました';
      }
      if (error is SecureStorageException) {
        return 'セキュアストレージの操作に失敗しました';
      }
      if (error is InvalidAuthConfigException) {
        return '認証設定が無効です';
      }
      if (error is ServerInfoException) {
        return 'サーバー情報の取得に失敗しました${details != null ? ': $details' : ''}';
      }
      // OAuth
      if (error is OAuthNotSupportedException) {
        return 'このサーバーはOAuth認証に対応していません（MiAuthをご利用ください）';
      }
      if (error is StateMismatchException) {
        return 'セキュリティ検証に失敗しました（state不一致）';
      }
      if (error is AuthorizationCodeMissingException) {
        return '認証コードを取得できませんでした';
      }
      if (error is AuthorizationServerErrorException) {
        return '認可サーバーでエラーが発生しました${details != null ? ': $details' : ''}';
      }
      if (error is TokenExchangeException) {
        return 'トークン交換に失敗しました${details != null ? ': $details' : ''}';
      }
      // MiAuth
      if (error is MiAuthDeniedException) {
        return 'MiAuth がキャンセル/拒否されました';
      }
      if (error is MiAuthCheckFailedException) {
        return 'MiAuth の検証に失敗しました${details != null ? ': $details' : ''}';
      }
      if (error is MiAuthSessionInvalidException) {
        return 'MiAuth のセッションが無効または期限切れです${details != null ? ': $details' : ''}';
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
        'https://librarylibrarian.github.io/misskey_auth/';
    _redirectUriController.text =
        'https://librarylibrarian.github.io/misskey_auth/redirect.html';
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
        throw Exception('ホストを入力してください');
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
            const SnackBar(
                content: Text('OAuth認証はサポートされていません（MiAuth認証を使用してください）')),
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

      final key = await _auth.loginWithOAuth(config, setActive: true);
      if (kDebugMode) {
        final t = await _auth.tokenOf(key);
        developer
            .log('[OAuth] account=${key.accountId} token=${t?.accessToken}');
      }

      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(content: Text('認証に成功しました！')));
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
          ..showSnackBar(SnackBar(content: Text('認証エラー: $e')));
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
        throw Exception('ホストを入力してください');
      }

      final scheme = _callbackSchemeController.text.trim();
      if (scheme.isEmpty) {
        throw Exception('コールバックスキームを入力してください');
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

      final key = await _auth.loginWithMiAuth(config, setActive: true);
      if (kDebugMode) {
        final t = await _auth.tokenOf(key);
        developer
            .log('[MiAuth] account=${key.accountId} token=${t?.accessToken}');
      }

      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(content: Text('MiAuth に成功しました！')));
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
          ..showSnackBar(SnackBar(content: Text('MiAuth エラー: $e')));
      }
    } finally {
      if (mounted) {
        context.loaderOverlay.hide();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
        destinations: const [
          NavigationDestination(icon: Icon(Icons.lock), label: 'OAuth'),
          NavigationDestination(icon: Icon(Icons.vpn_key), label: 'MiAuth'),
          NavigationDestination(
              icon: Icon(Icons.info_outline), label: 'サーバー情報'),
          NavigationDestination(icon: Icon(Icons.people), label: 'アカウント一覧'),
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'OAuth認証設定',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _callbackSchemeController,
              decoration: const InputDecoration(
                labelText: 'コールバックスキーム',
                hintText: '例: misskeyauth',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _hostController,
              decoration: const InputDecoration(
                labelText: 'ホスト',
                hintText: '例: misskey.io',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _clientIdController,
              decoration: const InputDecoration(
                labelText: 'クライアントID (URL)',
                hintText: '例: https://example.com/my-app',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _redirectUriController,
              decoration: const InputDecoration(
                labelText: 'リダイレクトURI',
                hintText: '例: https://example.com/redirect',
                helperText: '要HTTPS',
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'カスタムスコープ（カンマ区切り）',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _oauthCustomScopesController,
              decoration: const InputDecoration(
                labelText: '例: write:drive, read:favorites',
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
                child: const Text('OAuthで認証'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiAuthForm(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'MiAuth認証設定',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _callbackSchemeController,
              decoration: const InputDecoration(
                labelText: 'コールバックスキーム',
                hintText: '例: misskeyauth',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _hostController,
              decoration: const InputDecoration(
                labelText: 'ホスト',
                hintText: '例: misskey.io',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _miAppNameController,
              decoration: const InputDecoration(
                labelText: 'アプリ名',
                hintText: '例: Misskey Auth Example',
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'カスタムスコープ（カンマ区切り）',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _miCustomScopesController,
              decoration: const InputDecoration(
                labelText: '例: write:drive, read:favorites',
              ),
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _addMiCustomScopesFromInput(),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _miIconUrlController,
              decoration: const InputDecoration(
                labelText: 'アイコンURL（任意）',
              ),
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
                child: const Text('MiAuthで認証'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServerInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'サーバー情報',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('認証エンドポイント'),
            const SizedBox(height: 4),
            SelectableText(_serverInfo!.authorizationEndpoint),
            const SizedBox(height: 8),
            const Text('トークンエンドポイント'),
            const SizedBox(height: 4),
            SelectableText(_serverInfo!.tokenEndpoint),
            if (_serverInfo!.scopesSupported != null &&
                _serverInfo!.scopesSupported!.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text('サポートされているスコープ（タップでコピー）'),
              const SizedBox(height: 4),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 200),
                child: Scrollbar(
                  child: ListView.separated(
                    itemCount: _serverInfo!.scopesSupported!.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final scope = _serverInfo!.scopesSupported![index];
                      return InkWell(
                        onTap: () async {
                          await Clipboard.setData(ClipboardData(text: scope));
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context)
                            ..hideCurrentSnackBar()
                            ..showSnackBar(
                              SnackBar(content: Text('コピーしました: $scope')),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'サーバー情報の確認',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _hostController,
                  decoration: const InputDecoration(
                    labelText: 'ホスト',
                    hintText: '例: misskey.io',
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _checkServerInfo,
                    child: const Text('サーバー情報を確認'),
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'ログイン済みアカウント',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: '再読込',
                  onPressed: () {
                    setState(() {}); // FutureBuilder を再評価
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.bug_report),
                  tooltip: 'デバッグログにトークンを出力',
                  onPressed: () async {
                    if (!kDebugMode) return;
                    final accounts = await _auth.listAccounts();
                    for (final entry in accounts) {
                      final key = entry.key;
                      final t = await _auth.tokenOf(key);
                      developer.log(
                          '[Dump] ${key.host}/${key.accountId} token=${t?.accessToken}');
                    }
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(
                        const SnackBar(content: Text('デバッグログにトークンを出力しました')),
                      );
                  },
                )
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
                  ));
                }
                if (!snapshot.hasData) {
                  return const Text('アカウント情報を取得できませんでした');
                }
                final accounts = (snapshot.data![0] as List<AccountEntry>);
                final active = snapshot.data![1] as AccountKey?;
                if (accounts.isEmpty) {
                  return const Text('ログイン済みのアカウントはありません');
                }
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: accounts.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final entry = accounts[index];
                    final key = entry.key;
                    final isActive = active != null && active == key;
                    final title = entry.userName ?? key.accountId;
                    final saved = entry.createdAt != null
                        ? '保存: ${entry.createdAt!.toLocal().toString().substring(0, 19)}'
                        : null;
                    return ListTile(
                      leading: Icon(
                          isActive ? Icons.star : Icons.person_outline,
                          color: isActive ? Colors.amber : null),
                      title: Text(title),
                      subtitle: Text(
                          '${key.host} / ${key.accountId}${saved != null ? '\n$saved' : ''}'),
                      isThreeLine: saved != null,
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          await _auth.signOut(key);
                          if (mounted) setState(() {});
                        },
                        tooltip: 'このアカウントを削除',
                      ),
                      onTap: () async {
                        await _auth.setActive(key);
                        if (mounted) setState(() {});
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context)
                          ..hideCurrentSnackBar()
                          ..showSnackBar(
                            SnackBar(
                                content: Text('デフォルトを変更: ${key.accountId}')),
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
