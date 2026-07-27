import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  static final Connectivity _connectivity = Connectivity();
  static bool _isOnline = true;
  static StreamSubscription<List<ConnectivityResult>>? _subscription;

  static bool get isOnline => _isOnline;

  static void init({void Function(bool online)? onChanged}) {
    _connectivity.checkConnectivity().then((result) {
      _isOnline = !result.contains(ConnectivityResult.none);
    });
    _subscription = _connectivity.onConnectivityChanged.listen((result) {
      _isOnline = !result.contains(ConnectivityResult.none);
      onChanged?.call(_isOnline);
    });
  }

  static void dispose() {
    _subscription?.cancel();
  }
}
