import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:intl/date_symbol_data_local.dart'; // <-- AÑADE ESTA LÍNEA
import 'package:restaurantesw2/HomeScreen.dart';

// --- ¡IMPORTANTE! Cambia esta URL según tu caso ---
// Para emulador Android:
final HttpLink httpLink = HttpLink('http://10.0.2.2:1337/graphql');
// Para simulador iOS o web:
// final HttpLink httpLink = HttpLink('http://localhost:1337/graphql');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_ES', null);
  // Inicializamos los HiveStore para el caché
  await initHiveForFlutter();

  final ValueNotifier<GraphQLClient> client = ValueNotifier(
    GraphQLClient(
      link: httpLink,
      // El caché es bueno para el rendimiento
      cache: GraphQLCache(store: HiveStore()),
    ),
  );

  runApp(
    // Envolvemos la app en el Provider
    GraphQLProvider(
      client: client,
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Restaurante App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: HomeScreen(), // Tu pantalla principal

      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [
        const Locale('es', ''), // Español
        const Locale('en', ''), // Inglés (opcional)
      ],
      locale: const Locale('es'), // Forzar español
    );
  }
}
