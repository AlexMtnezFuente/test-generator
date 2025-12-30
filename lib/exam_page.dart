// lib/exam_page.dart

import 'dart:math';

import 'package:flutter/material.dart';
import 'models.dart';

class ExamPage extends StatefulWidget {
  const ExamPage({
    super.key,
    required this.exam,
    this.infiniteMode = false,
    this.questionBank = const <Question>[],
  });

  final List<Question> exam;
  final bool infiniteMode;
  final List<Question> questionBank;

  @override
  State<ExamPage> createState() => _ExamPageState();
}

class _ExamPageState extends State<ExamPage> {
  int _currentIndex = 0;
  int _score = 0;

  final Set<int> _selected = <int>{};

  bool _isCorrect = false;
  bool _hasChecked = false;

  // Indica si esta pregunta ya se falló al menos una vez en este intento.
  // Sirve para mostrar la explicación SOLO cuando luego la aciertas.
  bool _failedBefore = false;

  final Random _random = Random();

  late final List<Question> _exam = List<Question>.from(widget.exam);

  Question get _question => _exam[_currentIndex];

  void _toggle(int index) {
    // Si ya acertaste, bloqueamos la interacción con las opciones
    if (_isCorrect) return;

    setState(() {
      if (_selected.contains(index)) {
        _selected.remove(index);
      } else {
        _selected.add(index);
      }

      // Si cambias la selección, invalidas la comprobación previa
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
        _isCorrect = true; // Bloquea opciones y habilita "Siguiente"
      });

      // La explicación se muestra SOLO si antes fallaste esta pregunta
      if (_failedBefore) await _showExplanationDialog(_question.explanation);

      return;
    }

    // Si fallas: reseteamos selección + reordenamos respuestas, pero NO mostramos popup
    setState(() {
      _failedBefore = true;

      _selected.clear();
      _hasChecked = false;
      _isCorrect = false;

      _question.answers.shuffle(_random);
    });
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
      _failedBefore = false;

      if (widget.infiniteMode) _ensureMoreQuestions();
    });
  }

  void _ensureMoreQuestions() {
    if (widget.questionBank.isEmpty) return;

    if (_currentIndex < _exam.length) return;

    int extra = min(10, widget.questionBank.length);

    for (int i = 0; i < extra; i++) {
      Question base = widget.questionBank[_random.nextInt(widget.questionBank.length)];
      List<Answer> answers = List<Answer>.from(base.answers)..shuffle(_random);

      _exam.add(
        base.copyWith(answers: answers),
      );
    }
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
    if (!widget.infiniteMode && _currentIndex >= _exam.length) {
      return Scaffold(
        appBar: AppBar(title: const Text('Examen finalizado')),
        body: Center(
          child: Text(
            'Resultado: $_score / ${_exam.length}',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ),
      );
    }

    if (widget.infiniteMode && _currentIndex >= _exam.length) {
      _ensureMoreQuestions();
    }

    Question q = _question;
    Set<int> correct = q.correctIndexes();

    int totalRows = q.answers.length + 1;

    // "Comprobar" solo si hay selección y aún no has acertado
    bool canCheck = _selected.isNotEmpty && !_isCorrect;

    // "Siguiente" solo si has comprobado y acertado
    bool canNext = _hasChecked && _isCorrect;

    // "Ver explicación" solo si has acertado
    bool canSeeExplanation = _isCorrect;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.infiniteMode
              ? 'Modo infinito · Aciertos: $_score'
              : 'Pregunta ${_currentIndex + 1} / ${_exam.length}',
        ),
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
                  // Última fila: botones, pegados a las opciones
                  if (i == q.answers.length) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Row(
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
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton(
                          onPressed: canSeeExplanation ? () => _showExplanationDialog(q.explanation) : null,
                          child: const Text('Ver explicación'),
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
                    onTap: _isCorrect ? null : () => _toggle(i),
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
                            onChanged: _isCorrect ? null : (_) => _toggle(i),
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
          ],
        ),
      ),
    );
  }
}
