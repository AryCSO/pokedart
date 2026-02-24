import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:translator/translator.dart';

import '../models/pokemon_model.dart';
import '../utils/format_helper.dart';

// Estados possíveis da tela para controle do novo fluxo
enum PokedexState {
  loadingList, // Carregando a super lista de 1300 nomes iniciais
  grid, // Exibindo os Cards (Search mode)
  loadingDetails, // Carregando detalhes completos de 1 Pokémon selecionado da Grid
  details, // Exibindo Modal/Tela detalhe do Pokémon
  error,
}

class PokedexViewModel extends ChangeNotifier {
  static const String _baseUrl = 'https://pokeapi.co/api/v2';

  final http.Client _client = http.Client();
  final GoogleTranslator _translator = GoogleTranslator();

  // Cache da lista leve de exibição
  List<PokemonListItem> _allPokemonList = [];
  List<PokemonListItem> _filteredList = [];

  // Caches pesados para evitar re-fetch
  final Map<int, PokemonModel> _detailsCache = {};
  final Map<int, Map<String, dynamic>> _speciesCache = {};
  final Map<String, PokemonModel> _varietiesCache = {}; // URL -> Model
  final Map<int, Map<String, List<String>>> _encountersCache = {};
  final Map<String, List<EvolutionNode>> _evolutionsCache =
      {}; // URL -> Évolutions

  PokedexState _state = PokedexState.loadingList;
  PokemonModel? _selectedPokemon;
  String? _errorMessage;
  bool _disposed = false;
  int _requestId = 0;

  // Toggle do Modo Shiny
  bool _isShiny = false;

  PokedexState get state => _state;
  PokemonModel? get selectedPokemon => _selectedPokemon;
  String? get errorMessage => _errorMessage;
  List<PokemonListItem> get filteredList => _filteredList;
  bool get isShiny => _isShiny;

  PokedexViewModel() {
    _fetchFullList();
  }

  @override
  void dispose() {
    _disposed = true;
    _client.close();
    super.dispose();
  }

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  void toggleShiny() {
    _isShiny = !_isShiny;
    _safeNotify();
  }

  void backToGrid() {
    _state = PokedexState.grid;
    _selectedPokemon = null;
    _isShiny = false; // reseta shiny ao voltar
    _safeNotify();
  }

