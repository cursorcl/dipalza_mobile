import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:dipalza_movil/src/share/prefs_usuario.dart';
import 'package:flutter/material.dart';

enum ServerStatus { online, offline, noInternet, connecting }

class ConnectivityService with ChangeNotifier {
  ServerStatus _status = ServerStatus.connecting;
  Timer? _timer;
  final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 5),
  ));

  ServerStatus get status => _status;

  void initialize() {
    _checkStatus();
    _timer = Timer.periodic(
        const Duration(seconds: 15), (_) async => _checkStatus());
  }

  Future<void> _checkStatus() async {
    final connectivityResult = await (Connectivity().checkConnectivity());
    ServerStatus newStatus;

    if (connectivityResult.contains(ConnectivityResult.none)) {
      newStatus = ServerStatus.noInternet;
    } else {
      final isServerOnline = await _isServerReachable();
      newStatus = isServerOnline ? ServerStatus.online : ServerStatus.offline;
    }

    if (newStatus != _status) {
      _status = newStatus;
      notifyListeners();
    }
  }

  Future<bool> _isServerReachable() async {
    final prefs = PreferenciasUsuario();

    try {
      final response = await _dio.get('${prefs.urlBase}/ping');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
