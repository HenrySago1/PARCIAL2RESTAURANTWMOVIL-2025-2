// -----------------------------------------------------------------
// ARCHIVO COMPLETO: lib/booking_form_screen.dart
// (Versión que LEE la hora UTC y la muestra LOCAL)
// -----------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:intl/intl.dart';

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

class BookingFormScreen extends StatefulWidget {
  final String mesaId;
  final String mesaNumero;
  final String fechaHora; // <-- Recibe la fecha UTC (ej: ...Z)

  BookingFormScreen({
    required this.mesaId,
    required this.mesaNumero,
    required this.fechaHora,
  });

  @override
  _BookingFormScreenState createState() => _BookingFormScreenState();
}

class _BookingFormScreenState extends State<BookingFormScreen> {
  final _nombreController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _personasController = TextEditingController();
  final _emailController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  String _fechaHoraParaMostrar = '';

  @override
  void initState() {
    super.initState();
    // --- LÓGICA DE HORA CORREGIDA ---
    try {
      // 1. Leemos la fecha UTC (ej: ...T23:00:00Z)
      final dateTime = DateTime.parse(widget.fechaHora);

      // 2. La convertimos de vuelta a "local" (ej: 7:00 PM)
      final localDateTime = dateTime.toLocal();

      // 3. La mostramos en español
      _fechaHoraParaMostrar =
          DateFormat('EEE, d MMMM, hh:mm a', 'es').format(localDateTime);
    } catch (e) {
      _fechaHoraParaMostrar = 'Fecha inválida';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Confirmar Reserva para:',
                        style: Theme.of(context).textTheme.titleMedium),
                    Text(
                      _fechaHoraParaMostrar, // Muestra la hora local (ej: 7:00 PM)
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 20),
                    TextFormField(
                      controller: _nombreController,
                      decoration: InputDecoration(labelText: 'Nombre Completo'),
                      validator: (value) =>
                          value!.isEmpty ? 'Campo requerido' : null,
                    ),
                    TextFormField(
                      controller: _emailController,
                      decoration:
                          InputDecoration(labelText: 'Correo Electrónico'),
                      keyboardType: TextInputType.emailAddress,
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
                      controller: _personasController,
                      decoration:
                          InputDecoration(labelText: 'Cantidad de Personas'),
                      keyboardType: TextInputType.number,
                      validator: (value) =>
                          value!.isEmpty ? 'Campo requerido' : null,
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      child: Text('Confirmar Reserva'),
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          runMutation({
                            'nombre': _nombreController.text,
                            'telefono': _telefonoController.text,
                            'fecha': widget.fechaHora, // <-- ¡Usa la fecha UTC!
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
