import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../model/tablero_meta_model.dart';
import '../../provider/meta_provider.dart';
import '../../share/app_scaffold_key.dart';
import '../../utils/utils.dart';
import 'formato_meta.dart';
import 'gauge_meta.dart';
import 'graficos_meta.dart';

const _notaMeta =
    'Se cuentan las ventas transferidas, sin flete, según su fecha de facturación.';

class MetaPage extends StatefulWidget {
  final MetaProvider? provider;

  const MetaPage({super.key, this.provider});

  @override
  State<MetaPage> createState() => _MetaPageState();
}

class _MetaPageState extends State<MetaPage> {
  late final MetaProvider _provider;
  late Future<TableroMetaModel> _tableroFuture;
  // Último tablero cargado: se sigue mostrando mientras se recarga.
  TableroMetaModel? _ultimo;

  @override
  void initState() {
    super.initState();
    _provider = widget.provider ?? MetaProvider.metaProvider;
    _tableroFuture = _obtener();
  }

  Future<TableroMetaModel> _obtener() async {
    final tablero = await _provider.obtenerMiMeta();
    _ultimo = tablero;
    return tablero;
  }

  Future<void> _recargar() {
    final futuro = _obtener();
    setState(() {
      _tableroFuture = futuro;
    });
    return futuro.then((_) {}, onError: (_) {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () => AppScaffoldKey.homeKey.currentState?.openDrawer(),
        ),
        centerTitle: true,
        backgroundColor: colorRojoBase(),
        title: const Text('Meta', style: TextStyle(color: Colors.white)),
      ),
      body: FutureBuilder<TableroMetaModel>(
        future: _tableroFuture,
        builder: _construir,
      ),
    );
  }

  Widget _construir(
      BuildContext context, AsyncSnapshot<TableroMetaModel> snapshot) {
    final previo = _ultimo;
    if (snapshot.connectionState == ConnectionState.waiting) {
      if (previo != null) return _conRefresco(previo);
      return const Center(child: CircularProgressIndicator());
    }
    final error = snapshot.error;
    if (error is MetaSinVendedorException) {
      return _mensajeCentrado(error.mensaje);
    }
    if (error != null) {
      return _mensajeCentrado('No se pudo cargar tu meta.', reintentar: true);
    }
    return _conRefresco(snapshot.data!);
  }

  Widget _conRefresco(TableroMetaModel t) {
    return RefreshIndicator(
      onRefresh: _recargar,
      child: _contenido(t),
    );
  }

  Widget _mensajeCentrado(String mensaje, {bool reintentar = false}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(mensaje, textAlign: TextAlign.center),
            if (reintentar) ...[
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _recargar,
                child: const Text('Reintentar'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _contenido(TableroMetaModel t) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        if (t.tieneMeta)
          GaugeMeta(
              fraccion: fraccionGauge(t.avance),
              texto: formatearAvance(t.avance),
              cumplida: metaCumplida(t))
        else
          const Center(
            child: Text('Sin meta asignada este mes',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        const SizedBox(height: 12),
        _detalleMes(t),
        const SizedBox(height: 16),
        _cifras(t),
        const SizedBox(height: 24),
        _tituloGrafico('Ventas del mes'),
        GraficoDiarioMeta(tablero: t),
        const SizedBox(height: 24),
        _tituloGrafico('Últimos 12 meses'),
        GraficoMensualMeta(tablero: t),
        const SizedBox(height: 16),
        const Text(_notaMeta,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  Widget _tituloGrafico(String titulo) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(titulo,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
    );
  }

  Widget _detalleMes(TableroMetaModel t) {
    final hora = DateFormat('HH:mm').format(t.calculadoEn.toLocal());
    return Column(
      children: [
        Text(nombreMes(t.periodo),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        Text('${t.cantidadVentas} ventas cerradas'),
        Text('Actualizado a las $hora',
            style: const TextStyle(color: Colors.grey)),
      ],
    );
  }

  Widget _cifras(TableroMetaModel t) {
    final falta = textoFalta(t);
    return Column(
      children: [
        _cifra('Vendido', formatearMonto(t.vendido)),
        if (t.tieneMeta) ...[
          _cifra('Meta', formatearMonto(t.meta!)),
          _cifra('Avance', formatearAvance(t.avance)),
          if (metaCumplida(t))
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('¡Meta cumplida!',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.green)),
            )
          else if (falta != null)
            _cifra('Falta', falta),
        ],
      ],
    );
  }

  Widget _cifra(String titulo, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(titulo, style: const TextStyle(fontSize: 16)),
          Text(valor,
              style:
                  const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
