import 'dart:async';
import 'dart:io';

/// Monitora continuamente se há conexão com a internet.
class ConnectivityService {
  static StreamController<bool>? _controller;
  static Timer? _timer;
  static bool _lastStatus = false;

  /// Inicia o monitoramento. O stream emite `true` quando
  /// a internet está disponível e `false` quando não está.
  static Stream<bool> startMonitoring() {
    _controller?.close();
    _controller = StreamController<bool>.broadcast();

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) async {
      final connected = await _checkConnection();
      if (connected != _lastStatus) {
        _lastStatus = connected;
        _controller?.add(connected);
      }
    });

    return _controller!.stream;
  }

  static void stopMonitoring() {
    _timer?.cancel();
    _controller?.close();
    _controller = null;
  }

  static Future<bool> _checkConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 3));
      return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> isConnected() => _checkConnection();
}
