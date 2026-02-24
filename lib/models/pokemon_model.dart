class PokemonVariety {
  final String name;
  final String url;
  final bool isDefault;

  PokemonVariety({
    required this.name,
    required this.url,
    required this.isDefault,
  });

  int get id {
    final segments = url.split('/');
    final idString = segments[segments.length - 2];
    return int.tryParse(idString) ?? 0;
  }

  String get imageUrl =>
      'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/$id.png';

  String get formattedName {
    if (name.isEmpty) return '';
    // Ex: "charizard-mega-x" -> "Charizard Mega X"
    return name
        .split('-')
        .map((s) => s.isNotEmpty ? s[0].toUpperCase() + s.substring(1) : '')
        .join(' ');
  }
}

class EvolutionNode {
  final int id;
  final String name;
  final bool isLeaf;

  EvolutionNode({required this.id, required this.name, this.isLeaf = false});

  String get formattedName {
    if (name.isEmpty) return '';
    return name
        .split('-')
        .map((s) => s.isNotEmpty ? s[0].toUpperCase() + s.substring(1) : '')
        .join(' ');
  }

  String get imageUrl =>
      'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/$id.png';
}

class PokemonModel {
  final int id;
  final String name;
  final List<String> types;
  final String imageUrl;
  final String animatedUrl;
  final String shinyImageUrl; // NOVO: Versão Brilhante
  final String shinyAnimatedUrl; // NOVO: Versão Brilhante Animada
  final Map<String, int> stats;
  final bool isLegendary;
  final String description;
  final int
  speciesId; // NOVO: ID original (ex: 6 para todas as Charizard Megas)
  final List<PokemonVariety> varieties; // NOVO: Mega, GMAX, etc
  final List<EvolutionNode> evolutions; // NOVO: Cadeia Evolutiva
  final Map<String, List<String>>
  encounters; // NOVO: Mapeamento "Nome Da Versão do Jogo" -> ["Lista de Rotas onde aparece"]

  PokemonModel({
    required this.id,
    required this.speciesId,
    required this.name,
    required this.types,
    required this.imageUrl,
    required this.animatedUrl,
    required this.shinyImageUrl,
    required this.shinyAnimatedUrl,
    required this.stats,
    this.isLegendary = false,
    this.description = '',
    this.varieties = const [],
    this.evolutions = const [],
    this.encounters = const {},
  });

  factory PokemonModel.fromJson(
    Map<String, dynamic> json,
    Map<String, dynamic> speciesJson,
  ) {
    // Tipos
    final typesList = (json['types'] as List)
        .map((t) => t['type']['name'].toString())
        .toList();

    // Stats
    final Map<String, int> statsMap = {};
    for (final s in json['stats']) {
      statsMap[s['stat']['name']] = s['base_stat'] as int;
    }

    // Legendary
    final bool legendary = speciesJson['is_legendary'] as bool? ?? false;

    // Imagens Normal
    final sprites = json['sprites'] ?? {};
    final other = sprites['other'] ?? {};

    // Official Artwork (estático alta qualidade)
    final officialArtwork =
        other['official-artwork']?['front_default'] as String? ?? '';

    final shinyArtwork =
        other['official-artwork']?['front_shiny'] as String? ?? officialArtwork;

    // Showdown (GIF animado de batalha) Normal e Shiny
    final animated = other['showdown']?['front_default'] as String?;
    final animatedShiny = other['showdown']?['front_shiny'] as String?;

    // Descrição (Flavor Text) - Pegando o primeiro em inglês
    String flavorText = '';
    if (speciesJson['flavor_text_entries'] != null) {
      final entries = speciesJson['flavor_text_entries'] as List;
      for (final entry in entries) {
        if (entry['language']['name'] == 'en') {
          flavorText = entry['flavor_text']
              .toString()
              .replaceAll('\n', ' ')
              .replaceAll('\f', ' ');
          break;
        }
      }
    }

    // Parse de Varieties (Formas Base, Mega, GMAX, Alola, Galar, etc)
    List<PokemonVariety> varietiesList = [];
    if (speciesJson['varieties'] != null) {
      final varietiesArr = speciesJson['varieties'] as List;
      for (var v in varietiesArr) {
        final isDefault = v['is_default'] as bool? ?? false;
        final vName = v['pokemon']['name'] as String;
        final vUrl = v['pokemon']['url'] as String;

        // Remove Totem forms pois são muito situacionais e poluem a UI
        if (!vName.contains('-totem')) {
          varietiesList.add(
            PokemonVariety(name: vName, url: vUrl, isDefault: isDefault),
          );
        }
      }
    }

    // ID Base da Espécie
    final int baseSpeciesId = speciesJson['id'] as int? ?? json['id'] as int;

    return PokemonModel(
      id: json['id'] as int,
      speciesId: baseSpeciesId,
      name: json['name'] as String,
      types: typesList,
      imageUrl: officialArtwork,
      animatedUrl: animated ?? officialArtwork,
      shinyImageUrl: shinyArtwork,
      shinyAnimatedUrl: animatedShiny ?? shinyArtwork,
      stats: statsMap,
      isLegendary: legendary,
      description: flavorText,
      varieties: varietiesList,
      evolutions: [],
      encounters: const {},
    );
  }

