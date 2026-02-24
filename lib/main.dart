import 'package:flutter/material.dart';

// --- MODEL ---

class PokemonModel {
  final int id;
  final String name;
  final List<String> types;
  final String imageUrl;
  final Map<String, int> stats;
  final bool isLegendary; // Nota: Requer busca adicional na PokeAPI (species)

  PokemonModel({
    required this.id,
    required this.name,
    required this.types,
    required this.imageUrl,
    required this.stats,
    this.isLegendary = false,
  });

  factory PokemonModel.fromJson(Map<String, dynamic> json, Map<String, dynamic> speciesJson) {
    // Extraindo tipos
    var typesList = (json['types'] as List)
        .map((t) => t['type']['name'].toString())
        .toList();

    // Extraindo stats
    Map<String, int> statsMap = {};
    for (var s in json['stats']) {
      statsMap[s['stat']['name']] = s['base_stat'];
    }

    // Verificando se é lendário no endpoint de species
    bool legendary = speciesJson['is_legendary'] ?? false;

    return PokemonModel(
      id: json['id'],
      name: json['name'],
      types: typesList,
      imageUrl: json['sprites']['other']['official-artwork']['front_default'] ?? '',
      stats: statsMap,
      isLegendary: legendary,
    );
  }
}

// --- VIEW MODEL ---
class PokedexViewModel extends ChangeNotifier {
  List<Pokemon> _allPokemon = [];
  Pokemon? _selectedPokemon;
  bool _isLoading = false;

  Pokemon? get selectedPokemon => _selectedPokemon;
  bool get isLoading => _isLoading;

  // Simulação de carregamento do arquivo .txt
  void loadData(String rawTxt) {
    final lines = rawTxt.split('\n').skip(1); // Pula o cabeçalho
    _allPokemon = lines
        .where((line) => line.isNotEmpty)
        .map((line) => Pokemon.fromCsvLine(line))
        .toList();
  }

  void searchPokemon(String name) async {
    _isLoading = true;
    _selectedPokemon = null;
    notifyListeners();

    // Pequeno delay para efeito visual de busca premium
    await Future.delayed(const Duration(milliseconds: 600));

    try {
      _selectedPokemon = _allPokemon.firstWhere(
        (p) => p.name.toLowerCase() == name.toLowerCase(),
      );
    } catch (e) {
      _selectedPokemon = null;
    }

    _isLoading = false;
    notifyListeners();
  }
}
// --- VIEW (Main Application) ---
void main() {
  runApp(const PokedexLuxoApp());
}

class PokedexLuxoApp extends StatelessWidget {
  const PokedexLuxoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pokedex Luxo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF1DA1F2),
        scaffoldBackgroundColor: Colors.black,
      ),
      home: const PokedexPage(),
    );
  }
}

class PokedexPage extends StatefulWidget {
  const PokedexPage({super.key});

  @override
  State<PokedexPage> createState() => _PokedexPageState();
}

class _PokedexPageState extends State<PokedexPage> {
  final PokedexViewModel _viewModel = PokedexViewModel();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Dados de exemplo baseados no seu .txt
    const String data = """#,Nome,Tipo 1,Tipo 2,Total,HP,Ataque,Defesa,Sp. Ataque Especial,Sp. Defesa Especial,Velocidade,Geração,Lendário
1,Bulbasaur,Grass,Poison,318,45,49,49,65,65,45,1,False
4,Charmander,Fire,,309,39,52,43,60,50,65,1,False
25,Pikachu,Electric,,320,35,55,40,50,50,90,1,False
150,Mewtwo,Psychic,,680,106,110,90,154,90,130,1,True""";
    
    _viewModel.loadData(data);
    _viewModel.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          children: [
            const SizedBox(height: 80),
            const Text(
              'POKÉDEX LUXO',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                letterSpacing: -1,
                fontStyle: FontStyle.italic,
                color: Color(0xFF1DA1F2),
              ),
            ),
            const SizedBox(height: 40),
            
            // Barra de Pesquisa Estilizada
            TextField(
              controller: _searchController,
              onSubmitted: (value) => _viewModel.searchPokemon(value),
              decoration: InputDecoration(
                hintText: 'Digite o nome do Pokémon...',
                filled: true,
                fillColor: const Color(0xFF0A0A0A),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search, color: Color(0xFF1DA1F2)),
                  onPressed: () => _viewModel.searchPokemon(_searchController.text),
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey.shade900),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF1DA1F2)),
                ),
              ),
            ),

            const SizedBox(height: 40),

            if (_viewModel.isLoading)
              const CircularProgressIndicator(color: Color(0xFF1DA1F2))
            else if (_viewModel.selectedPokemon != null)
              _buildPokemonCard(_viewModel.selectedPokemon!)
          ],
        ),
      ),
    );
  }

  Widget _buildPokemonCard(Pokemon p) {
    return Expanded(
      child: SingleChildScrollView(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF050505),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.grey.shade900),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('#${p.id}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.grey)),
                  if (p.isLegendary)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.blue.withOpacity(0.3)),
                      ),
                      child: const Text('✨ LENDÁRIO', style: TextStyle(color: Colors.blue, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
              Image.network(
                'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/${p.id}.png',
                height: 200,
                errorBuilder: (_, __, ___) => const Icon(Icons.catching_pokemon, size: 100),
              ),
              const SizedBox(height: 20),
              Text(p.name.toUpperCase(), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              _buildTypeBadge(p.type1),
              const SizedBox(height: 30),
              _buildStatRow('HP', p.hp),
              _buildStatRow('ATAQUE', p.attack),
              _buildStatRow('DEFESA', p.defense),
              _buildStatRow('VELOCIDADE', p.speed),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeBadge(String type) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1DA1F2).withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(type.toUpperCase(), style: const TextStyle(color: Color(0xFF1DA1F2), fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }

  Widget _buildStatRow(String label, int value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10)),
              Text(value.toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: value / 200,
            backgroundColor: Colors.grey.shade900,
            color: const Color(0xFF1DA1F2),
            minHeight: 3,
          ),
        ],
      ),
    );
  }
}