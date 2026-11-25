import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'models/producto.dart';
import 'screens/auth_gate.dart';
import 'screens/detalle_screen.dart';
import 'screens/editar_screen.dart';
import 'screens/inventario_screen.dart';
import 'screens/registro_screen.dart';
import 'screens/ventas_screen.dart';
import 'utils/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Conecta la app con el proyecto de Firebase (Auth + Cloud Firestore).
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const InventarioYaApp());
}

class InventarioYaApp extends StatelessWidget {
  const InventarioYaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'InventarioYa',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      // AuthGate muestra Login o Inicio según haya sesión.
      home: const AuthGate(),
      routes: {
        '/registro': (_) => const RegistroScreen(),
        '/inventario': (_) => const InventarioScreen(),
        '/ventas': (_) => const VentasScreen(),
      },
      // Rutas que reciben argumentos.
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/detalle':
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => DetalleScreen(productoId: settings.arguments as String),
            );
          case '/editar':
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => EditarScreen(producto: settings.arguments as Producto),
            );
        }
        return null;
      },
    );
  }
}
