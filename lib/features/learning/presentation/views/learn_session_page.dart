import 'package:flutter/material.dart';

class LearnSessionPage extends StatelessWidget {
  const LearnSessionPage({
    super.key,
    required this.levelCode,
    required this.unitName,
  });

  final String levelCode;
  final String unitName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Learn')),
      body: Center(
        child: Text('LearnSessionPage stub • $levelCode / $unitName'),
      ),
    );
  }
}
