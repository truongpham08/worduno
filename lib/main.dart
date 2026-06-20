import 'package:flutter/material.dart';

import 'app/app.dart';
import 'app/di/injection.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupDependencies();
  runApp(const WordunoApp());
}