  // 1. Baixa todos os nomes
  Future<void> _fetchFullList() async {
    try {
      final url = Uri.parse('$_baseUrl/pokemon?limit=1302');
      final response = await _client.get(url);

      if (_disposed) return;

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body) as Map<String, dynamic>;
        final results = jsonResponse['results'] as List;

        _allPokemonList = results
            .map((e) => PokemonListItem.fromJson(e as Map<String, dynamic>))
            .toList();
        _filteredList = List.from(_allPokemonList);
        _state = PokedexState.grid;
      } else {
        _errorMessage = 'Falha ao carregar Pokédex Principal.';
        _state = PokedexState.error;
      }
    } catch (e) {
      if (_disposed) return;
      _errorMessage = 'Erro de conexão inicial.';
      _state = PokedexState.error;
    }
    _safeNotify();
  }

  // 2. Filtro local
  void filterList(String query) {
    final q = query.trim().toLowerCase();

    if (_state == PokedexState.details || _state == PokedexState.error) {
      _state = PokedexState.grid;
    }

    if (q.isEmpty) {
      _filteredList = List.from(_allPokemonList);
    } else {
      _filteredList = _allPokemonList.where((p) {
        final formattedLower = p.formattedName.toLowerCase();
        final idMatch = p.id.toString() == q;
        final nameMatch = formattedLower.contains(q) || p.name.contains(q);
        return idMatch || nameMatch;
      }).toList();
    }
    _safeNotify();
  }

  // 3. Busca detalhes ricos (Base Form)
  Future<void> fetchPokemonDetails(int pokemonId) async {
    _requestId++;
    final currentRequestId = _requestId;
    _isShiny = false; // Reset form

    if (_detailsCache.containsKey(pokemonId)) {
      _selectedPokemon = _detailsCache[pokemonId];
      _state = PokedexState.details;
      _errorMessage = null;
      _safeNotify();
      return;
    }

    _state = PokedexState.loadingDetails;
    _selectedPokemon = null;
    _errorMessage = null;
    _safeNotify();

    try {
      final pokemonUrl = Uri.parse('$_baseUrl/pokemon/$pokemonId');
      final pokemonResponse = await _client.get(pokemonUrl);

      if (_disposed || currentRequestId != _requestId) return;

      if (pokemonResponse.statusCode != 200) {
        _errorMessage = 'Erro ao conectar. Tente novamente.';
        _state = PokedexState.error;
        _safeNotify();
        return;
      }

      final pokemonJson =
          json.decode(pokemonResponse.body) as Map<String, dynamic>;

      // Species Info (contém textos e as URLs de Formas)
      Map<String, dynamic> speciesJson = {};

      // Se já temos a species guardada, usamos. Senão, HTTP:
      if (_speciesCache.containsKey(pokemonId)) {
        speciesJson = _speciesCache[pokemonId]!;
      } else {
        final speciesUrl = Uri.parse('$_baseUrl/pokemon-species/$pokemonId');
        final speciesResponse = await _client.get(speciesUrl);

        if (_disposed || currentRequestId != _requestId) return;

        if (speciesResponse.statusCode == 200) {
          speciesJson =
              json.decode(speciesResponse.body) as Map<String, dynamic>;
          _speciesCache[pokemonId] = speciesJson; // Cache
        }
      }

      // Fetch Evolution Chain
      List<EvolutionNode> evolutions = [];
      if (speciesJson['evolution_chain'] != null) {
        final evoUrl = speciesJson['evolution_chain']['url'] as String;
        if (_evolutionsCache.containsKey(evoUrl)) {
          evolutions = _evolutionsCache[evoUrl]!;
        } else {
          try {
            final evoResponse = await _client.get(Uri.parse(evoUrl));
            if (!_disposed &&
                currentRequestId == _requestId &&
                evoResponse.statusCode == 200) {
              final evoJson =
                  json.decode(evoResponse.body) as Map<String, dynamic>;
              evolutions = _parseEvolutionChain(
                evoJson['chain'] as Map<String, dynamic>,
              );
              _evolutionsCache[evoUrl] = evolutions;
            }
          } catch (_) {}
        }
      }

      final basePokemon = PokemonModel.fromJson(pokemonJson, speciesJson);

      // Traduzir texto do Flavor Text
      String translatedDesc = basePokemon.description;
      if (translatedDesc.isNotEmpty && translatedDesc != 'TranslationError') {
        translatedDesc = await _translateDescription(translatedDesc);
      }

      final pokemon = basePokemon
          .copyWithEvolutions(evolutions)
          .copyWithTranslation(translatedDesc);

      // Assícrono em background de Encounters para preencher o Map
      final encounters = await _fetchEncountersAsync(pokemonId);
      final completePokemon = pokemon.copyWithEncounters(encounters);

      _detailsCache[pokemonId] = completePokemon;

      _selectedPokemon = completePokemon;
      _state = PokedexState.details;
    } catch (e) {
      if (_disposed || currentRequestId != _requestId) return;
      _errorMessage = 'Falha na conexão de detalhes.';
      _state = PokedexState.error;
    }

    _safeNotify();
  }

  // 4. Mudar Forma (Mega, Gigantamax, Regional)
  Future<void> fetchSpecificVariety(String varietyUrl, int speciesId) async {
    _requestId++;
    final currentRequestId = _requestId;

    if (_varietiesCache.containsKey(varietyUrl)) {
      _selectedPokemon = _varietiesCache[varietyUrl];
      _state = PokedexState.details;
      _safeNotify();
      return;
    }

    _state = PokedexState.loadingDetails;
    _safeNotify();

    try {
      final pokemonUrl = Uri.parse(varietyUrl);
      final pokemonResponse = await _client.get(pokemonUrl);

      if (_disposed || currentRequestId != _requestId) return;

      if (pokemonResponse.statusCode != 200) {
        _errorMessage = 'Erro ao carregar a Forma Especial.';
        _state = PokedexState.error;
        _safeNotify();
        return;
      }

      final pokemonJson =
          json.decode(pokemonResponse.body) as Map<String, dynamic>;

      // O JSON de Species foi cacheado no fetchDetails() original. Então é 100% de estar aqui.
      final speciesJson = _speciesCache[speciesId] ?? {};

      // Pega evoluções do cache se existirem (mesma espécie = mesma chain)
      List<EvolutionNode> evolutions = [];
      if (speciesJson['evolution_chain'] != null) {
        final evoUrl = speciesJson['evolution_chain']['url'] as String;
        evolutions = _evolutionsCache[evoUrl] ?? [];
      }

      final basePokemonVariety = PokemonModel.fromJson(
        pokemonJson,
        speciesJson,
      );

      // Traduzir descrição da variante
      String translatedDesc = basePokemonVariety.description;
      if (translatedDesc.isNotEmpty) {
        translatedDesc = await _translateDescription(translatedDesc);
      }

      final pokemonVariety = basePokemonVariety
          .copyWithEvolutions(evolutions)
          .copyWithTranslation(translatedDesc);

      _varietiesCache[varietyUrl] =
          pokemonVariety; // Salva o Mega Charizard pra ser rapidao depois
      _selectedPokemon = pokemonVariety;
      _state = PokedexState.details;
    } catch (e) {
      if (_disposed || currentRequestId != _requestId) return;
      _errorMessage = 'Falha de rede ao trocar de Forma.';
      _state = PokedexState.error;
    }
    _safeNotify();
  }

  // --- Helper de Tradução ---
  Future<String> _translateDescription(String text) async {
    try {
      final translation = await _translator.translate(
        text,
        from: 'en',
        to: 'pt',
      );
      return translation.text;
    } catch (e) {
      // Falha no motor do Google (Offline ou Rate Limit), mantém o fallback original em Inglês
      return text;
    }
  }

  // --- Parser Recursivo da Árvore de Evoluções ---
  List<EvolutionNode> _parseEvolutionChain(Map<String, dynamic> chain) {
    final List<EvolutionNode> nodes = [];

    void traverse(Map<String, dynamic> current) {
      final species = current['species'];
      if (species != null) {
        final url = species['url'] as String;
        final segments = url.split('/');
        final idString = segments[segments.length - 2];
        final id = int.tryParse(idString) ?? 0;

        final evolvesTo = current['evolves_to'] as List?;
        final isLeaf = evolvesTo == null || evolvesTo.isEmpty;

        nodes.add(
          EvolutionNode(
            id: id,
            name: species['name'] as String,
            isLeaf: isLeaf,
          ),
        );
      }

      final evolvesTo = current['evolves_to'] as List?;
      if (evolvesTo != null) {
        for (final next in evolvesTo) {
          traverse(next as Map<String, dynamic>);
        }
      }
    }

    traverse(chain);
    return nodes;
  }

  // --- Função Assincrona de Mapeamento de Encounters (Localizações por Jogo) ---
  Future<Map<String, List<String>>> _fetchEncountersAsync(int pokemonId) async {
    if (_encountersCache.containsKey(pokemonId)) {
      return _encountersCache[pokemonId]!;
    }

    try {
      final url = Uri.parse('$_baseUrl/pokemon/$pokemonId/encounters');
      final response = await _client.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        Map<String, List<String>> versionToLocations = {};

        for (var encounter in data) {
          final locNameRaw = encounter['location_area']['name'] as String;
          // Usa nosso motor Global Otimizado de pt-br pra Rotas
          final locNameFormatted = FormatHelper.formatLocationName(locNameRaw);
          final locTranslated = FormatHelper.batchTranslateLocations([
            locNameFormatted,
          ]).first;

          final versionDetails = encounter['version_details'] as List<dynamic>;
          for (var vd in versionDetails) {
            final versionNameRaw = vd['version']['name'] as String;
            final versionNameFormat = FormatHelper.formatLocationName(
              versionNameRaw,
            );

            if (!versionToLocations.containsKey(versionNameFormat)) {
              versionToLocations[versionNameFormat] = [];
            }
            if (!versionToLocations[versionNameFormat]!.contains(
              locTranslated,
            )) {
              versionToLocations[versionNameFormat]!.add(locTranslated);
            }
          }
        }

        _encountersCache[pokemonId] = versionToLocations;
        return versionToLocations;
      }
    } catch (_) {}

    return {};
  }
}
