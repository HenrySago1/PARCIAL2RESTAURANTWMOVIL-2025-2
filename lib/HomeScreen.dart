// -----------------------------------------------------------------
// ARCHIVO COMPLETO: lib/home_screen.dart
// (Versión Final)
// -----------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

// --- ¡CAMBIO AQUÍ! ---
// Ahora importamos la nueva pantalla de selección
import 'table_selection_screen.dart';

// 1. La consulta (sigue igual, pide la foto)
final String getPlatillosQuery = """
  query {
    platillos {
      data {
        id
        attributes {
          nombre
          precio
          foto {
            data {
              attributes {
                url 
              }
            }
          }
        }
      }
    }
  }
""";

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final String strapiBaseUrl = "http://10.0.2.2:1337";

    return Scaffold(
      appBar: AppBar(title: Text('Menú del Restaurante')),

      // 2. El cuerpo sigue siendo el GridView de tarjetas
      body: Query(
        options: QueryOptions(
          document: gql(getPlatillosQuery),
          pollInterval: Duration(seconds: 10),
        ),
        builder: (QueryResult result,
            {VoidCallback? refetch, FetchMore? fetchMore}) {
          if (result.hasException) {
            return Center(child: Text(result.exception.toString()));
          }
          if (result.isLoading) {
            return Center(child: CircularProgressIndicator());
          }

          final List<dynamic>? platillos = result.data?['platillos']['data'];

          if (platillos == null || platillos.isEmpty) {
            return Center(child: Text('No hay platillos disponibles.'));
          }

          return GridView.builder(
            padding: const EdgeInsets.all(10.0),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10.0,
              mainAxisSpacing: 10.0,
              childAspectRatio: 0.85, // Ajusta el tamaño (un poco más corto)
            ),
            itemCount: platillos.length,
            itemBuilder: (context, index) {
              final platillo = platillos[index]['attributes'];

              String? imageUrl;
              try {
                final String imagePath =
                    platillo['foto']['data']['attributes']['url'];
                imageUrl = "$strapiBaseUrl$imagePath";
              } catch (e) {}

              // 3. ¡TARJETA SIMPLIFICADA!
              // Ahora no tiene los botones
              return Card(
                elevation: 4.0,
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --- La Imagen ---
                    Expanded(
                      flex: 3,
                      child: imageUrl != null
                          ? Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              color: Colors.grey[200],
                              child: Icon(Icons.restaurant,
                                  size: 50, color: Colors.grey[400]),
                            ),
                    ),

                    // --- El Nombre y Precio ---
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        platillo['nombre'],
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8.0, 0, 8.0, 8.0),
                      child: Text(
                        '\$${platillo['precio']}',
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),

      // 4. ¡NUEVO BOTTOM NAVIGATION BAR!
      // Aquí están tus dos botones fijos
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Reservar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.image_search), // Icono para "Analizar"
            label: 'Analizar Plato',
          ),
        ],

        // 5. La lógica para saber qué botón se tocó
        onTap: (int index) {
          if (index == 0) {
            // --- Tocado "Reservar" ---
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => TableSelectionScreen()),
            );
          } else if (index == 1) {
            // --- Tocado "Analizar Plato" ---
            // TODO: Aquí irá la lógica de "Analizar Plato" (IA)
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(
                      'Función de IA (Analizar Plato) no implementada aún.')),
            );
          }
        },
      ),
    );
  }
}
