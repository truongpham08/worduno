import 'package:flutter/material.dart';

class CoachConfigPage extends StatelessWidget {
  const CoachConfigPage({
    super.key,
    this.levelCode,
    this.unitName,
  });

  final String? levelCode;
  final String? unitName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Coach')),
      body: Center(
        child: Text(
          'CoachConfigPage stub'
          '${levelCode == null ? '' : ' • level=$levelCode'}'
          '${unitName == null ? '' : ' • unit=$unitName'}',
        ),
      ),
    );
  }
}

class CoachSessionPage extends StatelessWidget {
  const CoachSessionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('CoachSessionPage stub')),
    );
  }
}

class CoachHistoryPage extends StatelessWidget {
  const CoachHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Coach History')),
      body: const Center(child: Text('CoachHistoryPage stub')),
    );
  }
}

class CoachDetailPage extends StatelessWidget {
  const CoachDetailPage({super.key, required this.coachId});

  final String coachId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Coach Detail')),
      body: Center(child: Text('CoachDetailPage stub • id=$coachId')),
    );
  }
}
