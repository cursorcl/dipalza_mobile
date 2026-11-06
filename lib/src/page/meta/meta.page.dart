import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../model/tablero_meta_model.dart';
import '../../provider/meta_provider.dart';
import '../../share/app_scaffold_key.dart';
import '../../utils/utils.dart';
import 'formato_meta.dart';
import 'graficos_meta.dart';

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
    // setState para que el título del AppBar (el mes) se actualice.
    if (mounted) setState(() => _ultimo = tablero);
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
        // El título es el mes del tablero ("Noviembre 2026"); mientras no
        // haya datos, "Meta".
        title: Text(
          _ultimo != null ? nombreMes(_ultimo!.periodo) : 'Meta',
          style: const TextStyle(color: Colors.white),
        ),
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
        _graficosEnTabs(t),
        const SizedBox(height: 24),
        if (!t.tieneMeta)
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Center(
              child: Text('Sin meta asignada este mes',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
        _cifras(t),
        const SizedBox(height: 16),
        _detalleMes(t),
      ],
    );
  }

  Widget _graficosEnTabs(TableroMetaModel t) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            labelColor: colorRojoBase(),
            indicatorColor: colorRojoBase(),
            unselectedLabelColor: Colors.grey,
            tabs: const [
              Tab(text: 'Ventas del mes'),
              Tab(text: 'Últimos 12 meses'),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 300,
            child: TabBarView(
              children: [
                _contenedorGrafico(GraficoDiarioMeta(tablero: t)),
                _contenedorGrafico(GraficoMensualMeta(tablero: t)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _contenedorGrafico(Widget grafico) {
    return Container(
      key: const Key('contenedor-grafico'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: grafico,
    );
  }

  Widget _detalleMes(TableroMetaModel t) {
    final hora = DateFormat('HH:mm').format(t.calculadoEn.toLocal());
    return Column(
      children: [
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
