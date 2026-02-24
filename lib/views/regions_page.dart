import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/region_viewmodel.dart';

class RegionsPage extends StatefulWidget {
  const RegionsPage({super.key});

  @override
  State<RegionsPage> createState() => _RegionsPageState();
}

class _RegionsPageState extends State<RegionsPage> {
  @override
  void initState() {
    super.initState();
    // Inicia a call das regiões só se a lista ainda for vazia
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<RegionViewModel>();
      if (vm.regionsList.isEmpty && vm.state != RegionsState.loading) {
        vm.fetchRegions();
      }
    });
  }

  // --- Função Helpper para Cores baseadas no ID (Geração da Região) ---
  LinearGradient _getRegionGradient(int id) {
    switch (id) {
      case 1: // Kanto (Red/Blue/Green)
        return const LinearGradient(
          colors: [Color(0xFFFF3333), Color(0xFF3333FF)],
        );
      case 2: // Johto (Gold/Silver)
        return const LinearGradient(
          colors: [Color(0xFFFFD700), Color(0xFFC0C0C0)],
        );
      case 3: // Hoenn (Ruby/Sapphire)
        return const LinearGradient(
          colors: [Color(0xFFA00000), Color(0xFF0000A0)],
        );
      case 4: // Sinnoh (Diamond/Pearl)
        return const LinearGradient(
          colors: [Color(0xFF5555AA), Color(0xFFAAAAAA)],
        );
      case 5: // Unova (Black/White)
        return const LinearGradient(
          colors: [Color(0xFF111111), Color(0xFFEEEEEE)],
        );
      case 6: // Kalos (X/Y)
        return const LinearGradient(
          colors: [Color(0xFF0055AA), Color(0xFFAA0000)],
        );
      case 7: // Alola (Sun/Moon)
        return const LinearGradient(
          colors: [Color(0xFFFFAA00), Color(0xFF5500AA)],
        );
      case 8: // Galar (Sword/Shield)
        return const LinearGradient(
          colors: [Color(0xFF00AAFF), Color(0xFFAA0055)],
        );
      case 9: // Paldea (Scarlet/Violet)
        return const LinearGradient(
          colors: [Color(0xFFFF3300), Color(0xFF6600AA)],
        );
      default:
        return const LinearGradient(
          colors: [Color(0xFF444444), Color(0xFF222222)],
        );
    }
  }

  void _showRegionDetails(BuildContext context, int regionId) {
    final viewModel = context.read<RegionViewModel>();
    viewModel.fetchRegionDetails(regionId);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          builder: (_, controller) {
            return Consumer<RegionViewModel>(
              builder: (context, vm, child) {
                if (vm.state == RegionsState.loading ||
                    vm.selectedRegion == null) {
                  return const SizedBox(
                    height: 300,
                    child: Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  );
                }

                final region = vm.selectedRegion!;

                return ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.only(
                        top: 24,
                        left: 24,
                        right: 24,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        border: Border(
                          top: BorderSide(
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Handle Slider
                          Center(
                            child: Container(
                              width: 40,
                              height: 4,
                              margin: const EdgeInsets.only(bottom: 20),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),

                          // Header
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                region.formattedName,
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  region.mainGeneration,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Rotas e Cidades Exploráveis',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Lista de Cidades Restante (Consumindo o espaço do ScrollableSheet)
                          Expanded(
                            child: region.locations.isNotEmpty
                                ? ListView.builder(
                                    controller: controller,
                                    physics: const BouncingScrollPhysics(),
                                    itemCount: region.locations.length,
                                    itemBuilder: (context, index) {
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 8.0,
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
                                                region.locations[index],
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  )
                                : const Center(
                                    child: Text(
                                      'Nenhum local catalogado para esta região.',
                                      style: TextStyle(color: Colors.white54),
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    ).whenComplete(() {
      viewModel.resetToLoadedState();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(24.0),
          child: Text(
            'Continentes',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: Consumer<RegionViewModel>(
            builder: (context, viewModel, child) {
              if (viewModel.state == RegionsState.loading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (viewModel.state == RegionsState.error &&
                  viewModel.regionsList.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.public_off,
                        color: Colors.white54,
                        size: 64,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        viewModel.errorMessage,
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () =>
                            viewModel.fetchRegions(isRefresh: true),
                        child: const Text('Tentar Novamente'),
                      ),
                    ],
                  ),
                );
              }

              return LayoutBuilder(
                builder: (context, constraints) {
                  // Ajusta dinamicamente a coluna
                  int crossAxisCount = constraints.maxWidth > 800 ? 3 : 2;

                  return GridView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      childAspectRatio: 1.5,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: viewModel.regionsList.length,
                    itemBuilder: (context, index) {
                      final region = viewModel.regionsList[index];

                      return GestureDetector(
                        onTap: () => _showRegionDetails(context, region.id),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: _getRegionGradient(region.id),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              // Textura/Icon de background (Efeito marca d'água)
                              Positioned(
                                right: -20,
                                bottom: -20,
                                child: Icon(
                                  Icons.public,
                                  size: 100,
                                  color: Colors.white.withValues(alpha: 0.1),
                                ),
                              ),
                              // Titulo Frontal
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      region.formattedName,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Região #${region.id}',
                                      style: TextStyle(
                                        color: Colors.white.withValues(
                                          alpha: 0.7,
                                        ),
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
