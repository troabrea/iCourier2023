// To parse this JSON data, do
//
//     final banner = bannerFromJson(jsonString);

class BannerImage {
  BannerImage({
    required this.registroId,
    required this.empresa,
    required this.imagenId,
    required this.descripcion,
    required this.url,
    required this.deleted,
  });

  String registroId;
  String empresa;
  String imagenId;
  String descripcion;
  String url;
  bool deleted;

  factory BannerImage.fromJson(Map<String, dynamic> json) => BannerImage(
        registroId: json["registroID"],
        empresa: json["empresa"],
        imagenId: json["imagenId"] ?? "",
        descripcion: json["descripcion"] ?? "",
        url: json["url"] ?? "",
        deleted: json["deleted"],
      );

  Map<String, dynamic> toJson() => {
        "registroID": registroId,
        "empresa": empresa,
        "imagenId": imagenId,
        "descripcion": descripcion,
        "url": url,
        "deleted": deleted,
      };
}
