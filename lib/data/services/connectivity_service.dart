import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:logger/logger.dart';

class ConnectivityService {
  final Logger _logger = Logger();
  Stream<ConnectivityResult> get connectivityStream =>
      Connectivity().onConnectivityChanged.map((results) => results.first);

  Future<bool> isConnected() async {
    final result = await Connectivity().checkConnectivity();
    final isConnected = result.isNotEmpty && result.first != ConnectivityResult.none;
    _logger.i('Connectivity check: ${isConnected ? "Connected" : "Offline"}');
    return isConnected;
  }
}