import '../services/local_database.dart';
import '../services/sync_service.dart';

class CacheHelper {
  static bool get isOnline => SyncService.isOnline;
  static const Duration _cacheTtl = Duration(hours: 24);
  static const String _cacheMetaKey = 'cache_meta';

  static Future<void> _markCached(String key) async {
    await LocalDatabase.insert(_cacheMetaKey, {
      'id': key,
      'cached_at': DateTime.now().toIso8601String(),
    });
  }

  static Future<void> invalidateCache(String key) async {
    await LocalDatabase.delete(_cacheMetaKey, key);
  }

  static Future<void> clearExpiredCaches() async {
    final db = await LocalDatabase.database;
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name NOT IN ('cache_meta', 'sync_queue')",
    );
    for (final t in tables) {
      final tableName = t['name'] as String;
      final meta = await LocalDatabase.get(_cacheMetaKey, tableName);
      if (meta != null) {
        final cachedAt = DateTime.parse(meta['cached_at'] as String);
        if (DateTime.now().difference(cachedAt) >= _cacheTtl) {
          await db.delete(tableName);
          await LocalDatabase.delete(_cacheMetaKey, tableName);
        }
      }
    }
  }

  static Future<List<Map<String, dynamic>>> fetchWithCache({
    required String table,
    required Future<List<Map<String, dynamic>>> Function() onlineFetch,
    String? cacheKey,
  }) async {
    if (isOnline) {
      try {
        final data = await onlineFetch();
        await _cacheList(table, data, cacheKey: cacheKey);
        if (cacheKey != null) await _markCached(cacheKey);
        return data;
      } catch (_) {
        final cached = await LocalDatabase.query(table, orderBy: 'created_at DESC', limit: 100);
        if (cached.isNotEmpty) return cached;
        rethrow;
      }
    }
    final cached = await LocalDatabase.query(table, orderBy: 'created_at DESC', limit: 100);
    if (cached.isNotEmpty) return cached;
    throw Exception('لا توجد بيانات مخزنة محلياً');
  }

  static Future<Map<String, dynamic>?> fetchSingleWithCache({
    required String table,
    required String id,
    required Future<Map<String, dynamic>?> Function() onlineFetch,
  }) async {
    if (isOnline) {
      try {
        final data = await onlineFetch();
        if (data != null) {
          await LocalDatabase.insert(table, data);
        }
        return data;
      } catch (_) {
        return LocalDatabase.get(table, id);
      }
    }
    return LocalDatabase.get(table, id);
  }

  static Future<void> writeWithSync({
    required String table,
    required String id,
    required Map<String, dynamic> data,
    required Future<void> Function() onlineWrite,
  }) async {
    if (isOnline) {
      try {
        await onlineWrite();
        await LocalDatabase.insert(table, data);
      } catch (_) {
        await LocalDatabase.insert(table, data);
        await LocalDatabase.addToSyncQueue(table, 'update', id, data);
      }
    } else {
      await LocalDatabase.insert(table, data);
      await LocalDatabase.addToSyncQueue(table, 'update', id, data);
    }
  }

  static Future<void> insertWithSync({
    required String table,
    required Map<String, dynamic> data,
    required Future<void> Function() onlineInsert,
  }) async {
    if (isOnline) {
      try {
        await onlineInsert();
        await LocalDatabase.insert(table, data);
      } catch (_) {
        await LocalDatabase.insert(table, data);
        await LocalDatabase.addToSyncQueue(table, 'insert', data['id'] as String, data);
      }
    } else {
      await LocalDatabase.insert(table, data);
      await LocalDatabase.addToSyncQueue(table, 'insert', data['id'] as String, data);
    }
  }

  static Future<void> _cacheList(String table, List<Map<String, dynamic>> items, {String? cacheKey}) async {
    for (final item in items) {
      try {
        await LocalDatabase.insert(table, item);
      } catch (_) {}
    }
  }
}
