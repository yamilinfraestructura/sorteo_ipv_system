import 'package:flutter/material.dart';
import 'package:get/get.dart';

//Importaciones de archivos
import 'package:sorteo_ipv_system/src/config/themes/responsive_config.dart';
import 'package:sorteo_ipv_system/src/presentation/screens/screen.dart';
import 'package:sorteo_ipv_system/src/presentation/screens/login_screen/login_controller.dart';
import 'package:sorteo_ipv_system/src/presentation/screens/settings_screen/settings_screen.dart';
import 'package:sorteo_ipv_system/src/presentation/screens/widgets/membrete_widget.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int selectedIndex = 0;
  bool isRailExtended = true;

  final List<Widget> _screens = [
    // CrearSorteoScreen(), // Comentado temporalmente - no se utilizará por el momento
    ImportPadronesScreen(),
    SearchParticipanteScreen(),
    ListGanadoresScreen(),
    ExportGanadoresScreen(),
    SettingsScreen(),
  ];

  final List<String> _titles = [
    // "Nuevo Sorteo", // Comentado temporalmente - no se utilizará por el momento
    "Importar Participantes",
    "Buscar Ganador",
    "Listado de Ganadores",
    "Exportar a Excel",
    "Configuración",
  ];

  @override
  Widget build(BuildContext context) {
    // Inicializar ResponsiveConfig para obtener standarSize
    ResponsiveConfig.init(context);
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(
          ResponsiveConfig.standarSize * 0.07,
        ), // Equivalente a 90
        child: AppBar(
          toolbarHeight:
              ResponsiveConfig.standarSize * 0.06, // Equivalente a 100
          backgroundColor: Color(0xffFFF2EB),
          elevation: 0.0,
          title: Padding(
            padding: EdgeInsets.only(
              top: ResponsiveConfig.standarSize * 0.015,
            ), // Equivalente a 15
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: ResponsiveConfig.standarSize * 0.01,
                  ), // Equivalente a 10
                  child: Image.asset(
                    'assets/images/logo.png',
                    width:
                        ResponsiveConfig.standarSize * 0.06, // Equivalente a 75
                    height:
                        ResponsiveConfig.standarSize * 0.04, // Equivalente a 50
                  ),
                ),
                SizedBox(
                  width: ResponsiveConfig.standarSize * 0.010,
                ), // Equivalente a 12
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Sorteo oficial de Viviendas del IPV- San Juan 2025',
                        style: TextStyle(
                          color: Color(0xffD84040),
                          fontSize:
                              ResponsiveConfig.standarSize *
                              0.016, // Equivalente a 25
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(
                        height: ResponsiveConfig.standarSize * 0.004,
                      ), // Equivalente a 4
                      Builder(
                        builder: (context) {
                          final loginCtrl = Get.find<LoginController>();
                          final user = loginCtrl.usuarioLogueado.value;
                          final nombre = user?['user_name']?.toString() ?? '';
                          return Text(
                            nombre.isNotEmpty ? nombre : '',
                            style: TextStyle(
                              color: Colors.grey[800],
                              fontSize:
                                  ResponsiveConfig.standarSize *
                                  0.014, // Equivalente a 20
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          );
                        },
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: ResponsiveConfig.standarSize * 0.012,
                ), // Equivalente a 12
              ],
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: TextButton.icon(
                icon: Icon(
                  Icons.logout,
                  color: Color(0xffD84040),
                  size:
                      ResponsiveConfig.standarSize *
                      0.01125, // iconSizeSmall (15) * 0.75 = 11.25
                ),
                label: Text(
                  'Cerrar Sesión',
                  style: TextStyle(
                    color: Color(0xffD84040),
                    fontSize:
                        ResponsiveConfig.standarSize *
                        0.009, // subtitleSize (18) * 0.5 = 9
                  ),
                ),
                onPressed: () {
                  final loginCtrl = Get.find<LoginController>();
                  loginCtrl.usuarioLogueado.value = null;
                  Get.offAllNamed('/login');
                },
              ),
            ),
          ],
        ),
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Column(
            children: [
              Expanded(
                child: NavigationRail(
                  indicatorShape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                  ),
                  selectedIndex: selectedIndex,
                  onDestinationSelected: (int index) {
                    setState(() {
                      selectedIndex = index;
                    });
                  },
                  labelType: NavigationRailLabelType.none,
                  extended: isRailExtended,
                  destinations: [
                    // NavigationRailDestination(
                    //   icon: Icon(Icons.upload_file_rounded, size: 32),
                    //   label: Text(
                    //     'Crear Sorteo',
                    //     style: TextStyle(fontSize: 18),
                    //   ),
                    // ), // Comentado temporalmente - no se utilizará por el momento
                    NavigationRailDestination(
                      icon: Icon(Icons.upload_file, size: 32),
                      label: Text(
                        'Importar Padrón',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.search, size: 32),
                      label: Text(
                        'Buscar y Registrar',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.list_alt, size: 32),
                      label: Text(
                        'Lista Ganadores',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.download, size: 32),
                      label: Text(
                        'Exportar Ganadores',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.settings, size: 32),
                      label: Text(
                        'Configuración',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 20.0),
                child: IconButton(
                  icon: Icon(
                    isRailExtended
                        ? Icons.arrow_back_ios
                        : Icons.arrow_forward_ios,
                    color: Colors.black,
                  ),
                  tooltip: isRailExtended ? 'Contraer menú' : 'Expandir menú',
                  onPressed: () {
                    setState(() {
                      isRailExtended = !isRailExtended;
                    });
                  },
                ),
              ),
            ],
          ),
          VerticalDivider(
            thickness: 1,
            width: ResponsiveConfig.standarSize * 0.01,
          ), // Equivalente a 10
          // Área principal
          Expanded(
            child: Column(
              children: [
                AppBar(
                  title: Row(
                    children: [
                      Text(
                        _titles[selectedIndex],
                        style: TextStyle(
                          fontSize:
                              ResponsiveConfig.standarSize *
                              0.016, // Equivalente a 18
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(
                        width: ResponsiveConfig.standarSize * 0.01,
                      ), // Equivalente a 10
                      MembreteWidget(),
                    ],
                  ),
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
