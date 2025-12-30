// lib/main.dart

// -----------------------------
// IMPORTS
// -----------------------------

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import 'exam_page.dart';
import 'models.dart';

// -----------------------------
// ENTRY POINT
// -----------------------------

void main() {
  runApp(const MyApp());
}

// -----------------------------
// ROOT WIDGET
// -----------------------------

// -----------------------------
// ROOT WIDGET CON TEMA DINÁMICO
// -----------------------------

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // Modo de tema actual de la app
  ThemeMode _themeMode = ThemeMode.system;

  // Cambia el modo de tema
  void _setThemeMode(ThemeMode mode) {
    setState(() {
      _themeMode = mode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Test Generator',
      debugShowCheckedModeBanner: false,

      // Tema claro
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        brightness: Brightness.light,
      ),

      // Tema oscuro
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        brightness: Brightness.dark,
      ),

      // Modo activo (claro / oscuro / sistema)
      themeMode: _themeMode,

      // Pasamos el callback a la HomePage
      home: HomePage(
        onThemeChanged: _setThemeMode,
        currentThemeMode: _themeMode,
      ),
    );
  }
}


// -----------------------------
// HOME PAGE
// -----------------------------

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.onThemeChanged,
    required this.currentThemeMode,
  });

  final void Function(ThemeMode) onThemeChanged;
  final ThemeMode currentThemeMode;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _status = 'No hay ningún JSON cargado';
  bool _loading = false;

  List<Question> _questionBank = <Question>[];

  Future<void> _loadJson() async {
    if (_loading) return;

    setState(() {
      _loading = true;
      _status = 'Seleccionando archivo...';
    });

    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: <String>['json'],
      withData: true,
    );

    if (result == null) {
      setState(() {
        _loading = false;
        _status = 'Operación cancelada';
      });
      return;
    }

    Uint8List? bytes = result.files.single.bytes;

    if (bytes == null) {
      setState(() {
        _loading = false;
        _status = 'No se pudo leer el archivo';
      });
      return;
    }

    try {
      String content = utf8.decode(bytes);
      Object decoded = jsonDecode(content);

      if (decoded is! List) {
        setState(() {
          _loading = false;
          _status = 'JSON inválido: se esperaba una lista';
        });
        return;
      }

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

      setState(() {
        _questionBank = questions;
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

  void _startFixedExam() {
    if (_questionBank.isEmpty) return;

    List<Question> exam = _generateExam(
      questions: _questionBank,
      count: 10,
    );

    Navigator.of(context).push(
      MaterialPageRoute<Widget>(
        builder: (_) => ExamPage(exam: exam),
      ),
    );
  }

  void _startInfiniteExam() {
    if (_questionBank.isEmpty) return;

    Navigator.of(context).push(
      MaterialPageRoute<Widget>(
        builder: (_) => ExamPage(
          exam: _generateInfiniteExamSeed(_questionBank),
          infiniteMode: true,
          questionBank: _questionBank,
        ),
      ),
    );
  }

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

  List<Question> _generateInfiniteExamSeed(List<Question> questions) {
    List<Question> shuffled = List<Question>.from(questions);
    shuffled.shuffle(Random());

    return shuffled.take(min(10, shuffled.length)).map((Question q) {
      List<Answer> answers = List<Answer>.from(q.answers);
      answers.shuffle(Random());
      return q.copyWith(answers: answers);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    bool hasQuestions = _questionBank.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Generator'),
        actions: <Widget>[
          PopupMenuButton<ThemeMode>(
            icon: const Icon(Icons.brightness_6),
            onSelected: widget.onThemeChanged,
            itemBuilder: (BuildContext context) => <PopupMenuEntry<ThemeMode>>[
              CheckedPopupMenuItem(
                value: ThemeMode.system,
                checked: widget.currentThemeMode == ThemeMode.system,
                child: const Text('Sistema'),
              ),
              CheckedPopupMenuItem(
                value: ThemeMode.light,
                checked: widget.currentThemeMode == ThemeMode.light,
                child: const Text('Claro'),
              ),
              CheckedPopupMenuItem(
                value: ThemeMode.dark,
                checked: widget.currentThemeMode == ThemeMode.dark,
                child: const Text('Oscuro'),
              ),
            ],
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ElevatedButton.icon(
                onPressed: _loading ? null : _loadJson,
                icon: const Icon(Icons.upload_file),
                label: const Text('Cargar JSON'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: hasQuestions ? _startFixedExam : null,
                child: const Text('Empezar examen (10 preguntas)'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: hasQuestions ? _startInfiniteExam : null,
                child: const Text('Empezar examen infinito'),
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
