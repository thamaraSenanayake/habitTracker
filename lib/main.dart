import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'views/auth_wrapper.dart';

void main() {
  runApp(
    const ProviderScope(
      child: HabitFlowApp(),
    ),
  );
}

class HabitFlowApp extends StatelessWidget {
  const HabitFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'HabitFlow',
      theme: ThemeData.dark(),
      home: const AuthWrapper(),
    );
  }
}