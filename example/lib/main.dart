import 'package:flutter/material.dart';
import 'package:misskey_auth/misskey_auth.dart';
import 'package:loader_overlay/loader_overlay.dart';

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
  final _client = MisskeyOAuthClient();
  final _miClient = MisskeyMiAuthClient();
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
  String? _accessToken;
  OAuthServerInfo? _serverInfo;

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
    _loadStoredToken();
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
  }

  Future<void> _loadStoredToken() async {
    try {
      final token = await _client.getStoredAccessToken();
      setState(() {
        _accessToken = token;
      });
    } on MisskeyAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_mapErrorToMessage(e))),
        );
      }
    } catch (_) {}
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

      final serverInfo = await _client.getOAuthServerInfo(host);

      if (!mounted) return;
      setState(() {
        _serverInfo = serverInfo;
      });

      if (serverInfo == null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('OAuth認証はサポートされていません（MiAuth認証を使用してください）')),
        );
      }
    } on MisskeyAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_mapErrorToMessage(e))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
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
      final config = MisskeyOAuthConfig(
        host: _hostController.text.trim(),
        clientId: _clientIdController.text.trim(),
        redirectUri: _redirectUriController.text.trim(),
        scope: _scopeController.text.trim(),
        callbackScheme: _callbackSchemeController.text.trim(),
      );

      final tokenResponse = await _client.authenticate(config);

      if (tokenResponse != null && mounted) {
        setState(() {
          _accessToken = tokenResponse.accessToken;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('認証に成功しました！')),
          );
        }
      }
    } on MisskeyAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_mapErrorToMessage(e))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('認証エラー: $e')),
        );
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

      final res = await _miClient.authenticate(config);

      if (mounted) {
        setState(() {
          _accessToken = res.token;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('MiAuth に成功しました！')),
          );
        }
      }
    } on MisskeyAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_mapErrorToMessage(e))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('MiAuth エラー: $e')),
        );
      }
    } finally {
      if (mounted) {
        context.loaderOverlay.hide();
      }
    }
  }

  Future<void> _clearToken() async {
    if (!mounted) return;
    context.loaderOverlay.show();

    try {
      await _client.clearTokens();
      await _loadStoredToken();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('トークンを削除しました')),
        );
      }
    } on MisskeyAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_mapErrorToMessage(e))),
        );
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
            _buildStoredTokenCard(),
            const SizedBox(height: 16),
            if (_currentIndex == 0)
              _buildOAuthForm(context)
            else if (_currentIndex == 1)
              _buildMiAuthForm(context)
            else
              _buildServerInfoTab(context),
            // 画面内のエラーカード表示は行わず、Snackbarのみで通知
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
        ],
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }

  Widget _buildStoredTokenCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '保存されたトークン',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(_accessToken != null
                ? '${_accessToken!.substring(0, 10)}...'
                : 'トークンなし'),
            if (_accessToken != null) ...[
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _clearToken,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('トークンを削除'),
              ),
            ],
          ],
        ),
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
            const SizedBox(height: 16),
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
            TextField(
              controller: _scopeController,
              decoration: const InputDecoration(
                labelText: 'スコープ',
                hintText: '例: read:account write:notes',
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _startAuth,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('認証を開始'),
                ),
              ],
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
            TextField(
              controller: _miPermissionsController,
              decoration: const InputDecoration(
                labelText: '権限（空白/カンマ区切り）',
                hintText: '例: read:account write:notes',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _miIconUrlController,
              decoration: const InputDecoration(
                labelText: 'アイコンURL（任意）',
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _startMiAuth,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('MiAuthで認証'),
                ),
              ],
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
            Text('認証エンドポイント:\n${_serverInfo!.authorizationEndpoint}'),
            const SizedBox(height: 4),
            Text('トークンエンドポイント:\n${_serverInfo!.tokenEndpoint}'),
            if (_serverInfo!.scopesSupported != null) ...[
              const SizedBox(height: 4),
              Text(
                  'サポートされているスコープ:\n${_serverInfo!.scopesSupported!.join(', ')}'),
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
                ElevatedButton(
                  onPressed: _checkServerInfo,
                  child: const Text('サーバー情報を確認'),
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

  // 画面内のエラーカードは廃止（Snackbarのみ使用）
}
