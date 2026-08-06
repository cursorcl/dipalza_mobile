import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../share/prefs_usuario.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  late Dio dio;
  late Dio dioRefresh;
  final pref = PreferenciasUsuario();

  bool _isRefreshing = false;
  bool _sessionNotified = false;
  final List<Completer<bool>> _refreshQueue = [];

  final _sessionExpiredController = StreamController<void>.broadcast();
  Stream<void> get onSessionExpired => _sessionExpiredController.stream;

  // Singleton
  factory ApiClient() => _instance;

  ApiClient._internal() {
    // Dio exige una URL válida al construir BaseOptions, incluso si el
    // servidor todavía no se ha configurado (primera vez que corre la
    // app: ver ServerSetupPage). Se usa un placeholder válido y, una vez
    // que el usuario guarda la URL real, ServerSetupPage actualiza
    // `dio.options.baseUrl` sobre esta misma instancia.
    final urlBase = pref.urlBase;
    dio = Dio(BaseOptions(
      baseUrl: urlBase.isEmpty ? 'http://localhost' : urlBase,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ));

    dioRefresh = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ));

    dio.interceptors.add(QueuedInterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = pref.access_token;
        options.headers['Authorization'] = 'Bearer $token';
        return handler.next(options);
      },
      onError: (DioException e, handler) async {
        if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
          try {
            final bool renovado = await _refreshTokenIfNeeded();
            if (renovado) {
              final options = e.requestOptions;
              options.headers['Authorization'] = 'Bearer ${pref.access_token}';
              final response = await dio.fetch(options);
              return handler.resolve(response);
            } else if (!_sessionNotified) {
              _sessionNotified = true;
              _sessionExpiredController.add(null);
            }
          } catch (err) {
            debugPrint("Error durante refresh token: $err");
            if (!_sessionNotified) {
              _sessionNotified = true;
              _sessionExpiredController.add(null);
            }
          }
        }
        return handler.next(e);
      },
    ));
  }

  Future<bool> _refreshTokenIfNeeded() async {
    if (_isRefreshing) {
      final completer = Completer<bool>();
      _refreshQueue.add(completer);
      return completer.future.timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          _refreshQueue.remove(completer);
          return false;
        },
      );
    }

    _isRefreshing = true;
    try {
      final result = await renovarToken();
      if (result) {
        _sessionNotified = false;
      }
      for (final completer in _refreshQueue) {
        if (!completer.isCompleted) {
          completer.complete(result);
        }
      }
      _refreshQueue.clear();
      return result;
    } catch (e) {
      for (final completer in _refreshQueue) {
        if (!completer.isCompleted) {
          completer.complete(false);
        }
      }
      _refreshQueue.clear();
      rethrow;
    } finally {
      _isRefreshing = false;
    }
  }

  Future<bool> renovarToken() async {
    try {
      final refreshToken = pref.refreshToken;
      if (refreshToken.isEmpty) return false;

      final resp = await dioRefresh
          .post(
            '${pref.urlBase}/auth/refresh',
            data: {'refreshToken': refreshToken},
            options: Options(contentType: Headers.jsonContentType),
          )
          .timeout(const Duration(seconds: 15));

      if (resp.statusCode == 200) {
        final nuevoAccessToken = resp.data['accessToken'];
        final nuevoRefreshToken = resp.data['refreshToken'];

        pref.access_token = nuevoAccessToken;
        if (nuevoRefreshToken != null) {
          pref.refreshToken = nuevoRefreshToken;
        }

        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Error en renovación automática: $e");
      return false;
    }
  }

  Future<void> logout() async {
    pref.borrarCredenciales();
    _sessionExpiredController.add(null);
  }

  void dispose() {
    _sessionExpiredController.close();
  }
}
