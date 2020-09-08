
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:onlinepainter/game_engine/game_ui.dart';

class Zombies extends GameUI {

  @override
  void draw(Canvas canvas, Size size) {

    Paint paint = Paint()
      ..color = Colors.red
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.fill
      ..strokeWidth = 1;

    canvas.drawCircle(Offset(50, 50), 10, paint);
  }

  @override
  void fixedUpdate() {

  }
}