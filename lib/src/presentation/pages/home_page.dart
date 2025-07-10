import 'package:flutter/material.dart';
import 'package:get/get.dart';

//Importaciones de archivos
import 'package:sorteo_ipv_system/src/presentation/screens/screen.dart';
import 'package:sorteo_ipv_system/src/presentation/screens/login_screen/login_controller.dart';
import 'package:sorteo_ipv_system/src/presentation/screens/settings_screen/settings_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int selectedIndex = 0;

  final List<Widget> _screens = [
    ImportPadronesScreen(),
    SearchParticipanteScreen(),
    ListGanadoresScreen(),
    ExportGanadoresScreen(),
    SettingsScreen(),
  ];

  final List<String> _titles = [
    "Importar Participantes",
    "Buscar Ganador",
    "Listado de Ganadores",
    "Exportar a Excel",
    "Configuración",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(90), // Aumenta el height
        child: AppBar(
          backgroundColor: Colors.white,
          elevation: 3.0,
          title: Padding(
            padding: const EdgeInsets.only(top: 5.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 75,
                    height: 50,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Sorteo oficial de Viviendas del IPV- San Juan 2025',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Builder(
                        builder: (context) {
                          final loginCtrl = Get.find<LoginController>();
                          final user = loginCtrl.usuarioLogueado.value;
                          final nombre = user?['user_name']?.toString() ?? '';
                          return Text(
                            nombre.isNotEmpty ? nombre : '',
                            style: TextStyle(
                              color: Colors.grey[200],
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.white,
                  ),

                  child: Image.asset(
                    'assets/images/membrete.jpeg',
                    width: 1000,
                    height: 50,
                    fit: BoxFit.contain,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton.icon(
              icon: const Icon(Icons.logout, color: Colors.white),
              label: const Text(
                'Cerrar Sesión',
                style: TextStyle(color: Colors.white),
              ),
              onPressed: () {
                final loginCtrl = Get.find<LoginController>();
                loginCtrl.usuarioLogueado.value = null;
                Get.offAllNamed('/login');
              },
            ),
          ],
        ),
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          NavigationRail(
            selectedIndex: selectedIndex,
            onDestinationSelected: (int index) {
              setState(() {
                selectedIndex = index;
              });
            },
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.upload_file),
                label: Text('Importar Padrón'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.search),
                label: Text('Buscar y Registrar'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.list_alt),
                label: Text('Ganadores Sorteados'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.download),
                label: Text('Exportar Ganadores'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.settings),
                label: Text('Configuración'),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 10),
          // Área principal
          Expanded(
            child: Column(
              children: [
                AppBar(
                  title: Text(_titles[selectedIndex]),
                  automaticallyImplyLeading: false,
                ),
                Expanded(child: _screens[selectedIndex]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
