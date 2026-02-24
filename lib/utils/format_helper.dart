class FormatHelper {
  static String formatLocationName(String location) {
    if (location.isEmpty) return '';
    return location
        .split('-')
        .map(
          (s) => s.isNotEmpty
              ? s[0].toUpperCase() + s.substring(1).toLowerCase()
              : '',
        )
        .join(' ');
  }

  // --- Helper Otimizado de Tradução Neural de Rotas ---
  static List<String> batchTranslateLocations(List<String> locations) {
    List<String> finalList = [];
    for (var original in locations) {
      String optimized = original;
      if (optimized.toLowerCase().contains('route')) {
        // Substituição Case-Insensitive segura
        optimized = optimized.replaceAll(
          RegExp(r'route', caseSensitive: false),
          'Rota',
        );
      }
      if (optimized.toLowerCase().contains('city')) {
        optimized = optimized.replaceAll(
          RegExp(r'city', caseSensitive: false),
          'Cidade',
        );
      }
      if (optimized.toLowerCase().contains('town')) {
        optimized = optimized.replaceAll(
          RegExp(r'town', caseSensitive: false),
          'Vila',
        );
      }
      if (optimized.toLowerCase().contains('cave')) {
        optimized = optimized.replaceAll(
          RegExp(r'cave', caseSensitive: false),
          'Caverna',
        );
      }
      if (optimized.toLowerCase().contains('forest')) {
        optimized = optimized.replaceAll(
          RegExp(r'forest', caseSensitive: false),
          'Floresta',
        );
      }
      if (optimized.toLowerCase().contains('island')) {
        optimized = optimized.replaceAll(
          RegExp(r'island', caseSensitive: false),
          'Ilha',
        );
      }
      if (optimized.toLowerCase().contains('sea')) {
        optimized = optimized.replaceAll(
          RegExp(r'sea', caseSensitive: false),
          'Mar',
        );
      }
      if (optimized.toLowerCase().contains('gym')) {
        optimized = optimized.replaceAll(
          RegExp(r'gym', caseSensitive: false),
          'Ginásio',
        );
      }
      if (optimized.toLowerCase().contains('building')) {
        optimized = optimized.replaceAll(
          RegExp(r'building', caseSensitive: false),
          'Prédio',
        );
      }
      if (optimized.toLowerCase().contains('tower')) {
        optimized = optimized.replaceAll(
          RegExp(r'tower', caseSensitive: false),
          'Torre',
        );
      }
      if (optimized.toLowerCase().contains('area')) {
        optimized = optimized.replaceAll(
          RegExp(r' area', caseSensitive: false),
          '',
        ); // Remove sufixos Area redundantes
      }

      finalList.add(optimized);
    }
    return finalList;
  }
}
