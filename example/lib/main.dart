import 'package:flutter/material.dart';

import 'src/hyper_axis_demo_page.dart';

void main() {
  runApp(const HyperAxisExampleApp());
}

final class HyperAxisExampleApp extends StatelessWidget {
  const HyperAxisExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'HyperAxis 移动端示例',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xff5b5bd6),
          brightness: Brightness.light,
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
        useMaterial3: true,
      ),
      home: const HyperAxisDemoPage(),
    );
  }
}
