# InventarioYa

App Flutter para el control de inventario y ventas de tiendas de barrio.
Unidad 3 de Computación Móvil (CUC): persistencia remota, autenticación y sincronización con **Firebase** (Authentication + Cloud Firestore).

## Configurar Firebase (una sola vez)

1. **Crear el proyecto**: entra a https://console.firebase.google.com → *Agregar proyecto* → nombre `inventario-ya` (puedes desactivar Analytics).
2. **Authentication**: *Compilación → Authentication → Comenzar → Método de acceso → Correo electrónico/contraseña → Habilitar → Guardar*.
3. **Firestore**: *Compilación → Firestore Database → Crear base de datos* → ubicación `nam5 (us-central)` o la más cercana → *Iniciar en modo de producción*.
4. **Reglas**: en *Firestore → Reglas*, borra lo que hay, pega el contenido de `firestore.rules` y pulsa *Publicar*.
5. **Conectar la app** (en la terminal, dentro de la carpeta del proyecto):
   ```bash
   npm install -g firebase-tools        # requiere Node.js
   firebase login
   dart pub global activate flutterfire_cli
   flutterfire configure                # elige el proyecto inventario-ya y la plataforma android
   ```
   Esto reemplaza `lib/firebase_options.dart` y agrega `google-services.json` en `android/app/`.
6. **Instalar paquetes y ejecutar**:
   ```bash
   flutter pub get
   flutter run
   ```
   Si `pub get` falla por versiones, ejecuta `flutter pub add firebase_core firebase_auth cloud_firestore` y vuelve a intentar.

## Estructura de datos (Cloud Firestore)

| Colección | Campos |
|---|---|
| `usuarios/{uid}` | correo, tienda, creadoEn |
| `productos/{id}` | uid, nombre, nombreLower, categoria, precio, stock, stockMinimo, perecedero, creadoEn, actualizadoEn |
| `ventas/{id}` | uid, productoId, productoNombre, cantidad, precioUnitario, total, fecha |
| `categorias/{id}` | uid, nombre |

Cada documento guarda el `uid` del dueño; las reglas solo permiten leer o escribir los documentos propios.

## Pantallas

| # | Pantalla | Archivo |
|---|---|---|
| — | Inicio de sesión / crear cuenta | `screens/login_screen.dart` |
| 1 | Inicio (panel) | `screens/home_screen.dart` |
| 2 | Consulta / listado | `screens/inventario_screen.dart` |
| 3 | Registro | `screens/registro_screen.dart` |
| 4 | Detalle | `screens/detalle_screen.dart` |
| 5 | Edición | `screens/editar_screen.dart` |
| 6 | Ventas y caja del día (funcionalidad principal) | `screens/ventas_screen.dart` |
