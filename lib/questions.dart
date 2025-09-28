import 'package:flutter/material.dart';

class QuestionsScreen extends StatelessWidget {
  const QuestionsScreen({Key? key}) : super(key: key);

  static final List<Map<String, dynamic>> _mockQuestions = List.generate(15, (
    i,
  ) {
    return {
      'id': i + 1,
      'title': 'How to implement feature ${i + 1} in Flutter?',
      'excerpt':
          'I am trying to implement feature ${i + 1} and facing issues with state management...',
      'votes': (i * 3) % 10,
      'answers': i % 3,
      'tags': ['flutter', 'dart', 'state-management'],
      'link': 'https://stackoverflow.com/questions/${i + 1}',
    };
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Questions'),
        backgroundColor: const Color(0xFF667eea),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 12),
        itemCount: _mockQuestions.length,
        itemBuilder: (context, index) {
          final q = _mockQuestions[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Column(
                        children: [
                          Text(
                            '${q['votes']}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const Text(
                            'votes',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              q['title'],
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(q['excerpt']),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              children: List<Widget>.from(
                                q['tags'].map((t) => Chip(label: Text(t))),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        children: [
                          Text(
                            '${q['answers']}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const Text(
                            'answers',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
