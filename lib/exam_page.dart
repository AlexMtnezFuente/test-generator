// lib/exam_page.dart

import 'dart:math';

import 'package:flutter/material.dart';
import 'models.dart';

class ExamPage extends StatefulWidget {
  const ExamPage({super.key, required this.exam});

  final List<Question> exam;

  @override
  State<ExamPage> createState() => _ExamPageState();
}

class _ExamPageState extends State<ExamPage> {
  int _currentIndex = 0;
  int _score = 0;

  final Set<int> _selected = <int>{};

  bool _isCorrect = false;
  bool _hasChecked = false;

  final Random _random = Random();

  Question get _question => widget.exam[_currentIndex];

  void _toggle(int index) {
    setState(() {
      if (_selected.contains(index)) {
        _selected.remove(index);
      } else {
        _selected.add(index);
      }

      _hasChecked = false;
      _isCorrect = false;
    });
  }

  Future<void> _check() async {
    if (_selected.isEmpty) return;

    Set<int> correct = _question.correctIndexes();
    bool ok = _setsEqual(_selected, correct);

    if (ok) {
      setState(() {
        _hasChecked = true;
        _isCorrect = true;
      });
      return;
    }

    setState(() {
      _selected.clear();
      _hasChecked = false;
      _isCorrect = false;

      _question.answers.shuffle(_random);
    });

    await _showExplanationDialog(_question.explanation);
  }

  Future<void> _showExplanationDialog(String explanation) async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Explicación'),
          content: SingleChildScrollView(
            child: Text(explanation),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  void _next() {
    setState(() {
      _score++;
      _currentIndex++;
      _selected.clear();
      _hasChecked = false;
      _isCorrect = false;
    });
  }

  bool _setsEqual(Set<int> a, Set<int> b) {
    if (a.length != b.length) return false;
    for (int v in a) {
      if (!b.contains(v)) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    if (_currentIndex >= widget.exam.length) {
      return Scaffold(
        appBar: AppBar(title: const Text('Examen finalizado')),
        body: Center(
          child: Text(
            'Resultado: $_score / ${widget.exam.length}',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ),
      );
    }

    Question q = _question;
    Set<int> correct = q.correctIndexes();

    int totalRows = q.answers.length + 1;

    bool canCheck = _selected.isNotEmpty;
    bool canNext = _hasChecked && _isCorrect;

    return Scaffold(
      appBar: AppBar(
        title: Text('Pregunta ${_currentIndex + 1} / ${widget.exam.length}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(q.question, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                itemCount: totalRows,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (BuildContext context, int i) {
                  if (i == q.answers.length) {
                    return Row(
                      children: <Widget>[
                        Expanded(
                          child: ElevatedButton(
                            onPressed: canCheck ? _check : null,
                            child: const Text('Comprobar'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: canNext ? _next : null,
                            child: const Text('Siguiente'),
                          ),
                        ),
                      ],
                    );
                  }

                  Answer a = q.answers[i];
                  bool selected = _selected.contains(i);

                  Color? bg;
                  if (_hasChecked) {
                    if (correct.contains(i)) bg = Colors.green.withOpacity(0.2);
                    if (selected && !correct.contains(i)) bg = Colors.red.withOpacity(0.2);
                  }

                  return InkWell(
                    onTap: () => _toggle(i),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.black12),
                      ),
                      child: Row(
                        children: <Widget>[
                          Checkbox(
                            value: selected,
                            onChanged: (_) => _toggle(i),
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Text(a.text)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            if (_hasChecked && !_isCorrect)
              Text(
                'Incorrecto. Ajusta tu selección y vuelve a comprobar.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            if (_hasChecked && _isCorrect)
              Text(
                'Correcto. Ya puedes pasar a la siguiente.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
          ],
        ),
      ),
    );
  }
}
