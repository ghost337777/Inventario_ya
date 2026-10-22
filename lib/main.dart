import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'screens/inventario_screen.dart';
import 'screens/registro_screen.dart';
import 'utils/app_theme.dart';

void main() => runApp(const InventarioYaApp());

class InventarioYaApp extends StatelessWidget {
  const InventarioYaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'InventarioYa',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: '/',
      routes: {
        '/': (_) => const HomeScreen(),
        '/registro': (_) => const RegistroScreen(),
        '/inventario': (_) => const InventarioScreen(),
      },
    );
  }
}
