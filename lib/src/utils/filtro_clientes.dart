import '../model/clientes_model.dart';

/// Texto que parece un RUT (o parte de uno): dígitos y, opcionalmente, el
/// dígito verificador K al final, una vez quitados puntos, guion y espacios.
final _patronRut = RegExp(r'^[0-9]+K?$');

/// `true` si el cliente calza con lo que escribió el vendedor: nombre (razón
/// social), código o RUT. El RUT se acepta con o sin puntos y guion, con la K
/// en mayúscula o minúscula y sin los ceros a la izquierda con que se guarda
/// (`010951201K` calza con `10.951.201-k`, `10951201K` o `1095120`).
bool coincideCliente(ClientesModel cliente, String termino) {
  final texto = termino.trim().toUpperCase();
  if (texto.isEmpty) return false;

  if (cliente.razon.toUpperCase().contains(texto) ||
      cliente.codigo.toUpperCase().contains(texto)) {
    return true;
  }

  final rutBuscado = _sinCeros(texto.replaceAll(RegExp(r'[.\-\s]'), ''));
  if (!_patronRut.hasMatch(rutBuscado)) return false;
  return _sinCeros(cliente.rut.toUpperCase().replaceAll(RegExp(r'[.\-\s]'), ''))
      .contains(rutBuscado);
}

String _sinCeros(String rut) => rut.replaceFirst(RegExp(r'^0+'), '');
