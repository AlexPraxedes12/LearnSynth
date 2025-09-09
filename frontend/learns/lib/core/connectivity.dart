import 'package:connectivity_plus/connectivity_plus.dart';

Future<bool> hasInternet() async {
  final res = await Connectivity().checkConnectivity();
  return res.contains(ConnectivityResult.mobile) ||
      res.contains(ConnectivityResult.wifi) ||
      res.contains(ConnectivityResult.ethernet);
}
