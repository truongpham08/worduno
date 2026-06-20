import 'package:flutter/material.dart';

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
      appBar: AppBar(title: const Text('Create Exam')),
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
      body: Center(child: Text('ExamSessionPage stub')),
    );
  }
}

class ExamResultPage extends StatelessWidget {
  const ExamResultPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('ExamResultPage stub')),
    );
  }
}

class ExamHistoryPage extends StatelessWidget {
  const ExamHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Exam History')),
      body: const Center(child: Text('ExamHistoryPage stub')),
    );
  }
}

class ExamDetailPage extends StatelessWidget {
  const ExamDetailPage({super.key, required this.examId});

  final String examId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Exam Detail')),
      body: Center(child: Text('ExamDetailPage stub • id=$examId')),
    );
  }
}
