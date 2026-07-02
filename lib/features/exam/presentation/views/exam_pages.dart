import 'package:flutter/material.dart';

import '../../../../core/widgets/app_navigation_widgets.dart';

class ExamConfigPage extends StatelessWidget {
  const ExamConfigPage({
    super.key,
    this.levelCode,
    this.unitName,
  });

  final String? levelCode;
  final String? unitName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const WordunoAppBar(title: 'Create Exam'),
      body: Center(
        child: Text(
          'ExamConfigPage stub'
          '${levelCode == null ? '' : ' • level=$levelCode'}'
          '${unitName == null ? '' : ' • unit=$unitName'}',
        ),
      ),
    );
  }
}

class ExamSessionPage extends StatelessWidget {
  const ExamSessionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: WordunoAppBar(title: 'Exam'),
      body: Center(child: Text('ExamSessionPage stub')),
    );
  }
}

class ExamResultPage extends StatelessWidget {
  const ExamResultPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: WordunoAppBar(title: 'Exam Result'),
      body: Center(child: Text('ExamResultPage stub')),
    );
  }
}

class ExamHistoryPage extends StatelessWidget {
  const ExamHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: WordunoAppBar(title: 'Exam History', showBack: false),
      body: Center(child: Text('ExamHistoryPage stub')),
    );
  }
}

class ExamDetailPage extends StatelessWidget {
  const ExamDetailPage({super.key, required this.examId});

  final String examId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const WordunoAppBar(title: 'Exam Detail'),
      body: Center(child: Text('ExamDetailPage stub • id=$examId')),
    );
  }
}
