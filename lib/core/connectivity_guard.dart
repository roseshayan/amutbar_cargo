import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityGuard {
  static Future<bool> hasInternet() async {
    final results = await Connectivity().checkConnectivity();

    return !results.contains(ConnectivityResult.none);
  }

  static Future<bool> isVpnOn() async {
    final results = await Connectivity().checkConnectivity();

    return results.contains(ConnectivityResult.vpn);
  }
}
