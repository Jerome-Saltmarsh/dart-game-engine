
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:onlinepainter/game_engine/game_ui.dart';
import 'dart:ui' as ui;


class Sprite {
  final List<ui.Image> images;
  int index = 0;

  Sprite(this.images){
    Timer.periodic(Duration(seconds: 1), (timer) {
      index = (index + 1) % images.length;
    });
  }

  ui.Image get image => images[index];
}

class Zombies extends GameUI {

  ui.Image potion;
  ui.Image numbers1;
  ui.Image numbers2;
  ui.Image numbers3;
  ui.Image numbers4;
  Sprite numbers;

  @override
  Future init() async {
    potion = await loadImage('images/potion.png');
    numbers1 = await loadImage('images/numbers1.png');
    numbers2 = await loadImage('images/numbers2.png');
    numbers3 = await loadImage('images/numbers3.png');
    numbers4 = await loadImage('images/numbers4.png');
    numbers = Sprite([
      numbers1,
      numbers2,
      numbers3,
      numbers4
    ]);
  }

  @override
  void draw(Canvas canvas, Size size) {
    if(mousePosition != null){
      canvas.drawCircle(mousePosition, 10, paint);
    }

    if(potion != null){
      // canvas.drawImageRect(potion, Rect.fromLTWH(0, 0, 100, 100), Rect.fromLTWH(mousePosX, mousePosY, 400, 500), paint);
    }

    if(numbers != null){
      canvas.drawImageRect(numbers.image, Rect.fromLTWH(0, 0, 100, 100), Rect.fromLTWH(mousePosX, mousePosY, 400, 500), paint);
    }
  }

  @override
  void fixedUpdate() {

    if(keyPressed(LogicalKeyboardKey.arrowUp)){
      paint.color = Colors.yellow;
    }

    if(mouseClicked){
      paint.color = Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Text("Hello World");
  }
}