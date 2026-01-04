import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_devtools_tracker/riverpod_devtools_tracker.dart';

import 'screens/home_screen.dart';

void main() {
  runApp(
    ProviderScope(
      observers: [
        // 整合 RiverpodDevToolsObserver 來追蹤所有 Provider 狀態變化
        RiverpodDevToolsObserver(
          config: TrackerConfig.forPackage('example'),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Riverpod DevTools Tracker Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
