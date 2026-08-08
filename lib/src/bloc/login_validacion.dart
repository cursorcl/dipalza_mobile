import 'dart:async';

class Validators {
  final validarUsuario = StreamTransformer<String, String>.fromHandlers(handleData: (usuario, sink) {
    if (usuario.length >= 3) {
      sink.add(usuario);
    } else {
      sink.addError('El usuario minimo 3 caracteres.');
    }
  });

  final validarPassword = StreamTransformer<String, String>.fromHandlers(handleData: (password, sink) {
    if (password.length >= 6) {
      sink.add(password);
    } else {
      sink.addError('La contraseña debe mayor a 6 caracteres.');
    }
  });

  final validarClaveActual = StreamTransformer<String, String>.fromHandlers(handleData: (clave, sink) {
    if (clave.isNotEmpty) {
      sink.add(clave);
    } else {
      sink.addError('Ingrese su clave actual.');
    }
  });

  final validarClaveNueva = StreamTransformer<String, String>.fromHandlers(handleData: (clave, sink) {
    if (clave.length >= 8) {
      sink.add(clave);
    } else {
      sink.addError('La clave nueva debe tener al menos 8 caracteres.');
    }
  });

  final validarCodigoRecuperacion = StreamTransformer<String, String>.fromHandlers(handleData: (codigo, sink) {
    if (RegExp(r'^\d{6}$').hasMatch(codigo)) {
      sink.add(codigo);
    } else {
      sink.addError('Ingrese el código de 6 dígitos recibido por correo.');
    }
  });
}
