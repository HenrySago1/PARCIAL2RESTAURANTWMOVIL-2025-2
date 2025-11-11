// Archivo: lib/analysis_result_screen.dart

import 'package:flutter/material.dart';

class AnalysisResultScreen extends StatelessWidget {
  // Recibimos el mapa de resultados de la API
  final Map<String, dynamic> resultados;

  const AnalysisResultScreen({Key? key, required this.resultados})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Extraemos los datos del JSON
    final String platoDetectado = resultados['plato_detectado'] ?? 'N/A';
    final List<dynamic> ingredientes = resultados['ingredientes'] ?? [];
    final List<dynamic> alergias = resultados['alergias'] ?? [];
    final List<dynamic> nombresAlternativos =
        resultados['nombres_alternativos'] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text('Resultados del Análisis'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Text(
              platoDetectado,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            if (nombresAlternativos.isNotEmpty)
              Text(
                'También conocido como: ${nombresAlternativos.join(', ')}',
                style: TextStyle(
                    fontStyle: FontStyle.italic, color: Colors.grey[700]),
              ),

            SizedBox(height: 24),

            // --- Sección de Ingredientes ---
            Text(
              'Ingredientes Principales:',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 8),
            ...ingredientes.map((ingrediente) => ListTile(
                  leading:
                      Icon(Icons.check_circle_outline, color: Colors.green),
                  title: Text(ingrediente),
                )),

            SizedBox(height: 24),

            // --- Sección de Alergias ---
            Text(
              'Posibles Alergias:',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 8),
            if (alergias.isEmpty)
              ListTile(
                leading: Icon(Icons.check_circle, color: Colors.green),
                title: Text('Ninguna detectada'),
              )
            else
              ...alergias.map((alergia) => ListTile(
                    leading:
                        Icon(Icons.warning_amber_rounded, color: Colors.red),
                    title: Text(alergia),
                  )),
          ],
        ),
      ),
    );
  }
}
