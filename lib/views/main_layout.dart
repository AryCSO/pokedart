import 'package:flutter/material.dart';
import 'package:sidebarx/sidebarx.dart';

import 'pokedex_page.dart';
import 'items_page.dart';
import 'regions_page.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  final _controller = SidebarXController(selectedIndex: 0, extended: true);
  final _key = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    // Detecta se é mobile para esconder a sidebar por default
    final isSmallScreen = MediaQuery.of(context).size.width < 800;

    return Scaffold(
      key: _key,
      backgroundColor: Colors.black,
      appBar: isSmallScreen
          ? AppBar(
              backgroundColor: Colors.black,
              title: const Text(
                'PokéDart',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              leading: IconButton(
                onPressed: () {
                  _key.currentState?.openDrawer();
                },
                icon: const Icon(Icons.menu, color: Colors.white),
              ),
            )
          : null,
      drawer: isSmallScreen ? _buildSidebar() : null,
      body: Row(
        children: [
          if (!isSmallScreen) _buildSidebar(),
          Expanded(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                switch (_controller.selectedIndex) {
                  case 0:
                    return const PokedexPage();
                  case 1:
                    return const ItemsPage();
                  case 2:
                    return const RegionsPage();
                  case 3:
                    return _buildPlaceholderPage('Favoritos');
                  default:
                    return const PokedexPage();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return SidebarX(
      controller: _controller,
      theme: SidebarXTheme(
        margin: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
        ),
        textStyle: const TextStyle(color: Colors.white70),
        selectedTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
        itemTextPadding: const EdgeInsets.only(left: 14),
        selectedItemTextPadding: const EdgeInsets.only(left: 14),
        itemDecoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
        selectedItemDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: const LinearGradient(
            colors: [Color(0xFFE3350D), Color(0xFFF95587)], // Gradiente Pokédex
          ),
          boxShadow: [
            BoxShadow(color: Colors.red.withValues(alpha: 0.3), blurRadius: 10),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.white70, size: 20),
        selectedIconTheme: const IconThemeData(color: Colors.white, size: 20),
      ),
      extendedTheme: const SidebarXTheme(
        width: 200,
        decoration: BoxDecoration(color: Colors.black),
      ),
      headerBuilder: (context, extended) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Icon(
              Icons.catching_pokemon,
              color: Colors.white,
              size: extended ? 50 : 30,
            ),
          ),
        );
      },
      items: const [
        SidebarXItem(icon: Icons.search, label: 'Pokédex'),
        SidebarXItem(icon: Icons.backpack, label: 'Itens'),
        SidebarXItem(icon: Icons.map, label: 'Regiões'),
        SidebarXItem(icon: Icons.favorite, label: 'Favoritos'),
      ],
    );
  }

  Widget _buildPlaceholderPage(String title) {
    return Center(
      child: Text(
        '$title em Breve!',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.5),
          fontSize: 24,
        ),
      ),
    );
  }
}
