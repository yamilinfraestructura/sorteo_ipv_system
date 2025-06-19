# Sorteo IPV System

Sistema de Sorteos para Padrones de Participantes

---

## Descripción

**Sorteo IPV System** es una aplicación de escritorio desarrollada en Flutter para la gestión de sorteos de padrones de participantes, ideal para rifas, concursos o sorteos institucionales. Permite importar, buscar, registrar, listar y exportar ganadores de manera sencilla y visual.

---

## Funcionalidades principales

- **Importar Padrón:**
  - Importa archivos Excel (.xlsx) con los datos de los participantes (DNI, nombre, barrio, grupo, número de bolilla).
  - Visualiza los padrones importados por barrio y consulta los participantes de cada uno.

- **Buscar y Registrar Ganador:**
  - Selecciona un barrio y busca participantes por número de bolilla.
  - Registra ganadores y visualiza los últimos ganadores registrados para el barrio seleccionado.

- **Ganadores Sorteados:**
  - Lista todos los ganadores registrados.
  - Filtra por barrio y grupo, o muestra todos.

- **Exportar Ganadores:**
  - Exporta la lista de ganadores a un archivo Excel listo para compartir o imprimir.

---

## Tecnologías y dependencias

- **Flutter** (Material 3)
- **sqflite_common_ffi**: Base de datos local para persistencia multiplataforma.
- **excel**: Lectura y escritura de archivos Excel.
- **file_picker**: Selección de archivos del sistema.
- **intl**: Formateo de fechas y textos.

---

## Instalación y ejecución

1. **Clona el repositorio:**
   ```bash
   git clone <URL_DEL_REPOSITORIO>
   cd sorteo_ipv_system
   ```
2. **Instala las dependencias:**
   ```bash
   flutter pub get
   ```
3. **Ejecuta la aplicación:**
   ```bash
   flutter run -d windows
   ```
   > También puedes correr en Linux, MacOS o Web si tienes el entorno configurado.

---

## Estructura de la app

- `lib/src/presentation/pages/home_page.dart`: Página principal con navegación lateral.
- `lib/src/presentation/screens/import_padrones_screen.dart`: Importación y visualización de padrones.
- `lib/src/presentation/screens/search_participante_screen.dart`: Búsqueda y registro de ganadores.
- `lib/src/presentation/screens/list_ganadores_screen.dart`: Listado y filtrado de ganadores.
- `lib/src/presentation/screens/export_ganadores_screen.dart`: Exportación de ganadores a Excel.
- `lib/src/data/helper/database_helper.dart`: Lógica de base de datos local.

---

## Formato del archivo Excel de participantes

El archivo debe tener las siguientes columnas (en este orden):

| DNI        | Nombre         | Barrio        | Grupo        | Número de bolilla |
|------------|----------------|---------------|--------------|-------------------|
| 12345678   | Juan Pérez     | Barrio Norte  | Grupo A      | 1                 |
| ...        | ...            | ...           | ...          | ...               |

---

## Licencia

MIT. Puedes usar, modificar y distribuir este software libremente.

---

## Autor

Desarrollado por Yamil Saad, Desarrollador de Software.
Ministerio de Infraestructura, Agua y Energía.
Gobierno de San Juan.
