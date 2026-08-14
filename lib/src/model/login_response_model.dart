import 'dart:convert';

// Helpers globales
LoginResponseModel loginResponseModelFromJson(String str) =>
    LoginResponseModel.fromJson(json.decode(str));

String loginResponseModelToJson(LoginResponseModel data) =>
    json.encode(data.toJson());

class LoginResponseModel {
  final String accessToken;
  final String refreshToken;
  final int expiresInSeconds;
  final String codigo;
  final String tipo;
  final String rut;
  final String nombre;
  final bool mustChangePassword;

  LoginResponseModel({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresInSeconds,
    required this.codigo,
    required this.tipo,
    required this.rut,
    required this.nombre,
    this.mustChangePassword = false,
  });

  factory LoginResponseModel.fromJson(Map<String, dynamic> json) {
    final vendedor = json["vendedor"] ?? {};
    return LoginResponseModel(
      accessToken: json["accessToken"],
      refreshToken: json["refreshToken"],
      expiresInSeconds: json["expiresInSeconds"],
      codigo: vendedor["codigo"],
      tipo: vendedor["tipo"],
      rut: vendedor["rut"],
      nombre: vendedor["nombre"],
      mustChangePassword: json["mustChangePassword"] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        "accessToken": accessToken,
        "refreshToken": refreshToken,
        "expiresInSeconds": expiresInSeconds,
        "vendedor": {
          "codigo": codigo,
          "tipo": tipo,
          "rut": rut,
          "nombre": nombre,
        },
        "mustChangePassword": mustChangePassword,
      };
}
