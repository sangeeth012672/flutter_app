// lib/main.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:smart_task_manager/app/app.dart';
import 'package:smart_task_manager/core/constants/app_constants.dart';
import 'package:smart_task_manager/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Firebase ──────────────────────────────────────────
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ── Hive (Offline Cache) ──────────────────────────────
  await Hive.initFlutter();
  await Hive.openBox<String>(AppConstants.tasksBox);
  await Hive.openBox<String>(AppConstants.settingsBox);

  // ── Run ───────────────────────────────────────────────
  runApp(
    const ProviderScope(
      child: SmartTaskManagerApp(),
    ),
  );
}
