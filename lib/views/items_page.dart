import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/item_viewmodel.dart';

class ItemsPage extends StatefulWidget {
  const ItemsPage({super.key});

  @override
  State<ItemsPage> createState() => _ItemsPageState();
}

class _ItemsPageState extends State<ItemsPage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    // Busca inicial apenas se a lista estiver vazia
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<ItemViewModel>();
      if (vm.itemsList.isEmpty && vm.state != ItemsState.loading) {
        vm.fetchItems();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<ItemViewModel>().fetchItems();
    }
  }

  void _showItemDetails(BuildContext context, int itemId) {
    final viewModel = context.read<ItemViewModel>();
    viewModel.fetchItemDetails(itemId);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) {
        return Consumer<ItemViewModel>(
          builder: (context, vm, child) {
            if (vm.state == ItemsState.loading || vm.selectedItem == null) {
              return const SizedBox(
                height: 300,
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xFF1DA1F2)),
                ),
              );
            }

            final item = vm.selectedItem!;

            return ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    border: Border(
                      top: BorderSide(
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Handle Slider
                      Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),

                      // Image & Title Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.network(
                            item.imageUrl,
                            width: 60,
                            height: 60,
                            fit: BoxFit.contain,
                            filterQuality:
                                FilterQuality.none, // Pixel Art style
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.formattedName,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF1DA1F2,
                                    ).withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: const Color(0xFF1DA1F2),
                                    ),
                                  ),
                                  child: Text(
                                    item.formattedCategory,
                                    style: const TextStyle(
                                      color: Color(0xFF1DA1F2),
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Cost Badget
                          if (item.cost > 0)
                            Column(
                              children: [
                                const Icon(
                                  Icons.monetization_on,
                                  color: Colors.amber,
                                  size: 20,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${item.cost}',
                                  style: const TextStyle(
                                    color: Colors.amber,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),

                      const SizedBox(height: 24),
                      Divider(color: Colors.white.withValues(alpha: 0.1)),
                      const SizedBox(height: 16),

                      // Effect (If exists)
                      if (item.effect.isNotEmpty) ...[
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Efeito',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          item.effect,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.justify,
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Flavor Lore Text (Glassmorphism Container)
                      if (item.description.isNotEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(16),
                            border: const Border(
                              left: BorderSide(
                                color: Color(0xFF1DA1F2),
                                width: 4,
                              ),
                            ),
                          ),
                          child: Text(
                            '"${item.description}"',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.9),
                              height: 1.5,
                              fontStyle: FontStyle.italic,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
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
      children: [
        // Search Bar Area
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Buscar item...',
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
              prefixIcon: const Icon(Icons.search, color: Color(0xFF1DA1F2)),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.white54),
                      onPressed: () {
                        _searchController.clear();
                        context.read<ItemViewModel>().search('');
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.1),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (value) {
              context.read<ItemViewModel>().search(value);
            },
          ),
        ),

        // Grid Area
        Expanded(
          child: Consumer<ItemViewModel>(
            builder: (context, viewModel, child) {
              if (viewModel.state == ItemsState.error &&
                  viewModel.itemsList.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        viewModel.errorMessage,
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => viewModel.fetchItems(isRefresh: true),
                        child: const Text('Tentar Novamente'),
                      ),
                    ],
                  ),
                );
              }

              if (viewModel.itemsList.isEmpty &&
                  viewModel.state == ItemsState.loading) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFF1DA1F2)),
                );
              }

              return RefreshIndicator(
                color: const Color(0xFF1DA1F2),
                backgroundColor: Colors.grey[900],
                onRefresh: () => viewModel.fetchItems(isRefresh: true),
                child: GridView.builder(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.85,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount:
                      viewModel.itemsList.length +
                      (viewModel.hasReachedMax ? 0 : 1),
                  itemBuilder: (context, index) {
                    if (index >= viewModel.itemsList.length) {
                      return const Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Color(0xFF1DA1F2),
                            strokeWidth: 2,
                          ),
                        ),
                      );
                    }

                    final item = viewModel.itemsList[index];

                    return GestureDetector(
                      onTap: () => _showItemDetails(context, item.id),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.network(
                              item.imageUrl,
                              width: 40,
                              height: 40,
                              fit: BoxFit.contain,
                              filterQuality: FilterQuality.none,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(
                                    Icons.backpack,
                                    color: Colors.white30,
                                    size: 30,
                                  ),
                            ),
                            const SizedBox(height: 12),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4.0,
                              ),
                              child: Text(
                                item.formattedName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
