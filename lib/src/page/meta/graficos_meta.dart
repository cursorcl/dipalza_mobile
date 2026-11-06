import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../model/tablero_meta_model.dart';
import '../../utils/utils.dart';
import 'formato_meta.dart';

const _meses = [
  'ene', 'feb', 'mar', 'abr', 'may', 'jun',
  'jul', 'ago', 'sep', 'oct', 'nov', 'dic', //
];

/// "2025-12" -> "dic". Tabla fija: no depende de la inicialización del locale.
String etiquetaMes(String periodo) {
  final mes = int.parse(periodo.split('-')[1]);
  return _meses[mes - 1];
}

/// Un grupo por día del mes, con `x` = día del mes.
List<BarChartGroupData> gruposDiarios(TableroMetaModel t) {
  return t.diario
      .map((d) => BarChartGroupData(
            x: d.fecha.day,
            barRods: [
              BarChartRodData(
                toY: d.vendido,
                width: 6,
                color: colorRojoBase(),
                borderRadius: BorderRadius.circular(1),
              ),
            ],
          ))
      .toList();
}

/// Meta diaria promedio (meta / días del mes), solo para presentación en la
/// línea horizontal del gráfico. la única división sobre montos en la app (solo presentación); el avance
/// siempre lo calcula el server.
double? metaDiariaPromedio(TableroMetaModel t) {
  if (!t.tieneMeta || t.diario.isEmpty) return null;
  return t.meta! / t.diario.length;
}

/// Tope del eje Y del gráfico diario: incluye la barra más alta y la meta
/// diaria promedio (con 10 % de holgura) para que la línea de meta no quede
/// fuera del área visible. Si todo es 0 devuelve 1.
double maxYDiario(TableroMetaModel t) {
  var maximo = metaDiariaPromedio(t) ?? 0;
  for (final d in t.diario) {
    if (d.vendido > maximo) maximo = d.vendido;
  }
  return maximo <= 0 ? 1 : maximo * 1.1;
}

/// 12 grupos (uno por mes). Si la meta del mes es > 0, el grupo agrega una
/// segunda barra gris con la meta junto a la del vendido; el mes en curso (el
/// último) se resalta.
/// Etiqueta del tooltip de la barra [rod] del mes: con meta, la barra 0 es la
/// meta y la 1 lo vendido; sin meta, la única barra es lo vendido.
String etiquetaBarraMensual(VendidoMesModel m, int rod) =>
    tieneMetaMes(m) && rod == 0 ? 'Meta' : 'Vendido';

/// El mes tiene meta para dibujar (> 0).
bool tieneMetaMes(VendidoMesModel m) => (m.meta ?? 0) > 0;

List<BarChartGroupData> gruposMensuales(TableroMetaModel t) {
  final ultimo = t.mensual.length - 1;
  return [
    for (var i = 0; i < t.mensual.length; i++)
      BarChartGroupData(
        x: i,
        barsSpace: 2,
        // Dos barras por mes, lado a lado: primero la meta (solo si hay)
        // y después lo vendido.
        barRods: [
          if (tieneMetaMes(t.mensual[i]))
            BarChartRodData(
              toY: t.mensual[i].meta!,
              width: 7,
              color: Colors.grey.shade400,
              borderRadius: BorderRadius.circular(2),
            ),
          BarChartRodData(
            toY: t.mensual[i].vendido,
            width: 7,
            color: i == ultimo ? colorRojoBase() : Colors.red.shade200,
            borderRadius: BorderRadius.circular(2),
          ),
        ],
      ),
  ];
}

BarTouchData _toque(String Function(int grupo, int rod, double valor) texto) {
  return BarTouchData(
    touchTooltipData: BarTouchTooltipData(
      getTooltipItem: (grupo, indice, rod, indiceRod) => BarTooltipItem(
        texto(indice, indiceRod, rod.toY),
        const TextStyle(color: Colors.white, fontSize: 12),
      ),
    ),
  );
}

FlTitlesData _titulos(Widget Function(double valor) etiqueta) {
  return FlTitlesData(
    topTitles: const AxisTitles(),
    rightTitles: const AxisTitles(),
    leftTitles: const AxisTitles(),
    bottomTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: 24,
        getTitlesWidget: (valor, meta) =>
            SideTitleWidget(meta: meta, child: etiqueta(valor)),
      ),
    ),
  );
}

/// Ventas por día del mes en curso, con la línea de meta diaria promedio.
class GraficoDiarioMeta extends StatelessWidget {
  final TableroMetaModel tablero;

  const GraficoDiarioMeta({super.key, required this.tablero});

  @override
  Widget build(BuildContext context) {
    final metaDia = metaDiariaPromedio(tablero);
    return SizedBox(
      height: 200,
      child: BarChart(BarChartData(
        barGroups: gruposDiarios(tablero),
        maxY: maxYDiario(tablero),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        alignment: BarChartAlignment.spaceAround,
        titlesData: _titulos((v) => v.toInt() % 5 == 0 || v == 1
            ? Text('${v.toInt()}', style: const TextStyle(fontSize: 10))
            : const SizedBox.shrink()),
        barTouchData: _toque((grupo, rod, valor) =>
            'Día ${tablero.diario[grupo].fecha.day}: ${formatearMonto(valor)}'),
        extraLinesData: ExtraLinesData(horizontalLines: [
          if (metaDia != null)
            HorizontalLine(
              y: metaDia,
              color: Colors.green,
              strokeWidth: 1.5,
              dashArray: [6, 4],
            ),
        ]),
      )),
    );
  }
}

/// Vendido de los últimos 12 meses, con la meta de cada mes si existe.
class GraficoMensualMeta extends StatelessWidget {
  final TableroMetaModel tablero;

  const GraficoMensualMeta({super.key, required this.tablero});

  @override
  Widget build(BuildContext context) {
    final meses = tablero.mensual;
    return SizedBox(
      height: 200,
      child: BarChart(BarChartData(
        barGroups: gruposMensuales(tablero),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        alignment: BarChartAlignment.spaceAround,
        titlesData: _titulos((v) {
          final i = v.toInt();
          if (i < 0 || i >= meses.length) return const SizedBox.shrink();
          return Text(etiquetaMes(meses[i].periodo),
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: i == meses.length - 1
                      ? FontWeight.bold
                      : FontWeight.normal));
        }),
        barTouchData: _toque((grupo, rod, valor) =>
            '${etiquetaBarraMensual(meses[grupo], rod)}: ${formatearMonto(valor)}'),
      )),
    );
  }
}
