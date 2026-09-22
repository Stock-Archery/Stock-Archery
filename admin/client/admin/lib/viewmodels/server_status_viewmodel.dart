import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../services/app_config.dart';

enum ServerAwakeState { unknown, checking, waking, awake }

/// Pings the admin server health endpoint (`GET /`).
/// First tap does one quick check; if the server is asleep (Render cold
/// start), it keeps polling in the background with increasing backoff
/// until the server responds.
class ServerStatusViewModel extends ChangeNotifier {
  ServerAwakeState _state = ServerAwakeState.unknown;
  ServerAwakeState get state => _state;

  int _attempt = 0;
  int get attempt => _attempt;

  int _generation = 0;
  bool _disposed = false;

  /// Seconds to wait between retries. Caps at 30s, repeats until awake.
  static const List<int> _backoffs = [3, 6, 12, 20, 30];

  bool get isBusy =>
      _state == ServerAwakeState.checking ||
      _state == ServerAwakeState.waking;

  Future<bool> _ping() async {
    try {
      final res = await http
          .get(Uri.parse('${AppConfig.baseUrl}/'))
          .timeout(const Duration(seconds: 15));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<void> check() async {
    if (isBusy) return;
    final gen = ++_generation;
    _attempt = 0;
    _state = ServerAwakeState.checking;
    _notify();

    // First attempt: fast path when server is already awake.
    if (await _ping()) {
      if (gen != _generation) return;
      _state = ServerAwakeState.awake;
      _notify();
      return;
    }

    // Server asleep — enter polling loop with progressive backoff.
    if (gen != _generation) return;
    _state = ServerAwakeState.waking;
    _attempt = 1;
    _notify();

    var backoffIndex = 0;
    while (gen == _generation) {
      final delay = _backoffs[backoffIndex < _backoffs.length
          ? backoffIndex
          : _backoffs.length - 1];
      await Future.delayed(Duration(seconds: delay));
      if (gen != _generation) return;
      _attempt++;
      _notify();
      if (await _ping()) {
        if (gen != _generation) return;
        _state = ServerAwakeState.awake;
        _notify();
        return;
      }
      backoffIndex++;
    }
  }

  void cancel() {
    _generation++;
    _state = ServerAwakeState.unknown;
    _attempt = 0;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    super.dispose();
  }
}
