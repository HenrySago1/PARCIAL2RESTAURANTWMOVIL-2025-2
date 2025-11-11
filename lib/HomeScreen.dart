// -----------------------------------------------------------------
// ARCHIVO COMPLETO: lib/home_screen.dart
// (Versión con "Analizar" en la tarjeta y "Reservar" flotante)
// -----------------------------------------------------------------

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:http/http.dart' as http;
// Importaciones para la IA
import 'package:image_picker/image_picker.dart';

import 'analysis_result_screen.dart';
import 'table_selection_screen.dart'; // Para el botón de reservar

// La consulta (pide foto y nombre)
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
  // 1. La función de ANÁLISIS (sigue igual)
  Future<void> _analizarPlato(BuildContext context, String nombrePlato) async {
    final ImagePicker picker = ImagePicker();
    XFile? foto;

    // 1. Mostrar diálogo para elegir Cámara o Galería
    await showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                  leading: Icon(Icons.photo_library),
                  title: Text('Elegir de la Galería'),
                  onTap: () async {
                    foto = await picker.pickImage(source: ImageSource.gallery);
                    Navigator.of(context).pop();
                  }),
              ListTile(
                leading: Icon(Icons.photo_camera),
                title: Text('Tomar Foto'),
                onTap: () async {
                  foto = await picker.pickImage(source: ImageSource.camera);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );

    if (foto != null) {
      // 2. Mostrar un diálogo de "cargando"
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Dialog(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 20),
                  Text("Analizando plato..."),
                ],
              ),
            ),
          );
        },
      );

      // 3. Crear la URL
      var uri = Uri.parse('http://10.0.2.2:8000/analizar-plato');

      // 4. Crear la petición
      var request = http.MultipartRequest('POST', uri)
        ..files.add(await http.MultipartFile.fromPath(
          'foto',
          foto!.path,
          filename: foto!.name,
        ))
        ..fields['nombre_plato'] = nombrePlato;

      // 5. Enviar la petición
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      // 6. Cerrar el diálogo de "cargando"
      Navigator.pop(context); // Cierra el diálogo

      if (response.statusCode == 200) {
        // ¡Éxito!
        final Map<String, dynamic> resultados = json.decode(response.body);

        // 7. Navegar a la pantalla de resultados
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AnalysisResultScreen(resultados: resultados),
          ),
        );
      } else {
        // Error del servidor de IA
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error del servidor de IA: ${response.body}')),
        );
      }
    }
  }

  // --- EL WIDGET BUILD ---
  @override
  Widget build(BuildContext context) {
    final String strapiBaseUrl = "http://10.0.2.2:1337";

    return Scaffold(
      appBar: AppBar(title: Text('Menú del Restaurante')),

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
              childAspectRatio: 0.75, // Un poco más alto para el botón
            ),
            itemCount: platillos.length,
            itemBuilder: (context, index) {
              final platillo = platillos[index]['attributes'];
              final String nombrePlato = platillo['nombre'];

              String? imageUrl;
              try {
                final String imagePath =
                    platillo['foto']['data']['attributes']['url'];
                imageUrl = "$strapiBaseUrl$imagePath";
              } catch (e) {}

              // 2. ¡TARJETA CON UN SOLO BOTÓN!
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
                      padding: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 4.0),
                      child: Text(
                        nombrePlato,
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

                    // 3. ¡BOTÓN "ANALIZAR" DENTRO DE LA TARJETA!
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: TextButton(
                        child: Text('Analizar Plato'),
                        onPressed: () {
                          _analizarPlato(context, nombrePlato);
                        },
                      ),
                    )
                  ],
                ),
              );
            },
          );
        },
      ),

      // 4. ¡BOTÓN "RESERVAR" FLOTANTE Y GLOBAL!
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => TableSelectionScreen()),
          );
        },
        icon: Icon(Icons.calendar_today),
        label: Text('Reservar'),
      ),
    );
  }
}
