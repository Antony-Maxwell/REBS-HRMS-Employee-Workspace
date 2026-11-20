import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();

  StreamSubscription<List<ConnectivityResult>>? _subscription;

  void startListening({required Future<void> Function() onConnected}) {
    _subscription?.cancel();

    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      final isConnected = results.any(
        (result) => result != ConnectivityResult.none,
      );

      if (isConnected) {
        onConnected();
      }
    });
  }

  Future<bool> hasConnection() async {
    final results = await _connectivity.checkConnectivity();

    return results.any((result) => result != ConnectivityResult.none);
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
  }
}
