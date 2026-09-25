import 'dart:async';

import 'package:dipalza_movil/src/model/clientes_model.dart';
import 'package:dipalza_movil/src/provider/cliente_provider.dart';
import 'package:dipalza_movil/src/share/cached_list_store.dart';
import 'package:dipalza_movil/src/share/prefs_usuario.dart';
import 'package:rxdart/rxdart.dart';

class ClientesBloc {
  static final ClientesBloc _singleton = ClientesBloc._internal();

  factory ClientesBloc() => _singleton;

  ClientesBloc._internal();

  static const _ttl = Duration(minutes: 30);

  final _clientesController = BehaviorSubject<List<ClientesModel>>();

  Stream<List<ClientesModel>> get clientesStream => _clientesController.stream;

  List<ClientesModel> get clientesList => _clientesController.valueOrNull ?? [];

  CachedListStore<ClientesModel> get _store => CachedListStore<ClientesModel>(
        key: 'cache_clientes_${PreferenciasUsuario().vendedor}',
        toJsonString: clientesModelToJson,
        fromJsonString: clientesModelFromJson,
      );

  Future<void> ensureFresh() async {
    final cached = await _store.read();
    if (cached != null) {
      _clientesController.sink.add(cached.items);
      if (!cached.isStale(_ttl)) return;
    }
    await _refrescarDesdeRed();
  }

  Future<void> forceRefresh() => _refrescarDesdeRed();

  /// Busca y devuelve una LISTA de clientes que coincidan con el término,
  /// por razón social o código. Búsqueda local sobre la lista ya cacheada
  /// (ver [ensureFresh]), sin ir a red.
  List<ClientesModel> searchClientes(String termino) {
    if (termino.isEmpty) return [];

    final listaCompleta = _clientesController.valueOrNull;
    if (listaCompleta == null || listaCompleta.isEmpty) return [];

    final terminoUpper = termino.toUpperCase();

    return listaCompleta.where((cliente) {
      final razonMatch = cliente.razon.toUpperCase().contains(terminoUpper);
      final codigoMatch = cliente.codigo.toUpperCase().contains(terminoUpper);
      return razonMatch || codigoMatch;
    }).toList();
  }

  Future<void> _refrescarDesdeRed() async {
    final prefs = PreferenciasUsuario();
    try {
      final lista = await ClientesProvider.clientesProvider
          .obtenerListaClientes(prefs.vendedor, prefs.ruta);
      _clientesController.sink.add(lista);
      await _store.write(lista);
    } catch (error) {
      if (_clientesController.valueOrNull == null) {
        _clientesController.addError(error);
      }
    }
  }
}
