import 'package:get/get.dart';
import 'package:sorteo_ipv_system/src/presentation/pages/home_page.dart';
import 'package:sorteo_ipv_system/src/presentation/screens/login_screen/login_screen.dart';
import 'package:sorteo_ipv_system/src/presentation/screens/register_screen/register_screen.dart';
import 'package:sorteo_ipv_system/src/presentation/screens/import_padrones_screen/import_padrones_screen.dart';
import 'package:sorteo_ipv_system/main.dart'; // Para ResponsiveInit
import 'package:sorteo_ipv_system/src/presentation/screens/splash_screen/screen_splash.dart';
import 'package:sorteo_ipv_system/src/presentation/screens/splash_screen/welcome_screen.dart';

class AppRouter {
  static const String initialRoute = '/';

  static final List<GetPage> routes = [
    GetPage(name: '/', page: () => const SplashScreen()),
    GetPage(
      name: '/login',
      page: () => LoginScreen(),
      // binding: LoginBinding(), // Si usas bindings
    ),
    GetPage(
      name: '/register',
      page: () => const RegisterScreen(),
      // binding: RegisterBinding(),
    ),
    GetPage(name: '/home', page: () => ResponsiveInit(child: HomePage())),
    GetPage(
      name: '/import_padrones',
      page: () => ResponsiveInit(child: ImportPadronesScreen()),
    ),
    // Pantalla de bienvenida intermedia
    GetPage(name: '/welcome', page: () => const WelcomeScreen()),
    // Agrega aquí más rutas según crezcas la app
  ];
}
