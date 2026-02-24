import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/region_model.dart';

enum RegionsState { idle, loading, loaded, details, error }

class RegionViewModel extends ChangeNotifier {
  static const String _baseUrl = 'https://pokeapi.co/api/v2';
  final http.Client _client = http.Client();

  // --- Estado da Lista ---
  List<RegionListItem> _regionsList = [];
  List<RegionListItem> get regionsList => _regionsList;

  RegionsState _state = RegionsState.idle;
  RegionsState get state => _state;
  String _errorMessage = '';
  String get errorMessage => _errorMessage;

  // --- Cache e Detalhes ---
  final Map<int, RegionModel> _detailsCache = {};
  RegionModel? _selectedRegion;
  RegionModel? get selectedRegion => _selectedRegion;

  bool _disposed = false;
  int _requestId = 0;

  @override
  void dispose() {
    _disposed = true;
    _client.close();
    super.dispose();
  }

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  // --- Boot (Busca as 10 regiões únicas da API) ---
  Future<void> fetchRegions({bool isRefresh = false}) async {
    if (isRefresh) {
      _regionsList.clear();
      _state = RegionsState.loading;
      _safeNotify();
    } else if (_regionsList.isNotEmpty && _state == RegionsState.loaded) {
      return;
    }

    _state = RegionsState.loading;
    _safeNotify();

    try {
      // Diferente de itens, há apenas 10 regiões, puxar 20 garante carregar todas.
      final url = Uri.parse('$_baseUrl/region?limit=20');
      final response = await _client.get(url);

      if (_disposed) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final results = data['results'] as List;

        _regionsList = results
            .map(
              (json) => RegionListItem.fromJson(json as Map<String, dynamic>),
            )
            .toList();

        _state = RegionsState.loaded;
      } else {
        _errorMessage = 'Falha ao carregar regiões';
        _state = RegionsState.error;
      }
    } catch (e) {
      if (!_disposed) {
        _errorMessage = 'Erro de conexão: $e';
        _state = RegionsState.error;
      }
    }
    _safeNotify();
  }

  // --- Busca de Detalhes da Região Selecionada ---
  Future<void> fetchRegionDetails(int regionId) async {
    _requestId++;
    final currentRequestId = _requestId;

    if (_detailsCache.containsKey(regionId)) {
      _selectedRegion = _detailsCache[regionId];
      _state = RegionsState.details;
      _safeNotify();
      return;
    }

    _state = RegionsState.loading;
    _safeNotify();

    try {
      final url = Uri.parse('$_baseUrl/region/$regionId');
      final response = await _client.get(url);

      if (_disposed || currentRequestId != _requestId) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final baseRegion = RegionModel.fromJson(data);

        // Processo Custoso (Regex e Tradução) para as centenas de locações
        List<String> formattedLocations = [];
        for (var loc in baseRegion.locations) {
          final readableName = _formatLocationName(loc);
          formattedLocations.add(readableName);
        }

        final translatedLocations = await _batchTranslateLocations(
          formattedLocations,
        );

        final region = baseRegion.copyWithTranslatedLocations(
          translatedLocations,
        );

        _detailsCache[regionId] = region;
        _selectedRegion = region;
        _state = RegionsState.details;
      } else {
        _errorMessage = 'Erro ao carregar detalhes da região.';
        _state = RegionsState.error;
      }
    } catch (e) {
      if (_disposed || currentRequestId != _requestId) return;
      _errorMessage = 'Falha de conexão nas configurações da Região.';
      _state = RegionsState.error;
    }
    _safeNotify();
  }

  // --- Função RegEx de Formatação (pallet-town -> Pallet Town) ---
  String _formatLocationName(String location) {
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
  Future<List<String>> _batchTranslateLocations(List<String> locations) async {
    // Como o GoogleTranslator da Lib limita requests brutas, vamos otimizar:
    // Se a string tiver "Route", trocamos manualmente primeiro. Poupando a API
    List<String> finalList = [];
    for (var original in locations) {
      String optimized = original;
      if (optimized.contains('Route')) {
        optimized = optimized.replaceAll('Route', 'Rota');
      }
      if (optimized.contains('City')) {
        optimized = optimized.replaceAll('City', 'Cidade');
      }
      if (optimized.contains('Town')) {
        optimized = optimized.replaceAll('Town', 'Vila');
      }
      if (optimized.contains('Cave')) {
        optimized = optimized.replaceAll('Cave', 'Caverna');
      }
      if (optimized.contains('Forest')) {
        optimized = optimized.replaceAll('Forest', 'Floresta');
      }
      if (optimized.contains('Island')) {
        optimized = optimized.replaceAll('Island', 'Ilha');
      }
      if (optimized.contains('Sea')) {
        optimized = optimized.replaceAll('Sea', 'Mar');
      }
      if (optimized.contains('Gym')) {
        optimized = optimized.replaceAll('Gym', 'Ginásio');
      }

      finalList.add(optimized);
    }
    return finalList;
  }

  void resetToLoadedState() {
    if (_state == RegionsState.details) {
      _state = RegionsState.loaded;
      _safeNotify();
    }
  }
}
