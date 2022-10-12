
import 'package:meta/meta.dart';
import 'dart:convert';

class Producto {
  Producto({
    required this.registroId,
    required this.empresa,
    required this.titulo,
    required this.codigo,
    required this.orden,
    required this.deleted,
  });

  String registroId;
  String empresa;
  String titulo;
  String codigo;
  double orden;
  bool deleted;

  factory Producto.fromJson(Map<String, dynamic> json) => Producto(
    registroId: json["registroID"],
    empresa: json["empresa"],
    titulo: json["titulo"],
    codigo: json["codigo"],
    orden: json["orden"],
    deleted: json["deleted"],
  );

  Map<String, dynamic> toJson() => {
    "registroID": registroId,
    "empresa": empresa,
    "titulo": titulo,
    "codigo": codigo,
    "orden": orden,
    "deleted": deleted,
  };
}