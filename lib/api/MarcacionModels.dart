class MarcacionModels {
  final int? id;
  final String? id_personal;
  final DateTime fecha_hora;
  final String? fecha;
  final String? hora;
  final int? activo;
  final int? idpersonbio;
  final String dni;
  final int idbio;
  final String? idcencos;
  final String? idempresa;
  final String? tipo;
  final String? id_planilla;
  final String? depurado;
  final String? id_planta;
  final DateTime fecha_hora_real;
  final int tipo_marcado;
  final double latitud;
  final double longitud;

  final String? nombre;
  final String? departamento;
  final int? id_turno;
  final int? id_accion;
  final String? swt_estado;
  final int? count_hor;
  final String? fechainicio;
  final String? fechafin;

  final int? idmotivo;
  final String? dispositivoId;
  final String? dispositivoMarca;
  final String? dispositivoModelo;
  final String? dispositivoSerie;
  final String? dispositivoNombre;

  MarcacionModels({
    this.id,
    this.id_personal,
    required this.fecha_hora,
    this.fecha,
    this.hora,
    this.activo,
    this.idpersonbio,
    required this.dni,
    required this.idbio,
    this.idcencos,
    this.idempresa,
    this.tipo,
    this.id_planilla,
    this.depurado,
    this.id_planta,
    required this.fecha_hora_real,
    required this.tipo_marcado,
    required this.latitud,
    required this.longitud,
    this.nombre,
    this.departamento,
    this.id_turno,
    this.id_accion,
    this.swt_estado,
    this.count_hor,
    this.fechainicio,
    this.fechafin,
    this.idmotivo,
    this.dispositivoId,
    this.dispositivoMarca,
    this.dispositivoModelo,
    this.dispositivoSerie,
    this.dispositivoNombre,
  });

  Map<String, dynamic> toJsonPost() {
    return {
      'Dni': dni,
      'Fecha_hora': fecha_hora.toIso8601String(),
      'Idbio': idbio,
      'Fecha_hora_real': fecha_hora_real.toIso8601String(),
      'Tipo_marcado': tipo_marcado,
      'Latitud': latitud,
      'Longitud': longitud,
      'IdMotivo': idmotivo,
      'DispositivoId': dispositivoId,
      'DispositivoMarca': dispositivoMarca,
      'DispositivoModelo': dispositivoModelo,
      'DispositivoSerie': dispositivoSerie,
      'DispositivoNombre': dispositivoNombre,
      'Tipo': tipo,
    };
  }

  // factory MarcacionModels.fromJson(Map<String, dynamic> json) {

  //   return MarcacionModels(
  //     id: json['id'] as int?,
  //     id_personal: json['id_personal'] as String?,
  //     fecha_hora: DateTime.tryParse(json['fecha_hora'])!,
  //     fecha: json['fecha'] as String?,
  //     hora: json['hora'] as String?,
  //     activo: json['activo'] as int?,
  //     idpersonbio: json['idpersonbio'] as int?,
  //     dni: json['dni'] as String,
  //     idbio: json['idbio'] as int,
  //     idcencos: json['idcencos'] as String?,
  //     idempresa: json['idempresa'] as String?,
  //     tipo: json['tipo'] as String?,
  //     id_planilla: json['id_planilla'] as String?,
  //     depurado: json['depurado'] as String?,
  //     id_planta: json['id_planta'] as String?,
  //     fecha_hora_real: DateTime.tryParse(json['fecha_hora_real'])!,
  //     tipo_marcado: json['tipo_marcado'] as int,
  //     latitud: json['latitud'] as double,
  //     longitud: json['longitud'] as double,
  //     nombre: json['nombre'] as String?,
  //     departamento: json['departamento'] as String?,
  //     id_turno: json['id_turno'] as int?,
  //     id_accion: json['id_accion'] as int?,
  //     swt_estado: json['swt_estado'] as String?,
  //     count_hor: json['count_hor'] as int?,
  //     fechainicio: json['fechainicio'] as String?,
  //     fechafin: json['fechafin'] as String?,
  //   );
  // }
  factory MarcacionModels.fromJson(Map<String, dynamic> json) {
    // Funciones de ayuda para obtener valores de forma segura y convertirlos.
    // Esto es muy útil para evitar repetición de código y manejar los posibles nulls.
    T? _safeGet<T>(String key) {
      if (!json.containsKey(key) || json[key] == null) {
        return null;
      }
      return json[key] as T;
    }

    // El operador 'as' puede fallar si el tipo no coincide.
    // Es más seguro usar una lógica condicional o métodos de conversión.
    // Usamos '??' para proporcionar un valor predeterminado en caso de que la conversión falle.

    // Obtener valores que son obligatorios (required)
    final dni = _safeGet<String>('dni') ?? '';
    final idbio = _safeGet<int>('idbio') ?? 0;
    final tipoMarcado = _safeGet<int>('tipo_marcado') ?? 0;
    final latitud = _safeGet<double>('latitud') ?? 0.0;
    final longitud = _safeGet<double>('longitud') ?? 0.0;
    final idmotivo = _safeGet<int>('idmotivo') ?? 0;
    final tipo = _safeGet<String>('tipo') ?? '';
    final dispositivoId = _safeGet<String>('dispositivoId') ?? '';
    final dispositivoMarca = _safeGet<String>('dispositivoMarca') ?? '';
    final dispositivoModelo = _safeGet<String>('dispositivoModelo') ?? '';
    final dispositivoSerie = _safeGet<String>('dispositivoSerie') ?? '';
    final dispositivoNombre = _safeGet<String>('dispositivoNombre') ?? '';

    // El manejo de DateTime es crucial. Usamos tryParse y proporcionamos una fecha por defecto.
    final fechaHora =
        DateTime.tryParse(_safeGet<String>('fecha_hora') ?? '') ??
        DateTime.now();
    final fechaHoraReal =
        DateTime.tryParse(_safeGet<String>('fecha_hora_real') ?? '') ??
        DateTime.now();

    return MarcacionModels(
      id: _safeGet<int>('id'),
      id_personal: _safeGet<String>('id_personal'),
      fecha_hora: fechaHora,
      fecha: _safeGet<String>('fecha'),
      hora: _safeGet<String>('hora'),
      activo: _safeGet<int>('activo'),
      idpersonbio: _safeGet<int>('idpersonbio'),
      dni: dni,
      idbio: idbio,
      idcencos: _safeGet<String>('idcencos'),
      idempresa: _safeGet<String>('idempresa'),
      tipo: tipo,
      id_planilla: _safeGet<String>('id_planilla'),
      depurado: _safeGet<String>('depurado'),
      id_planta: _safeGet<String>('id_planta'),
      fecha_hora_real: fechaHoraReal,
      tipo_marcado: tipoMarcado,
      latitud: latitud,
      longitud: longitud,
      nombre: _safeGet<String>('nombre'),
      departamento: _safeGet<String>('departamento'),
      id_turno: _safeGet<int>('id_turno'),
      id_accion: _safeGet<int>('id_accion'),
      swt_estado: _safeGet<String>('swt_estado'),
      count_hor: _safeGet<int>('count_hor'),
      fechainicio: _safeGet<String>('fechainicio'),
      fechafin: _safeGet<String>('fechafin'),
      idmotivo: idmotivo,
      dispositivoId: dispositivoId,
      dispositivoMarca: dispositivoMarca,
      dispositivoModelo: dispositivoModelo,
      dispositivoSerie: dispositivoSerie,
      dispositivoNombre: dispositivoNombre,
    );
  }
}
