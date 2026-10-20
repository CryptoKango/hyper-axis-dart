import 'package:flutter/material.dart';
import 'package:hyper_axis/hyper_axis.dart';

void main() {
  runApp(const HyperAxisExampleApp());
}

final class HyperAxisExampleApp extends StatelessWidget {
  const HyperAxisExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HyperAxis',
      theme: ThemeData(colorSchemeSeed: Colors.indigo),
      home: const Scaffold(
        body: Center(child: Text('HyperAxis Dart $hyperAxisDartVersion')),
      ),
    );
  }
}
