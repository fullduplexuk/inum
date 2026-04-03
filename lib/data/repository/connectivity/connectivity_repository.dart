import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:inum/core/interfaces/i_connectivity_repository.dart';

class ConnectivityRepository implements IConnectivityRepository {
  final Connectivity _connectivity;

  ConnectivityRepository(this._connectivity);

  @override
  Stream<ConnectivityResult> get connectivityStateChanges {
    try {
      return _connectivity.onConnectivityChanged.map(_extractSingleResult);
    } catch (e) {
      debugPrint('Error monitoring connectivity changes: $e');
      return Stream.value(ConnectivityResult.none);
    }
  }

  @override
  Future<ConnectivityResult> checkConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      return _extractSingleResult(results);
    } catch (e) {
      debugPrint('Error checking current connectivity: $e');
      return ConnectivityResult.none;
    }
  }

  ConnectivityResult _extractSingleResult(List<ConnectivityResult> results) {
    if (results.contains(ConnectivityResult.mobile)) {
      return ConnectivityResult.mobile;
    } else if (results.contains(ConnectivityResult.wifi)) {
      return ConnectivityResult.wifi;
    } else if (results.contains(ConnectivityResult.ethernet)) {
      return ConnectivityResult.ethernet;
    } else if (results.isNotEmpty) {
      return results.first;
    } else {
      return ConnectivityResult.none;
    }
  }
}
