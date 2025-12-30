// -----------------------------
// IMPORTS
// -----------------------------

// Librerías estándar de Dart
import 'dart:convert'; // Para convertir texto JSON a objetos Dart
import 'dart:math'; // Para Random y min
import 'dart:typed_data'; // Para manejar bytes (Uint8List)

// Flutter (UI y widgets)
import 'package:flutter/material.dart';

// Plugin para seleccionar archivos del dispositivo
import 'package:file_picker/file_picker.dart';

// Archivos propios del proyecto
import 'exam_page.dart';
import 'models.dart';

// -----------------------------
// ENTRY POINT
// -----------------------------

void main() {
  // Punto de entrada de la app.
  // Flutter empieza a dibujar la UI desde aquí.
  runApp(const MyApp());
}

// -----------------------------
// ROOT WIDGET
// -----------------------------

/// Widget raíz de la aplicación.
/// No tiene estado porque solo define configuración global.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Título interno de la app
      title: 'Test Generator',

      // Quitamos el banner DEBUG
      debugShowCheckedModeBanner: false,

      // Tema global
      theme: ThemeData(
        // Genera una paleta de colores coherente
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),

      // Pantalla inicial
      home: const HomePage(),
    );
  }
}

// -----------------------------
// HOME PAGE
// -----------------------------

/// Pantalla principal.
/// Permite cargar un JSON y empezar el examen.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

/// Estado de la pantalla principal.
class _HomePageState extends State<HomePage> {
  // Texto de estado que se muestra debajo del botón
  String _status = 'No hay ningún JSON cargado';

  // Evita que el usuario pulse el botón varias veces
  bool _loading = false;

  /// Abre el selector de archivos, carga el JSON,
  /// genera el examen y navega a la pantalla de preguntas.
  Future<void> _loadJsonAndStart() async {
    if (_loading) return;

    setState(() {
      _loading = true;
      _status = 'Seleccionando archivo...';
    });

    // Abrimos el selector de archivos
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: <String>['json'],
      withData: true,
    );

    // Usuario canceló
    if (result == null) {
      setState(() {
        _loading = false;
        _status = 'Operación cancelada';
      });
      return;
    }

    // Leemos los bytes del archivo
    Uint8List? bytes = result.files.single.bytes;

    if (bytes == null) {
      setState(() {
        _loading = false;
        _status = 'No se pudo leer el archivo';
      });
      return;
    }

    try {
      // Convertimos bytes a texto
      String content = utf8.decode(bytes);

      // Convertimos texto JSON a objeto Dart
      Object decoded = jsonDecode(content);

      // El JSON debe ser una lista de preguntas
      if (decoded is! List) {
        setState(() {
          _loading = false;
          _status = 'JSON inválido: se esperaba una lista';
        });
        return;
      }

      // Convertimos cada elemento en un objeto Question
      List<Question> questions = decoded
          .whereType<Map<String, dynamic>>()
          .map<Question>(Question.fromJson)
          .where((Question q) => q.isValidForExam)
          .toList();

      if (questions.isEmpty) {
        setState(() {
          _loading = false;
          _status = 'No hay preguntas válidas en el JSON';
        });
        return;
      }

      // Generamos el examen
      List<Question> exam = _generateExam(
        questions: questions,
        count: 10,
      );

      // Navegamos a la pantalla del examen
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute<Widget>(
          builder: (_) => ExamPage(exam: exam),
        ),
      );

      setState(() {
        _loading = false;
        _status = 'Cargadas ${questions.length} preguntas';
      });
    } catch (_) {
      setState(() {
        _loading = false;
        _status = 'Error al procesar el JSON';
      });
    }
  }

  /// Genera un examen aleatorio:
  /// - Desordena preguntas
  /// - Limita el número
  /// - Desordena respuestas de cada pregunta
  List<Question> _generateExam({
    required List<Question> questions,
    required int count,
  }) {
    List<Question> shuffled = List<Question>.from(questions);
    shuffled.shuffle(Random());

    int total = min(count, shuffled.length);

    return shuffled.take(total).map((Question q) {
      List<Answer> answers = List<Answer>.from(q.answers);
      answers.shuffle(Random());
      return q.copyWith(answers: answers);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Test Generator')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ElevatedButton.icon(
                onPressed: _loading ? null : _loadJsonAndStart,
                icon: const Icon(Icons.upload_file),
                label: const Text('Cargar JSON y empezar examen'),
              ),
              const SizedBox(height: 16),
              Text(_status),
            ],
          ),
        ),
      ),
    );
  }
}