  // Permite injetar as evoluções depois de baixadas
  PokemonModel copyWithEvolutions(List<EvolutionNode> newEvolutions) {
    return PokemonModel(
      id: id,
      speciesId: speciesId,
      name: name,
      types: types,
      imageUrl: imageUrl,
      animatedUrl: animatedUrl,
      shinyImageUrl: shinyImageUrl,
      shinyAnimatedUrl: shinyAnimatedUrl,
      stats: stats,
      isLegendary: isLegendary,
      description: description,
      varieties: varieties,
      evolutions: newEvolutions,
      encounters: encounters,
    );
  }

  // Permite injetar os mapas de encontro por jogo depois de baixados
  PokemonModel copyWithEncounters(Map<String, List<String>> newEncounters) {
    return PokemonModel(
      id: id,
      speciesId: speciesId,
      name: name,
      types: types,
      imageUrl: imageUrl,
      animatedUrl: animatedUrl,
      shinyImageUrl: shinyImageUrl,
      shinyAnimatedUrl: shinyAnimatedUrl,
      stats: stats,
      isLegendary: isLegendary,
      description: description,
      varieties: varieties,
      evolutions: evolutions,
      encounters: newEncounters,
    );
  }

  // Permite injetar as traduções depois
  PokemonModel copyWithTranslation(String newDescription) {
    return PokemonModel(
      id: id,
      speciesId: speciesId,
      name: name,
      types: types,
      imageUrl: imageUrl,
      animatedUrl: animatedUrl,
      shinyImageUrl: shinyImageUrl,
      shinyAnimatedUrl: shinyAnimatedUrl,
      stats: stats,
      isLegendary: isLegendary,
      description: newDescription,
      varieties: varieties,
      evolutions: evolutions,
      encounters: encounters,
    );
  }

  // Helpers para formatar ID e nome
  String get formattedId => '#${id.toString().padLeft(3, '0')}';

  String get formattedName {
    if (name.isEmpty) return '';
    String cleanName = name
        .replaceAll('-mega-y', ' Mega Y')
        .replaceAll('-mega-x', ' Mega X')
        .replaceAll('-mega', ' Mega')
        .replaceAll('-gmax', ' Gigamax')
        .replaceAll('-alola', ' Alola Form')
        .replaceAll('-galar', ' Galar Form')
        .replaceAll('-hisui', ' Hisui Form')
        .replaceAll('-paldea', ' Paldea Form');

    return cleanName
        .split('-')
        .map(
          (s) => s.isNotEmpty
              ? s[0].toUpperCase() + s.substring(1).toLowerCase()
              : '',
        )
        .join(' ');
  }

  // Helpers para stats
  int get hp => stats['hp'] ?? 0;
  int get attack => stats['attack'] ?? 0;
  int get defense => stats['defense'] ?? 0;
  int get specialAttack => stats['special-attack'] ?? 0;
  int get specialDefense => stats['special-defense'] ?? 0;
  int get speed => stats['speed'] ?? 0;
}

// Representação super rápida para a Grid com Lazy Loading da Imagem
class PokemonListItem {
  final int id;
  final String name;

  PokemonListItem({required this.id, required this.name});

  factory PokemonListItem.fromJson(Map<String, dynamic> json) {
    final url = json['url'] as String;
    // URL exp: https://pokeapi.co/api/v2/pokemon/1/
    final segments = url.split('/');
    final idString = segments[segments.length - 2];

    return PokemonListItem(
      id: int.parse(idString),
      name: json['name'] as String,
    );
  }

  String get formattedId => '#${id.toString().padLeft(3, '0')}';

  String get formattedName {
    if (name.isEmpty) return '';
    String cleanName = name
        .replaceAll('-mega-y', ' Mega Y')
        .replaceAll('-mega-x', ' Mega X')
        .replaceAll('-mega', ' Mega')
        .replaceAll('-gmax', ' Gigamax')
        .replaceAll('-alola', ' Alola Form')
        .replaceAll('-galar', ' Galar Form')
        .replaceAll('-hisui', ' Hisui Form')
        .replaceAll('-paldea', ' Paldea Form');

    return cleanName
        .split('-')
        .map(
          (s) => s.isNotEmpty
              ? s[0].toUpperCase() + s.substring(1).toLowerCase()
              : '',
        )
        .join(' ');
  }

  // Puxa a imagem da fonte direta do PokeAPI master sem fazer proxy de JSON!
  String get imageUrl =>
      'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/$id.png';
}
