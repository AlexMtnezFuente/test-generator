import 'package:flutter/material.dart';
import 'models.dart';

class ExamPage extends StatefulWidget {
  const ExamPage({super.key, required this.exam});

  final List<Question> exam;

  @override
  State<ExamPage> createState() => _ExamPageState();
}

class _ExamPageState extends State<ExamPage> {
  int _index = 0;
  int _score = 0;
  bool _answered = false;
  int? _selected;

  void _answer(int i) {
    if (_answered) return;

    Answer a = widget.exam[_index].answers[i];

    setState(() {
      _answered = true;
      _selected = i;
      if (a.correct) _score++;
    });

    Future<void>.delayed(const Duration(seconds: 1), _next);
  }

  void _next() {
    if (!mounted) return;

    setState(() {
      _answered = false;
      _selected = null;
      _index++;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_index >= widget.exam.length) {
      return Scaffold(
        appBar: AppBar(title: const Text('Finished')),
        body: Center(
          child: Text(
            'Score: $_score / ${widget.exam.length}',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ),
      );
    }

    Question q = widget.exam[_index];

    return Scaffold(
      appBar: AppBar(
        title: Text('Question ${_index + 1}/${widget.exam.length}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              q.question,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                itemCount: q.answers.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (BuildContext context, int i) {
                  Answer a = q.answers[i];

                  Color? bg;
                  if (_answered) {
                    if (a.correct) bg = Colors.green.withOpacity(0.2);
                    if (_selected == i && !a.correct) {
                      bg = Colors.red.withOpacity(0.2);
                    }
                  }

                  return InkWell(
                    onTap: () => _answer(i),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.black12),
                      ),
                      child: Text(a.text),
                    ),
                  );
                },
              ),
            ),
            if (_answered) ...<Widget>[
              const SizedBox(height: 12),
              Text(q.explanation),
            ],
          ],
        ),
      ),
    );
  }
}
