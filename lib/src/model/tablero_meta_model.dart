/// Vendido de un día del mes en curso.
class VendidoDiaModel {
  final DateTime fecha;
  final double vendido;

  const VendidoDiaModel({required this.fecha, required this.vendido});

  factory VendidoDiaModel.fromJson(Map<String, dynamic> json) {
    return VendidoDiaModel(
      // Fecha local (sin zona horaria), ej. '2026-11-03'.
      fecha: DateTime.parse(json['fecha'] as String),
      vendido: (json['vendido'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// Vendido (y meta, si existe) de un mes.
class VendidoMesModel {
  final String periodo;
  final double vendido;
  final double? meta;

  const VendidoMesModel({
    required this.periodo,
    required this.vendido,
    this.meta,
  });

  factory VendidoMesModel.fromJson(Map<String, dynamic> json) {
    return VendidoMesModel(
      periodo: json['periodo'] as String,
      vendido: (json['vendido'] as num?)?.toDouble() ?? 0,
      meta: (json['meta'] as num?)?.toDouble(),
    );
  }
}

/// Tablero de meta del vendedor para el mes en curso.
class TableroMetaModel {
  final String periodo;
  final DateTime calculadoEn;
  final double? meta;
  final double vendido;
  final double? avance;
  final int cantidadVentas;
  final List<VendidoDiaModel> diario;
  final List<VendidoMesModel> mensual;

  const TableroMetaModel({
    required this.periodo,
    required this.calculadoEn,
    required this.meta,
    required this.vendido,
    required this.avance,
    required this.cantidadVentas,
    required this.diario,
    required this.mensual,
  });

  /// Hay meta utilizable: mayor que 0 y con avance calculado por el server.
  bool get tieneMeta => meta != null && meta! > 0 && avance != null;

  factory TableroMetaModel.fromJson(Map<String, dynamic> json) {
    return TableroMetaModel(
      periodo: json['periodo'] as String,
      calculadoEn: DateTime.parse(json['calculadoEn'] as String),
      meta: (json['meta'] as num?)?.toDouble(),
      vendido: (json['vendido'] as num?)?.toDouble() ?? 0,
      avance: (json['avance'] as num?)?.toDouble(),
      cantidadVentas: (json['cantidadVentas'] as num?)?.toInt() ?? 0,
      diario: ((json['diario'] as List?) ?? [])
          .map((e) => VendidoDiaModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      mensual: ((json['mensual'] as List?) ?? [])
          .map((e) => VendidoMesModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
