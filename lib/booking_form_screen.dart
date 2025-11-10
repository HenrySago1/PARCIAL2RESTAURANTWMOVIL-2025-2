// -----------------------------------------------------------------
// ARCHIVO COMPLETO: lib/booking_form_screen.dart
// (Tu antiguo "reservation_screen.dart" renombrado)
// -----------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

// 1. LA MUTACIÓN (¡ACTUALIZADA!)
// Ahora acepta $mesaId y lo pasa en los datos.
final String createReservaMutation = """
  mutation CreateReserva(
      \$nombre: String!, 
      \$telefono: String!, 
      \$fecha: DateTime!, 
      \$personas: Int!,
      \$mesaId: ID!,
      \$email: String! 
    ) {
    createReserva(
      data: {
        nombre_cliente: \$nombre,
        telefono_cliente: \$telefono,
        fecha_hora: \$fecha,
        cantidad_personas: \$personas,
        mesa: \$mesaId,
        email_cliente: \$email 
      }
    ) {
      data {
        id
      }
    }
  }
""";

// Esta pantalla ahora espera el ID y número de la mesa
class BookingFormScreen extends StatefulWidget {
  final String mesaId;
  final String mesaNumero;

  // El constructor ahora requiere los datos de la mesa
  BookingFormScreen({required this.mesaId, required this.mesaNumero});

  @override
  _BookingFormScreenState createState() => _BookingFormScreenState();
}

class _BookingFormScreenState extends State<BookingFormScreen> {
  final _nombreController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _personasController = TextEditingController();
  final _fechaController = TextEditingController();
  final _emailController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 2. El título ahora muestra la mesa seleccionada
      appBar: AppBar(title: Text('Reservar Mesa: ${widget.mesaNumero}')),
      body: Mutation(
        options: MutationOptions(
          document: gql(createReservaMutation),
          onCompleted: (dynamic resultData) {
            if (resultData != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text('¡Reserva creada con éxito!'),
                    backgroundColor: Colors.green),
              );
              // Regresa dos pantallas atrás (hasta el home)
              Navigator.of(context).popUntil((route) => route.isFirst);
            }
          },
          onError: (OperationException? error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content:
                      Text('Error al crear la reserva: ${error.toString()}'),
                  backgroundColor: Colors.red),
            );
          },
        ),
        builder: (RunMutation runMutation, QueryResult? result) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                // Añadido para evitar overflow del teclado
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nombreController,
                      decoration: InputDecoration(labelText: 'Nombre Completo'),
                      validator: (value) =>
                          value!.isEmpty ? 'Campo requerido' : null,
                    ),
                    TextFormField(
                      controller: _telefonoController,
                      decoration: InputDecoration(labelText: 'Teléfono'),
                      keyboardType: TextInputType.phone,
                      validator: (value) =>
                          value!.isEmpty ? 'Campo requerido' : null,
                    ),
                    TextFormField(
                      // <-- AÑADE ESTE WIDGET
                      controller: _emailController,
                      decoration:
                          InputDecoration(labelText: 'Correo Electrónico'),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) =>
                          value!.isEmpty ? 'Campo requerido' : null,
                    ),
                    TextFormField(
                      controller: _personasController,
                      decoration:
                          InputDecoration(labelText: 'Cantidad de Personas'),
                      keyboardType: TextInputType.number,
                      validator: (value) =>
                          value!.isEmpty ? 'Campo requerido' : null,
                    ),
                    TextFormField(
                      controller: _fechaController,
                      decoration: InputDecoration(
                          labelText: 'Fecha y Hora (AAAA-MM-DDTHH:MM:SSZ)'),
                      validator: (value) =>
                          value!.isEmpty ? 'Campo requerido' : null,
                      // Ej: 2025-11-10T20:00:00Z
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      child: Text('Confirmar Reserva'),
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          // 3. ¡ACTUALIZADO!
                          // Ahora pasamos también el widget.mesaId
                          runMutation({
                            'nombre': _nombreController.text,
                            'telefono': _telefonoController.text,
                            'fecha': _fechaController.text,
                            'personas': int.parse(_personasController.text),
                            'mesaId': widget.mesaId,
                            'email': _emailController.text,
                          });
                        }
                      },
                    )
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
