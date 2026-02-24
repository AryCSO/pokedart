import 'package:flutter/material.dart';
import '../models/pokemon_model.dart';
import '../viewmodels/pokedex_viewmodel.dart';

class PokedexPage extends StatefulWidget {
  const PokedexPage({super.key});

  @override
  State<PokedexPage> createState() => _PokedexPageState();
}

class _PokedexPageState extends State<PokedexPage>
    with SingleTickerProviderStateMixin {
  final PokedexViewModel _viewModel = PokedexViewModel();
  final TextEditingController _searchController = TextEditingController();

  late AnimationController _bgAnimationController;

  @override
  void initState() {
    super.initState();
    _viewModel.addListener(_onViewModelChanged);
    _bgAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  void _onViewModelChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _bgAnimationController.dispose();
    _viewModel.removeListener(_onViewModelChanged);
    _searchController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  // Cor principal baseada no tipo do Pokémon em detalhe (ou Padrão Vermelho Pokédex)
  Color get _primaryColor {
    if (_viewModel.state == PokedexState.details &&
        _viewModel.selectedPokemon != null) {
      if (_viewModel.selectedPokemon!.types.isNotEmpty) {
        return _getTypeColor(_viewModel.selectedPokemon!.types.first);
      }
    }
    return const Color(0xFFE3350D); // Vermelho Pokédex Padrão
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Fundo animado com gradiente suave
          _buildAnimatedBackground(),

          // Conteúdo principal
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _buildBodyContent(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _bgAnimationController,
      builder: (context, child) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0, -0.4),
              radius: 1.2,
              colors: [_primaryColor.withValues(alpha: 0.15), Colors.black],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    // Esconder o Header na tela de detalhes? Não, vamos colocar botão de voltar nela.
    final bool isDetails =
        _viewModel.state == PokedexState.details ||
        _viewModel.state == PokedexState.loadingDetails;

    if (isDetails) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: () => _viewModel.backToGrid(),
            ),
            const Expanded(
              child: Text(
                'Detalhes',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ),
            const SizedBox(width: 48), // Balanceia o Row
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.catching_pokemon, color: _primaryColor, size: 28),
              const SizedBox(width: 10),
              const Text(
                'Pokédex',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Search Bar com Filtro em tempo real
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    // Filtro em real time sem apagar o layout
                    _viewModel.filterList(value);
                  },
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Buscar Pokémon...',
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.search, color: _primaryColor),
                      onPressed: () => FocusScope.of(context).unfocus(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBodyContent() {
    switch (_viewModel.state) {
      case PokedexState.loadingList:
        return Column(
          key: const ValueKey('loadingList'),
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: _primaryColor),
            const SizedBox(height: 16),
            Text(
              "Sincronizando Pokédex...",
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
            ),
          ],
        );

      case PokedexState.grid:
        if (_viewModel.filteredList.isEmpty && _searchController.text.isEmpty) {
          return _buildEmptyState('Carregando Lista...'); // Fallback rápido
        }
        if (_viewModel.filteredList.isEmpty) {
          return _buildEmptyState('Nenhum Pokémon encontrado.');
        }
        return _buildGrid();

      case PokedexState.loadingDetails:
        return Center(
          key: const ValueKey('loadingDetails'),
          child: CircularProgressIndicator(color: _primaryColor),
        );

      case PokedexState.details:
        if (_viewModel.selectedPokemon == null) {
          return _buildErrorState('Erro ao carregar detalhes.');
        }
        return _buildPokemonDetails(_viewModel.selectedPokemon!);

      case PokedexState.error:
        return _buildErrorState(_viewModel.errorMessage ?? 'Erro desconhecido');
    }
  }

  // --- GRID VIEW PARA CARDS --- //
  Widget _buildGrid() {
    final double screenWidth = MediaQuery.of(context).size.width;

    // Responsividade: define quantas colunas baseado no tamanho da tela
    int crossAxisCount = 2; // Celular
    if (screenWidth >= 1200) {
      crossAxisCount = 6; // Desktop Largo
    } else if (screenWidth >= 800) {
      crossAxisCount = 4; // Tablet ou Desktop Normal
    } else if (screenWidth >= 600) {
      crossAxisCount = 3; // Tablet Retrato
    }

    return GridView.builder(
      key: const ValueKey('grid'),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 0.8,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _viewModel.filteredList.length,
      itemBuilder: (context, index) {
        final poke = _viewModel.filteredList[index];
        return _buildPokemonCard(poke);
      },
    );
  }

  Widget _buildPokemonCard(PokemonListItem p) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        _viewModel.fetchPokemonDetails(p.id);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Fundo circular de luz
            Positioned(
              right: -10,
              bottom: -10,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.formattedId,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    p.formattedName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Expanded(
                    child: Center(
                      child: Hero(
                        tag: 'poke_img_${p.id}', // Se for usar PageRoute dps
                        child: Image.network(
                          p.imageUrl,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.catching_pokemon,
                              size: 40,
                              color: Colors.white.withValues(alpha: 0.2),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      key: const ValueKey('empty'),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 60,
            color: Colors.white.withValues(alpha: 0.1),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      key: const ValueKey('error'),
      child: Container(
        padding: const EdgeInsets.all(24),
        margin: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red, fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _viewModel.backToGrid(),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text(
                'Voltar',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- TELA DE DETALHES --- //
  Widget _buildPokemonDetails(PokemonModel p) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800), // Limita em Desktop
        child: SingleChildScrollView(
          key: ValueKey('details_full_${p.id}'),
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 10, 24, 40),
          child: Column(
            children: [
              // Área da Imagem (Hero / GIF) com fundo circular sutil
              SizedBox(
                height: 220,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.05),
                        boxShadow: [
                          BoxShadow(
                            color: _primaryColor.withValues(alpha: 0.2),
                            blurRadius: 40,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      constraints: const BoxConstraints(
                        minHeight: 120,
                        maxHeight:
                            180, // Evita esticar demais e ficar feio no Desktop
                      ),
                      child: Image.network(
                        _viewModel.isShiny ? p.shinyAnimatedUrl : p.animatedUrl,
                        filterQuality: FilterQuality
                            .none, // Point Sampling! Magia pro SVG/PixelArt ficar nítido
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          // Fallback se o GIF falhar (Fotos normais HD, usamos qualidade default high)
                          return Image.network(
                            _viewModel.isShiny ? p.shinyImageUrl : p.imageUrl,
                            fit: BoxFit.contain,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Nome e ID
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    p.formattedName,
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      p.formattedId,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                ],
              ),

              if (p.isLegendary) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.purpleAccent, Colors.blueAccent],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'LENDÁRIO / MÍTICO',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // Tipos
              Wrap(
                spacing: 12,
                children: p.types.map((t) => _buildTypeBadge(t)).toList(),
              ),

              const SizedBox(height: 24),

              // Botões Shiny
              Center(
                child: ActionChip(
                  avatar: Icon(
                    Icons.auto_awesome,
                    color: _viewModel.isShiny
                        ? Colors.yellowAccent
                        : Colors.white54,
                    size: 16,
                  ),
                  label: Text(
                    'Shiny',
                    style: TextStyle(
                      color: _viewModel.isShiny
                          ? Colors.yellowAccent
                          : Colors.white,
                    ),
                  ),
                  backgroundColor: _viewModel.isShiny
                      ? Colors.yellowAccent.withValues(alpha: 0.2)
                      : Colors.white.withValues(alpha: 0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: _viewModel.isShiny
                          ? Colors.yellowAccent.withValues(alpha: 0.5)
                          : Colors.white24,
                    ),
                  ),
                  onPressed: () => _viewModel.toggleShiny(),
                ),
              ),

              const SizedBox(height: 30),

              // Info Card (Glassmorphism)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (p.description.isNotEmpty) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(16),
                          border: Border(
                            left: BorderSide(color: _primaryColor, width: 4),
                          ),
                        ),
                        child: Text(
                          '"${p.description}"',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.white.withValues(alpha: 0.9),
                            height: 1.5,
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    const Text(
                      'BASE STATS',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildStatRow('HP', p.hp),
                    _buildStatRow('Ataque', p.attack),
                    _buildStatRow('Defesa', p.defense),
                    _buildStatRow('Sp. Atk', p.specialAttack),
                    _buildStatRow('Sp. Def', p.specialDefense),
                    _buildStatRow('Velocidade', p.speed),

                    if (p.evolutions.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Divider(color: Colors.white.withValues(alpha: 0.1)),
                      const SizedBox(height: 20),
                      const Text(
                        'LINHA EVOLUTIVA',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 20),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: _buildEvolutionChainRow(
                            p.evolutions,
                            p.id,
                            p.speciesId,
                          ),
                        ),
                      ),
                    ],

                    // Regra: As Varieties GMAX, Mega, etc. Só aparecem se esta espécie em específico for um Estágio Final (Leaf)
                    if (p.varieties.length > 1 &&
                        _isFinalStage(p.evolutions, p.speciesId)) ...[
                      const SizedBox(height: 24),
                      Divider(color: Colors.white.withValues(alpha: 0.1)),
                      const SizedBox(height: 20),
                      const Text(
                        'FORMAS ESPECIAIS',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                          color: Colors.purpleAccent,
                        ),
                      ),
                      const SizedBox(height: 20),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: _buildVarietiesRow(
                            p.varieties,
                            p.name,
                            p.speciesId,
                          ),
                        ),
                      ),
                    ],

                    // Encounters (Módulo de Locais Agrupados por Jogo)
                    if (p.encounters.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Divider(color: Colors.white.withValues(alpha: 0.1)),
                      const SizedBox(height: 20),
                      const Text(
                        'LOCAIS E JOGOS',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                          color: Colors.lightGreenAccent,
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Loop criando uma Sanfona(ExpansionTile) para cada Jogo
                      ...p.encounters.entries.map((entry) {
                        final gameName = entry.key;
                        final locations = entry.value;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: Theme(
                            data: Theme.of(context).copyWith(
                              dividerColor: Colors
                                  .transparent, // Remove as linhas nativas do Material
                            ),
                            child: ExpansionTile(
                              title: Text(
                                gameName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              leading: const Icon(
                                Icons.gamepad,
                                color: Colors.lightGreenAccent,
                              ),
                              iconColor: Colors.lightGreenAccent,
                              collapsedIconColor: Colors.white54,
                              collapsedBackgroundColor: Colors.black.withValues(
                                alpha: 0.3,
                              ),
                              backgroundColor: Colors.black.withValues(
                                alpha: 0.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: Colors.lightGreenAccent.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                              ),
                              collapsedShape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.1),
                                ),
                              ),
                              childrenPadding: const EdgeInsets.only(
                                left: 16,
                                right: 16,
                                bottom: 16,
                                top: 0,
                              ),
                              children: locations.map((loc) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4.0,
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.place,
                                        color: Colors.white30,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          loc,
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildEvolutionChainRow(
    List<EvolutionNode> evolutions,
    int currentId,
    int speciesId,
  ) {
    List<Widget> children = [];
    for (int i = 0; i < evolutions.length; i++) {
      final evo = evolutions[i];
      final isCurrent = evo.id == currentId || evo.id == speciesId;

      children.add(
        GestureDetector(
          onTap: () {
            if (!isCurrent) {
              _viewModel.fetchPokemonDetails(evo.id);
            }
          },
          child: Column(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCurrent
                      ? _primaryColor.withValues(alpha: 0.2)
                      : Colors.white.withValues(alpha: 0.05),
                  border: Border.all(
                    color: isCurrent
                        ? _primaryColor
                        : Colors.white.withValues(alpha: 0.1),
                    width: isCurrent ? 2 : 1,
                  ),
                ),
                child: Center(
                  child: Image.network(
                    evo.imageUrl,
                    width: 60,
                    height: 60,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.catching_pokemon,
                      color: Colors.white30,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                evo.formattedName,
                style: TextStyle(
                  color: isCurrent ? _primaryColor : Colors.white70,
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );

      // Seta indicativa para o próximo estágio
      if (i < evolutions.length - 1) {
        children.add(
          const Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 20,
            ), // alinha com a imagem e cima do texto
            child: Icon(
              Icons.arrow_forward_ios,
              color: Colors.white30,
              size: 16,
            ),
          ),
        );
      }
    }
    return children;
  }

  // --- Lógica de Componentes Relacionais --- //

  bool _isFinalStage(List<EvolutionNode> chain, int currentSpeciesId) {
    if (chain.isEmpty)
      return true; // Pokémon únicos que não evoluem (Lendários) são Leaf
    try {
      final node = chain.firstWhere((e) => e.id == currentSpeciesId);
      return node.isLeaf;
    } catch (_) {
      return false;
    }
  }

  List<Widget> _buildVarietiesRow(
    List<PokemonVariety> varieties,
    String currentName,
    int speciesId,
  ) {
    List<Widget> children = [];
    for (int i = 0; i < varieties.length; i++) {
      final v = varieties[i];
      final isCurrent = v.name == currentName;

      children.add(
        GestureDetector(
          onTap: () {
            if (!isCurrent) {
              _viewModel.fetchSpecificVariety(v.url, speciesId);
            }
          },
          child: Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCurrent
                        ? Colors.purpleAccent.withValues(alpha: 0.2)
                        : Colors.white.withValues(alpha: 0.05),
                    border: Border.all(
                      color: isCurrent
                          ? Colors.purpleAccent
                          : Colors.white.withValues(alpha: 0.1),
                      width: isCurrent ? 2 : 1,
                    ),
                  ),
                  child: Center(
                    child: Image.network(
                      v.imageUrl,
                      width: 60,
                      height: 60,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.star, color: Colors.white30),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  v.formattedName,
                  style: TextStyle(
                    color: isCurrent ? Colors.purpleAccent : Colors.white70,
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return children;
  }

  Widget _buildTypeBadge(String type) {
    final color = _getTypeColor(type);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getTypeIcon(type), size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            type.toUpperCase(),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, int value) {
    final double percentage = (value / 150).clamp(0.0, 1.0);

    Color statColor = Colors.redAccent;
    if (value >= 100) {
      statColor = Colors.greenAccent;
    } else if (value >= 70) {
      statColor = Colors.orangeAccent;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(
            width: 36,
            child: Text(
              value.toString().padLeft(3, '0'),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 6,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(3),
              ),
              alignment: Alignment.centerLeft,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutCubic,
                width: MediaQuery.of(context).size.width * 0.5 * percentage,
                height: 6,
                decoration: BoxDecoration(
                  color: statColor,
                  borderRadius: BorderRadius.circular(3),
                  boxShadow: [
                    BoxShadow(
                      color: statColor.withValues(alpha: 0.5),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getTypeColor(String type) {
    const colors = {
      'normal': Color(0xFFA8A77A),
      'fire': Color(0xFFEE8130),
      'water': Color(0xFF6390F0),
      'electric': Color(0xFFF7D02C),
      'grass': Color(0xFF7AC74C),
      'ice': Color(0xFF96D9D6),
      'fighting': Color(0xFFC22E28),
      'poison': Color(0xFFA33EA1),
      'ground': Color(0xFFE2BF65),
      'flying': Color(0xFFA98FF3),
      'psychic': Color(0xFFF95587),
      'bug': Color(0xFFA6B91A),
      'rock': Color(0xFFB6A136),
      'ghost': Color(0xFF735797),
      'dragon': Color(0xFF6F35FC),
      'dark': Color(0xFF705746),
      'steel': Color(0xFFB7B7CE),
      'fairy': Color(0xFFD685AD),
    };
    return colors[type.toLowerCase()] ?? const Color(0xFF1DA1F2);
  }

  IconData _getTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'fire':
        return Icons.local_fire_department;
      case 'water':
        return Icons.water_drop;
      case 'grass':
        return Icons.eco;
      case 'electric':
        return Icons.bolt;
      case 'ice':
        return Icons.ac_unit;
      case 'fighting':
        return Icons.sports_mma;
      case 'poison':
        return Icons.science;
      case 'ground':
        return Icons.landscape;
      case 'flying':
        return Icons.air;
      case 'psychic':
        return Icons.visibility;
      case 'bug':
        return Icons.bug_report;
      case 'rock':
        return Icons.terrain;
      case 'ghost':
        return Icons.nights_stay;
      case 'dragon':
        return Icons.local_fire_department;
      case 'dark':
        return Icons.dark_mode;
      case 'steel':
        return Icons.hardware;
      case 'fairy':
        return Icons.auto_awesome;
      default:
        return Icons.circle;
    }
  }
}
