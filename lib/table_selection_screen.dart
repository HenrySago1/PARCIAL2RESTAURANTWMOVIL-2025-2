// -----------------------------------------------------------------
// ARCHIVO COMPLETO: lib/table_selection_screen.dart
// (Versión con lógica de disponibilidad)
// -----------------------------------------------------------------

import 'dart:convert'; // Para decodificar el JSON

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // <-- CORRECTO

import 'booking_form_screen.dart'; // Importamos la pantalla del formulario
// ¡YA NO USAMOS GRAPHQL AQUÍ!

// 1. Convertimos la pantalla a un StatefulWidget
class TableSelectionScreen extends StatefulWidget {
  @override
  _TableSelectionScreenState createState() => _TableSelectionScreenState();
}

class _TableSelectionScreenState extends State<TableSelectionScreen> {
  final _fechaController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // 2. Una variable para guardar la lista de mesas disponibles
  List<dynamic> _mesasDisponibles = [];
  bool _isLoading = false;

  // 3. La función que llama a tu nueva API de Strapi
  Future<void> _buscarMesasDisponibles() async {
    if (!_formKey.currentState!.validate()) {
      return; // Si el formulario no es válido, no hagas nada
    }

    setState(() {
      _isLoading = true; // Mostrar spinner
      _mesasDisponibles = []; // Limpiar resultados anteriores
    });

    try {
      // ¡Recuerda! 10.0.2.2 para emulador Android
      final url = Uri.parse(
          'http://10.0.2.2:1337/api/mesas/disponibles?fecha_hora=${_fechaController.text}');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        // Éxito
        final data = json.decode(response.body);
        setState(() {
          _mesasDisponibles = data['data']; // Guardamos la lista de mesas
          _isLoading = false;
        });
      } else {
        // Error del servidor
        throw Exception('Error del servidor: ${response.body}');
      }
    } catch (e) {
      // Error de red o al parsear
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error al buscar mesas: ${e.toString()}'),
            backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Buscar Mesas Disponibles')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 4. El formulario para pedir la fecha
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _fechaController,
                    decoration: InputDecoration(
                      labelText: 'Fecha y Hora (AAAA-MM-DDTHH:MM:SSZ)',
                      hintText: '2025-11-10T22:00:00Z',
                    ),
                    validator: (value) =>
                        value!.isEmpty ? 'Ingresa una fecha' : null,
                  ),
                  SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _buscarMesasDisponibles,
                    child: Text('Buscar Disponibilidad'),
                  ),
                ],
              ),
            ),

            SizedBox(height: 20),

            // 5. El área de resultados
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : _mesasDisponibles.isEmpty
                      ? Center(
                          child:
                              Text('No hay mesas disponibles para esta hora.'))
                      : ListView.builder(
                          itemCount: _mesasDisponibles.length,
                          itemBuilder: (context, index) {
                            final mesa = _mesasDisponibles[index];
                            final String mesaId =
                                mesa['id'].toString(); // ¡Ojo! ID es int
                            final String mesaNumero =
                                mesa['attributes']['numero'];
                            final int mesaCapacidad =
                                mesa['attributes']['capacidad'];

                            return ListTile(
                              leading: Icon(Icons.table_restaurant),
                              title: Text('Mesa: $mesaNumero'),
                              subtitle:
                                  Text('Capacidad: $mesaCapacidad personas'),
                              trailing: Icon(Icons.chevron_right),
                              onTap: () {
                                // Navegamos al formulario final
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => BookingFormScreen(
                                      mesaId: mesaId,
                                      mesaNumero: mesaNumero,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
