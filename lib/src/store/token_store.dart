import 'account_key.dart';
import 'stored_token.dart';

/// トークン保存の抽象インターフェース
///
/// - 複数アカウントの並行管理を前提とし、`AccountKey` を主キーとして扱う
/// - 実装は `SecureTokenStore` を既定とし、アプリ側で差し替え可能
abstract class TokenStore {
  /// トークンを保存または更新（存在すれば上書き）
  Future<void> upsert(AccountKey key, StoredToken token);

  /// 指定アカウントのトークンを取得（未保存なら `null`）
  Future<StoredToken?> read(AccountKey key);

  /// 保存済みアカウントの一覧を取得
  Future<List<AccountEntry>> list();

  /// 指定アカウントのトークンを削除
  Future<void> delete(AccountKey key);

  /// すべてのアカウントのトークンを削除
  Future<void> clearAll();

  /// アクティブ（デフォルト）アカウントを設定
  Future<void> setActive(AccountKey? key);

  /// 現在のアクティブ（デフォルト）アカウントを取得
  Future<AccountKey?> getActive();
}
