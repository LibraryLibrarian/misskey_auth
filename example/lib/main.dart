import 'package:flutter/material.dart';
import 'package:misskey_auth/misskey_auth.dart';

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
      home: const AuthExamplePage(),
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

  // フォームコントローラー
  final _hostController = TextEditingController();
  final _clientIdController = TextEditingController();
  final _redirectUriController = TextEditingController();
  final _scopeController = TextEditingController();
  final _callbackSchemeController = TextEditingController();

  // 状態
  bool _isLoading = false;
  String? _accessToken;
  String? _errorMessage;
  OAuthServerInfo? _serverInfo;

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
  }

  Future<void> _loadStoredToken() async {
    final token = await _client.getStoredAccessToken();
    setState(() {
      _accessToken = token;
    });
  }

  Future<void> _checkServerInfo() async {
    setState(() {
      _isLoading = true;
      _serverInfo = null;
      _errorMessage = null;
    });

    try {
      final host = _hostController.text.trim();
      if (host.isEmpty) {
        throw Exception('ホストを入力してください');
      }

      final serverInfo = await _client.getOAuthServerInfo(host);

      setState(() {
        _serverInfo = serverInfo;
        if (serverInfo == null) {
          _errorMessage = 'OAuth認証はサポートされていません（MiAuth認証を使用してください）';
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'エラー: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _startAuth() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final config = MisskeyOAuthConfig(
        host: _hostController.text.trim(),
        clientId: _clientIdController.text.trim(),
        redirectUri: _redirectUriController.text.trim(),
        scope: _scopeController.text.trim(),
        callbackScheme: _callbackSchemeController.text.trim(),
      );

      final tokenResponse = await _client.authenticate(config);

      if (tokenResponse != null) {
        setState(() {
          _accessToken = tokenResponse.accessToken;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('認証に成功しました！')),
          );
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('認証エラー: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _clearToken() async {
    await _client.clearTokens();
    await _loadStoredToken();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('トークンを削除しました')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Misskey Auth Example'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 保存されたトークン情報
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '保存されたトークン',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(_accessToken != null
                        ? 'トークンあり: ${_accessToken!.substring(0, 10)}...'
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
            ),

            const SizedBox(height: 16),

            // 認証設定フォーム
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'OAuth認証設定',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                        helperText: 'Misskey OAuth 2.0では有効なURLを指定する必要があります',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _redirectUriController,
                      decoration: const InputDecoration(
                        labelText: 'リダイレクトURI',
                        hintText: '例: https://example.com/redirect',
                        helperText: 'HTTPSのURLを指定してください',
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
                    const SizedBox(height: 8),
                    TextField(
                      controller: _callbackSchemeController,
                      decoration: const InputDecoration(
                        labelText: 'コールバックスキーム',
                        hintText: '例: misskeyauth',
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: _isLoading ? null : _checkServerInfo,
                          child: const Text('サーバー情報を確認'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _startAuth,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('認証を開始'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // サーバー情報
            if (_serverInfo != null) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'サーバー情報',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
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
              ),
            ],

            // エラーメッセージ
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Card(
                color: Colors.red[50],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'エラー',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // ローディング
            if (_isLoading) ...[
              const SizedBox(height: 16),
              const Center(
                child: CircularProgressIndicator(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
