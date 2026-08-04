import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class ConnectivityProvider extends ChangeNotifier {
  bool _isOnline = true;
  bool get isOnline => _isOnline;

  late StreamSubscription<List<ConnectivityResult>> _subscription;

  ConnectivityProvider() {
    _initConnectivity();
    _subscription = Connectivity().onConnectivityChanged.listen(_updateConnectionStatus);
  }

  Future<void> _initConnectivity() async {
    try {
      final List<ConnectivityResult> result = await Connectivity().checkConnectivity();
      _updateConnectionStatus(result);
    } catch (e) {
      debugPrint('Could not check connectivity: $e');
    }
  }

  void _updateConnectionStatus(List<ConnectivityResult> result) {
    // If any of the results is not 'none', we consider it online
    final bool online = result.any((r) => r != ConnectivityResult.none);
    if (_isOnline != online) {
      _isOnline = online;
      notifyListeners();
      debugPrint('Connection Status Changed: ${_isOnline ? "ONLINE" : "OFFLINE"}');
    }
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
