import 'package:flutter/material.dart';
import 'package:flutter/material.dart' as mat;
import 'package:onlinepainter/engine.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Blast Abouts',
      theme: ThemeData(
        primarySwatch: mat.Colors.orange,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: GameEngine(),
    );
  }
}
