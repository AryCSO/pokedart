class RegionListItem {
  final int id;
  final String name;

  RegionListItem({required this.id, required this.name});

  factory RegionListItem.fromJson(Map<String, dynamic> json) {
    final url = json['url'] as String;
    final segments = url.split('/');
    final idString = segments[segments.length - 2];

    return RegionListItem(
      id: int.parse(idString),
      name: json['name'] as String,
    );
  }

  String get formattedName {
    if (name.isEmpty) return '';
    return name[0].toUpperCase() + name.substring(1).toLowerCase();
  }
}

class RegionModel {
  final int id;
  final String name;
  final String mainGeneration;
  final List<String> locations; // Cidades e rotas

  RegionModel({
    required this.id,
    required this.name,
    required this.mainGeneration,
    required this.locations,
  });

  factory RegionModel.fromJson(Map<String, dynamic> json) {
    // Formatação Geração: 'generation-i' -> 'Geração 1' (Simplificado para PT por enqaunto)
    String genName = 'Geração Desconhecida';
    if (json['main_generation'] != null) {
      final String rawGen = json['main_generation']['name'] as String;
      // Trata romanos (i, ii, iii, iv, v, vi, vii, viii, ix)
      final parts = rawGen.split('-');
      if (parts.length == 2) {
        genName = 'Geração ${parts[1].toUpperCase()}';
      }
    }

    final locationsList =
        (json['locations'] as List?)
            ?.map((loc) => loc['name'].toString())
            .toList() ??
        [];

    return RegionModel(
      id: json['id'] as int,
      name: json['name'] as String,
      mainGeneration: genName,
      locations: locationsList,
    );
  }

  String get formattedName {
    if (name.isEmpty) return '';
    return name[0].toUpperCase() + name.substring(1).toLowerCase();
  }

  // Helper copyWith
  RegionModel copyWithTranslatedLocations(List<String> translatedLocations) {
    return RegionModel(
      id: id,
      name: name,
      mainGeneration: mainGeneration,
      locations: translatedLocations,
    );
  }
}
