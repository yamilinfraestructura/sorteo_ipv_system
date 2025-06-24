import 'package:flutter/material.dart';

//Importaciones de archivos
import 'package:sorteo_ipv_system/src/presentation/screens/screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int selectedIndex = 0;

  final List<Widget> _screens = const [
    ImportPadronesScreen(),
    SearchParticipanteScreen(),
    ListGanadoresScreen(),
    ExportGanadoresScreen(),
  ];

  final List<String> _titles = [
    "Importar Participantes",
    "Buscar Ganador",
    "Listado de Ganadores",
    "Exportar a Excel",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.orange,
        title: Text('Sorteo oficial de Viviendas del IPV- San Juan 2025'),
        elevation: 3.0,
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
                Expanded(
                  child: _screens[selectedIndex],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}