
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:onlinepainter/game_engine/game_ui.dart';

class Zombies extends GameUI {

  @override
  void draw(Canvas canvas, Size size) {
    canvas.drawCircle(mousePosition, 10, paint);
  }

  @override
  void fixedUpdate() {

    if(keyPressed(LogicalKeyboardKey.arrowUp)){
      paint.color = Colors.yellow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Text("Hello World");
  }
}