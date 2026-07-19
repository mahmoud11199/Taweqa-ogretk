import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../config/supabase_config.dart';
import 'local_database.dart';

class SyncService {
  static bool _isSyncing = false;
  static StreamSubscription? _connectivitySub;
  static bool _isOnline = true;
  static final List<void Function(bool)> _listeners = [];

  static bool get isOnline => _isOnline;

  static void addListener(void Function(bool online) listener) {
    _listeners.add(listener);
  }

  static void removeListener(void Function(bool online) listener) {
    _listeners.remove(listener);
  }

  static void _notify(bool online) {
    for (final fn in _listeners) {
      fn(online);
    }
  }

  static Future<void> startMonitoring() async {
    final connectivity = Connectivity();
    final result = await connectivity.checkConnectivity();
    _isOnline = !result.contains(ConnectivityResult.none);
    _notify(_isOnline);

    _connectivitySub = connectivity.onConnectivityChanged.listen((results) {
      final online = !results.contains(ConnectivityResult.none);
      if (online != _isOnline) {
        _isOnline = online;
        _notify(online);
        if (online) {
          syncPending();
        }
      }
    });
  }

  static Future<void> stopMonitoring() async {
    await _connectivitySub?.cancel();
    _connectivitySub = null;
  }

  static Future<void> syncPending() async {
    if (_isSyncing || !_isOnline) return;
    _isSyncing = true;

    try {
      final items = await LocalDatabase.getPendingSyncItems();
      final client = SupabaseConfig.client;

      for (final item in items) {
        try {
          final table = item['table_name'] as String;
          final operation = item['operation'] as String;
          final recordId = item['record_id'] as String?;
          final payload = _decode(item['payload'] as String);

          if (operation == 'insert') {
            await client.from(table).insert(payload);
          } else if (operation == 'update') {
            await client.from(table).update(payload).eq('id', recordId!);
          } else if (operation == 'delete') {
            await client.from(table).delete().eq('id', recordId!);
          }

          await LocalDatabase.removeSyncItem(item['id'] as int);
        } catch (_) {
          // Skip failed items, will retry on next sync
        }
      }
    } finally {
      _isSyncing = false;
    }
  }

  static Map<String, dynamic> _decode(String encoded) {
    try {
      return jsonDecode(encoded) as Map<String, dynamic>;
    } catch (_) {
      return <String, dynamic>{};
    }
  }
}
