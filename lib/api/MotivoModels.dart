class MotivoModels {
  final int id;
  final String descripcion;

  MotivoModels({required this.id, required this.descripcion});

  Map<String, dynamic> toJson() {
    return {'id': id, 'descripcion': descripcion};
  }

  factory MotivoModels.fromJson(Map<String, dynamic> json) {
    return MotivoModels(
      id: json['id'] as int,
      descripcion: json['descripcion'] as String,
    );
  }
}
