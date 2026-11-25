import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../utils/app_theme.dart';
import '../utils/errores.dart';
import '../utils/validators.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_card.dart';
import '../widgets/custom_text_field.dart';

/// PANTALLA DE AUTENTICACIÓN: inicio de sesión y creación de cuenta.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _correoCtrl = TextEditingController();
  final _claveCtrl = TextEditingController();
  final _tiendaCtrl = TextEditingController();

  bool _modoRegistro = false;
  bool _verClave = false;
  bool _cargando = false;
  String? _error;

  @override
  void dispose() {
    _correoCtrl.dispose();
    _claveCtrl.dispose();
    _tiendaCtrl.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;
    setState(() => _cargando = true);
    try {
      if (_modoRegistro) {
        await AuthService.instance.crearCuenta(
          correo: _correoCtrl.text,
          clave: _claveCtrl.text,
          tienda: _tiendaCtrl.text,
        );
      } else {
        await AuthService.instance.iniciarSesion(_correoCtrl.text, _claveCtrl.text);
      }
      // Si todo sale bien, AuthGate muestra automáticamente la pantalla de inicio.
    } catch (e) {
      if (mounted) setState(() => _error = mensajeError(e));
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  /// Prueba de seguridad: intenta leer productos SIN sesión iniciada.
  /// Las reglas de Firestore deben rechazar la consulta (permission-denied).
  Future<void> _probarAccesoSinSesion() async {
    String resultado;
    bool denegado;
    try {
      final snap = await FirebaseFirestore.instance
          .collection('productos')
          .limit(1)
          .get(const GetOptions(source: Source.server));
      resultado = 'La consulta devolvió ${snap.size} documentos. Revisa las reglas de seguridad.';
      denegado = false;
    } catch (e) {
      resultado = mensajeError(e);
      denegado = true;
    }
    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(denegado ? Icons.lock_outline : Icons.lock_open,
            color: denegado ? AppColors.alerta : Colors.orange, size: 40),
        title: Text(denegado ? 'Acceso bloqueado' : 'Atención'),
        content: Text('Usuario no autenticado intentó leer la colección "productos".\n\n$resultado'),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Entendido'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.storefront, size: 72, color: AppColors.primary),
                  const SizedBox(height: 8),
                  const Text('InventarioYa',
                      textAlign: TextAlign.center, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                  Text(_modoRegistro ? 'Crea la cuenta de tu tienda' : 'Inicia sesión para ver tu inventario',
                      textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textoSuave)),
                  const SizedBox(height: 28),
                  if (_modoRegistro) ...[
                    CustomTextField(
                      controller: _tiendaCtrl,
                      label: 'Nombre de la tienda',
                      icon: Icons.store_outlined,
                      validator: Validators.nombre,
                    ),
                    const SizedBox(height: 14),
                  ],
                  CustomTextField(
                    controller: _correoCtrl,
                    label: 'Correo electrónico',
                    hint: 'tienda@correo.com',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: Validators.correo,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _claveCtrl,
                    obscureText: !_verClave,
                    validator: Validators.clave,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    onFieldSubmitted: (_) => _enviar(),
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_verClave ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _verClave = !_verClave),
                      ),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    CustomCard(
                      accent: AppColors.alerta,
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: AppColors.alerta),
                          const SizedBox(width: 8),
                          Expanded(child: Text(_error!, style: const TextStyle(color: AppColors.alerta))),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  _cargando
                      ? const Center(child: CircularProgressIndicator())
                      : CustomButton(
                          text: _modoRegistro ? 'Crear cuenta' : 'Iniciar sesión',
                          icon: _modoRegistro ? Icons.person_add_alt : Icons.login,
                          onPressed: _enviar,
                        ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _cargando
                        ? null
                        : () => setState(() {
                              _modoRegistro = !_modoRegistro;
                              _error = null;
                            }),
                    child: Text(_modoRegistro ? '¿Ya tienes cuenta? Inicia sesión' : '¿No tienes cuenta? Regístrate'),
                  ),
                  const Divider(height: 32),
                  TextButton.icon(
                    onPressed: _probarAccesoSinSesion,
                    icon: const Icon(Icons.security, size: 18),
                    label: const Text('Probar acceso a los datos sin iniciar sesión'),
                    style: TextButton.styleFrom(foregroundColor: AppColors.textoSuave),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
