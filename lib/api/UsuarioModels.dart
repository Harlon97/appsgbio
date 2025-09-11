class UsuarioModels {
  final int? id;
  final String user;
  final String? password;
  final String? nombres;
  final String dni;
  final int? apruebaPapeleta;
  final String? correo;
  final String? codigojerarquia;
  final String? serieidcel;

  UsuarioModels({
    this.id,
    required this.user,
    this.password,
    this.nombres,
    required this.dni,
    this.apruebaPapeleta,
    this.correo,
    this.codigojerarquia,
    this.serieidcel,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': user,
      'password': password,
      'nombres': nombres,
      'dni': dni,
      'apruebaPapeleta': apruebaPapeleta,
      'correo': correo,
      'codigojerarquia': codigojerarquia,
      'serieidcel': serieidcel,
    };
  }

  factory UsuarioModels.fromJson(Map<String, dynamic> json) {
    return UsuarioModels(
      id: json['id'] as int?,
      user: json['user'] as String,
      password: json['password'] as String?,
      nombres: json['nombres'] as String?,
      dni: json['dni'] as String,
      apruebaPapeleta: json['apruebaPapeleta'] as int?,
      correo: json['correo'] as String?,
      codigojerarquia: json['codigojerarquia'] as String?,
      serieidcel: json['serieIdCel'] as String?,
    );
  }
}
