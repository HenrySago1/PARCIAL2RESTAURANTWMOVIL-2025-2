// -----------------------------------------------------------------
// ARCHIVO COMPLETO: lib/table_selection_screen.dart
// (Versión con Date Picker + Lógica "Fake UTC")
// -----------------------------------------------------------------

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart'; // Importamos el formateador de fecha

import 'booking_form_screen.dart';

class TableSelectionScreen extends StatefulWidget {
  @override
  _TableSelectionScreenState createState() => _TableSelectionScreenState();
}

class _TableSelectionScreenState extends State<TableSelectionScreen> {
  // El controlador que guarda la fecha en formato "Fake UTC" (para la API)
  final _fechaApiController = TextEditingController();
  // Este controlador es SÓLO para mostrar la fecha bonita al usuario
  final _fechaDisplayController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  List<dynamic> _mesasDisponibles = [];
  bool _isLoading = false;

  // --- FUNCIÓN DE DATE/TIME PICKER (CORREGIDA) ---
  Future<void> _selectDateTime(BuildContext context) async {
    // Corrección del bug "mar, 11 nov"
    final DateTime today = DateTime.now();
    final DateTime midnightToday = DateTime(today.year, today.month, today.day);

    // 1. Pedir la Fecha (Calendario)
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: midnightToday, // Usa la medianoche de hoy
      firstDate: midnightToday, // La primera fecha seleccionable es hoy
      lastDate: midnightToday.add(Duration(days: 30)),
    );

    if (pickedDate == null) {
      return; // El usuario canceló
    }

    // 2. Pedir la Hora (Reloj)
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (pickedTime == null) {
      return; // El usuario canceló
    }

    // 3. Combinar Fecha y Hora
    final DateTime finalDateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    // 4. Formatear para el USUARIO (ej: "10 de Nov, 08:30 PM")
    final String displayFormat =
        DateFormat('EEE, d MMM, hh:mm a', 'es').format(finalDateTime);
    _fechaDisplayController.text = displayFormat;

    // 5. Formatear para la API (LA SOLUCIÓN "FAKE UTC")
    // "Mentimos" y decimos que la hora local ES la hora UTC
    // para que Strapi la muestre correctamente.
    final DateTime fakeUtcDateTime = DateTime.utc(
      finalDateTime.year,
      finalDateTime.month,
      finalDateTime.day,
      finalDateTime.hour,
      finalDateTime.minute,
    );
    // Esto genera: "2025-11-10T20:00:00.000Z"
    // (La hora local, pero con la Z que el servidor necesita)
    final String apiFormat = fakeUtcDateTime.toIso8601String();
    _fechaApiController.text = apiFormat;
  }
  // --- Fin de la función ---

  // La función de buscar mesas (usa _fechaApiController)
  Future<void> _buscarMesasDisponibles() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _mesasDisponibles = [];
    });

    try {
      final url = Uri.parse(
          'http://10.0.2.2:1337/api/mesas/disponibles?fecha_hora=${_fechaApiController.text}');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _mesasDisponibles = data['data'];
          _isLoading = false;
        });
      } else {
        throw Exception('Error del servidor: ${response.body}');
      }
    } catch (e) {
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
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller:
                        _fechaDisplayController, // Muestra la fecha bonita
                    decoration: InputDecoration(
                      labelText: 'Fecha y Hora',
                      hintText: 'Toca para seleccionar',
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    readOnly: true, // Evita que el usuario escriba
                    onTap: () {
                      _selectDateTime(context);
                    },
                    validator: (value) => value!.isEmpty
                        ? 'Por favor, selecciona una fecha y hora'
                        : null,
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
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : _mesasDisponibles.isEmpty
                      ? Center(child: Text('Toca "Buscar" para ver mesas.'))
                      : ListView.builder(
                          itemCount: _mesasDisponibles.length,
                          itemBuilder: (context, index) {
                            final mesa = _mesasDisponibles[index];
                            final String mesaId = mesa['id'].toString();
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
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => BookingFormScreen(
                                      mesaId: mesaId,
                                      mesaNumero: mesaNumero,
                                      // ¡Enviamos la fecha "Fake UTC" al formulario!
                                      fechaHora: _fechaApiController.text,
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
