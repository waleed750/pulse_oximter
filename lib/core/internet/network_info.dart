import 'package:internet_connection_checker/internet_connection_checker.dart';

abstract class NetworkInfo {
   Future<bool> isConnected();
}
class NetworkInfoImpl extends NetworkInfo {
  @override
  Future<bool> isConnected() async => await InternetConnectionChecker().hasConnection;
}