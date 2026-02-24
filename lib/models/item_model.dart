class ItemListItem {
  final int id;
  final String name;

  ItemListItem({required this.id, required this.name});

  factory ItemListItem.fromJson(Map<String, dynamic> json) {
    final url = json['url'] as String;
    // URL exp: https://pokeapi.co/api/v2/item/1/
    final segments = url.split('/');
    final idString = segments[segments.length - 2];

    return ItemListItem(id: int.parse(idString), name: json['name'] as String);
  }

  String get formattedName {
    if (name.isEmpty) return '';
    return name
        .split('-')
        .map(
          (s) => s.isNotEmpty
              ? s[0].toUpperCase() + s.substring(1).toLowerCase()
              : '',
        )
        .join(' ');
  }

  String get imageUrl =>
      'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/items/$name.png';
}

class ItemModel {
  final int id;
  final String name;
  final int cost;
  final String category;
  final String effect;
  final String description;

  ItemModel({
    required this.id,
    required this.name,
    required this.cost,
    required this.category,
    required this.effect,
    required this.description,
  });

  factory ItemModel.fromJson(Map<String, dynamic> json) {
    String effectText = '';
    if (json['effect_entries'] != null) {
      final entries = json['effect_entries'] as List;
      for (final entry in entries) {
        if (entry['language']['name'] == 'en') {
          effectText = entry['effect']
              .toString()
              .replaceAll('\n', ' ')
              .replaceAll('\f', ' ');
          break;
        }
      }
    }

    String flavorText = '';
    if (json['flavor_text_entries'] != null) {
      final entries = json['flavor_text_entries'] as List;
      for (final entry in entries) {
        if (entry['language']['name'] == 'en') {
          flavorText = entry['text']
              .toString()
              .replaceAll('\n', ' ')
              .replaceAll('\f', ' ');
          break;
        }
      }
    }

    final categoryName = json['category'] != null
        ? json['category']['name'] as String
        : '';

    return ItemModel(
      id: json['id'] as int,
      name: json['name'] as String,
      cost: json['cost'] as int? ?? 0,
      category: categoryName,
      effect: effectText,
      description: flavorText,
    );
  }

  String get formattedName {
    if (name.isEmpty) return '';
    return name
        .split('-')
        .map(
          (s) => s.isNotEmpty
              ? s[0].toUpperCase() + s.substring(1).toLowerCase()
              : '',
        )
        .join(' ');
  }

  String get formattedCategory {
    if (category.isEmpty) return '';
    return category
        .split('-')
        .map(
          (s) => s.isNotEmpty
              ? s[0].toUpperCase() + s.substring(1).toLowerCase()
              : '',
        )
        .join(' ');
  }

  String get imageUrl =>
      'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/items/$name.png';

  // Helper de imutabilidade para instancição de textos traduzidos
  ItemModel copyWithTranslations({String? newDescription, String? newEffect}) {
    return ItemModel(
      id: id,
      name: name,
      cost: cost,
      category: category,
      effect: newEffect ?? effect,
      description: newDescription ?? description,
    );
  }
}
