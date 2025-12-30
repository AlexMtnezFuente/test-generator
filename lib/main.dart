import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'exam_page.dart';
import 'models.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Test Generator',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _status = 'No JSON loaded';

  Future<void> _loadJsonAndStart() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: <String>['json'],
      withData: true,
    );

    if (result == null) return;

    Uint8List? bytes = result.files.single.bytes;
    if (bytes == null) {
      setState(() => _status = 'Could not read file');
      return;
    }

    String content = utf8.decode(bytes);
    Object decoded = jsonDecode(content);

    if (decoded is! List) {
      setState(() => _status = 'Invalid JSON');
      return;
    }

    List<Question> questions = decoded
        .whereType<Map<String, dynamic>>()
        .map<Question>(Question.fromJson)
        .toList();

    bool valid = questions.isNotEmpty &&
        questions.every((Question q) =>
        q.answers.length >= 2 &&
            q.answers.where((Answer a) => a.correct).length == 1);

    if (!valid) {
      setState(() => _status = 'Invalid questions');
      return;
    }

    List<Question> exam = _generateExam(questions, 10);

    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute<Widget>(
        builder: (_) => ExamPage(exam: exam),
      ),
    );

    setState(() => _status = 'Loaded ${questions.length} questions');
  }

  List<Question> _generateExam(List<Question> questions, int count) {
    List<Question> shuffled = List<Question>.from(questions)..shuffle(Random());
    int n = min(count, shuffled.length);

    return shuffled.take(n).map((Question q) {
      List<Answer> answers = List<Answer>.from(q.answers)..shuffle(Random());
      return q.copyWith(answers: answers);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Test Generator')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ElevatedButton(
              onPressed: _loadJsonAndStart,
              child: const Text('Load JSON and start exam'),
            ),
            const SizedBox(height: 16),
            Text(_status),
          ],
        ),
      ),
    );
  }
}
