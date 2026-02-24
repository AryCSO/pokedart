import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:translator/translator.dart';
import '../models/item_model.dart';

enum ItemsState { idle, loading, loadingMore, loaded, error, details }

class ItemViewModel extends ChangeNotifier {
  static const String _baseUrl = 'https://pokeapi.co/api/v2';
  final http.Client _client = http.Client();
  final GoogleTranslator _translator = GoogleTranslator();

  // --- Estado da Lista ---
  List<ItemListItem> _itemsList = [];
  List<ItemListItem> get itemsList =>
      _searchQuery.isEmpty ? _itemsList : _filteredList;

  List<ItemListItem> _filteredList = [];
  String _searchQuery = '';
  ItemsState _state = ItemsState.idle;
  ItemsState get state => _state;
  String _errorMessage = '';
  String get errorMessage => _errorMessage;

  // --- Paginação ---
  int _offset = 0;
  final int _limit = 50;
  bool _hasReachedMax = false;
  bool get hasReachedMax => _hasReachedMax;

  // --- Cache e Detalhes ---
  final Map<int, ItemModel> _detailsCache = {};
  ItemModel? _selectedItem;
  ItemModel? get selectedItem => _selectedItem;

  bool _disposed = false;
  int _requestId = 0; // Controle de concorrência

  @override
  void dispose() {
    _disposed = true;
    _client.close();
    super.dispose();
  }

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  // --- Boot e Paginação (Infinite Scroll) ---
  Future<void> fetchItems({bool isRefresh = false}) async {
    if (isRefresh) {
      _offset = 0;
      _hasReachedMax = false;
      _itemsList.clear();
      _filteredList.clear();
      _state = ItemsState.loading;
      _safeNotify();
    } else {
      if (_hasReachedMax ||
          _state == ItemsState.loading ||
          _state == ItemsState.loadingMore) {
        return;
      }
      _state = ItemsState.loadingMore;
      _safeNotify();
    }

    try {
      final url = Uri.parse('$_baseUrl/item?offset=$_offset&limit=$_limit');
      final response = await _client.get(url);

      if (_disposed) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final results = data['results'] as List;

        final newItems = results
            .map((json) => ItemListItem.fromJson(json as Map<String, dynamic>))
            .toList();

        if (newItems.isEmpty || results.length < _limit) {
          _hasReachedMax = true;
        }

        _itemsList.addAll(newItems);
        _offset += _limit;

        if (_searchQuery.isNotEmpty) {
          _filterList(_searchQuery);
        }

        _state = ItemsState.loaded;
      } else {
        _errorMessage = 'Falha ao carregar itens';
        _state = ItemsState.error;
      }
    } catch (e) {
      if (!_disposed) {
        _errorMessage = 'Erro de conexão: $e';
        _state = ItemsState.error;
      }
    }
    _safeNotify();
  }

  // --- Busca de Detalhes com Tradução ---
  Future<void> fetchItemDetails(int itemId) async {
    _requestId++;
    final currentRequestId = _requestId;

    if (_detailsCache.containsKey(itemId)) {
      _selectedItem = _detailsCache[itemId];
      _state = ItemsState.details;
      _safeNotify();
      return;
    }

    _state = ItemsState
        .loading; // Usamos loading pra congelar UI se preferir (ou showDialog trata isso)
    _safeNotify();

    try {
      final url = Uri.parse('$_baseUrl/item/$itemId');
      final response = await _client.get(url);

      if (_disposed || currentRequestId != _requestId) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final baseItem = ItemModel.fromJson(data);

        // Tradução em Tempo Real
        String translatedDesc = baseItem.description;
        String translatedEffect = baseItem.effect;

        if (translatedDesc.isNotEmpty) {
          translatedDesc = await _translateText(translatedDesc);
        }
        if (translatedEffect.isNotEmpty) {
          translatedEffect = await _translateText(translatedEffect);
        }

        final item = baseItem.copyWithTranslations(
          newDescription: translatedDesc,
          newEffect: translatedEffect,
        );

        _detailsCache[itemId] = item;
        _selectedItem = item;
        _state = ItemsState.details;
      } else {
        _errorMessage = 'Erro ao carregar detalhes do item.';
        _state = ItemsState.error;
      }
    } catch (e) {
      if (_disposed || currentRequestId != _requestId) return;
      _errorMessage = 'Falha de conexão nos detalhes do item.';
      _state = ItemsState.error;
    }
    _safeNotify();
  }

  // --- Helper de Tradução ---
  Future<String> _translateText(String text) async {
    try {
      final translation = await _translator.translate(
        text,
        from: 'en',
        to: 'pt',
      );
      return translation.text;
    } catch (e) {
      return text; // Fallback para Inglês
    }
  }

  // --- Pesquisa Local ---
  void search(String query) {
    _searchQuery = query.trim().toLowerCase();
    _filterList(_searchQuery);
    // Mesmo em busca vazia, avisamos os listeners para restaurar a original
    _safeNotify();
  }

  void _filterList(String query) {
    if (query.isEmpty) {
      _filteredList = [];
    } else {
      _filteredList = _itemsList.where((item) {
        final lowerName = item.name.toLowerCase();
        final lowerId = item.id.toString();
        return lowerName.contains(query) || lowerId.contains(query);
      }).toList();
    }
  }

  void resetToLoadedState() {
    if (_state == ItemsState.details) {
      _state = ItemsState.loaded;
      _safeNotify();
    }
  }
}
