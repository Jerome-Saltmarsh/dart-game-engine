import 'package:flutter/material.dart';
import 'package:onlinepainter/game_engine/game_ui.dart';
import 'package:onlinepainter/spaceblast/space_blast.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Blast Abouts',
      theme: ThemeData(
        primarySwatch: Colors.orange,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: GameUI(game: SpaceBlast(),),
      debugShowCheckedModeBanner: false,
    );
  }
}
