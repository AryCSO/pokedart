import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import 'views/main_layout.dart';
import 'viewmodels/pokedex_viewmodel.dart';
import 'viewmodels/item_viewmodel.dart';
import 'viewmodels/region_viewmodel.dart';

void main() {
  runApp(const PokedexApp());
}

class PokedexApp extends StatelessWidget {
  const PokedexApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PokedexViewModel()),
        ChangeNotifierProvider(create: (_) => ItemViewModel()),
        ChangeNotifierProvider(create: (_) => RegionViewModel()),
      ],
      child: MaterialApp(
        title: 'Pokédex',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          primaryColor: const Color(0xFF1DA1F2),
          scaffoldBackgroundColor: Colors.black,
        ),
        home: const MainLayout(),
      ),
    );
  }
}
