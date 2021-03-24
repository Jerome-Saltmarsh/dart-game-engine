import 'dart:async';

import 'package:flutter/material.dart';

import 'package:flutter/services.dart';
import 'package:onlinepainter/game_engine/game_ui.dart';
import 'dart:ui' as ui;

import 'package:vector_math/vector_math.dart';

class Images {
  ui.Image skeletonIdle;
  ui.Image skeletonWalk;
  ui.Image skeletonWalk1;
  ui.Image skeletonWalk2;
  ui.Image skeletonWalk3;

  Images(){
    init();
  }

  Future init() async {
    print('images.init()');
    skeletonIdle = await loadImage('images/skeleton/skeleton-idle.png');
    skeletonWalk = await loadImage('images/skeleton/skeleton-walk.png');
  }
}

class Skeleton {}

class BasicRender {
  Images img;
  double width;
  double left;

  void draw() {
    // canvas.drawImageRect(numbers.image, Rect.fromLTWH(0, 0, 100, 100), Rect.fromLTWH(mousePosX, mousePosY, 400, 500), paint);
  }
}

Images images = Images();

double angle = 0;

class Zombies extends GameUI {
  ui.Image potion;
  ui.Image numbers1;
  ui.Image numbers2;
  ui.Image numbers3;
  ui.Image numbers4;
  Sprite numbers;

  Vector2 playerPosition = Vector2(200, 200);

  @override
  Future init() async {
    potion = await loadImage('images/potion.png');
    numbers1 = await loadImage('images/numbers1.png');
    numbers2 = await loadImage('images/numbers2.png');
    numbers3 = await loadImage('images/numbers3.png');
    numbers4 = await loadImage('images/numbers4.png');
    numbers = Sprite([numbers1, numbers2, numbers3, numbers4]);
  }

  @override
  void draw(Canvas canvas, Size size) {

    if (mousePosition != null) {
      canvas.drawCircle(mousePosition, 10, paint);
    }

    canvas.drawRRect(RRect.fromLTRBR(10, 20, 50, 100, Radius.circular(10)), paint);

    if (images.skeletonIdle != null) {
      // images.skeletonWalk.width / 3;

      // canvas.rotate(1);
      // canvas.rotate(angle);
      // angle += 0.01;
      // canvas.drawImageRect(
      //     images.skeletonIdle,
      //     Rect.fromLTWH(0, 0, images.skeletonIdle.width.toDouble(),
      //         images.skeletonIdle.height.toDouble()),
      //     Rect
      //     Rect.fromLTWH(
      //         playerPosition.x,
      //         playerPosition.y,
      //         images.skeletonIdle.width.toDouble(),
      //         images.skeletonIdle.height.toDouble()),
      //     paint);
    }

    if (potion != null) {
      // canvas.drawImageRect(potion, Rect.fromLTWH(0, 0, 100, 100), Rect.fromLTWH(mousePosX, mousePosY, 400, 500), paint);
      canvas.drawAtlas(potion, <RSTransform>[
        RSTransform.fromComponents(
          rotation: 39,
          scale: 1.0,
          // Center of the sprite relative to its rect
          anchorX: 20.0,
          anchorY: 20.0,
          // Location at which to draw the center of the sprite
          translateX: 155,
          translateY: 215,
        )
      ], [Rect.fromLTWH(0, 0, 100, 100)], null ,BlendMode.color, null, paint);
    }
  }

  @override
  void fixedUpdate() {
    double speed = 4;
    if (keyPressed(LogicalKeyboardKey.keyW)) {
      playerPosition.y -= speed;
    }
    if (keyPressed(LogicalKeyboardKey.keyS)) {
      playerPosition.y += speed;
    }
    if (keyPressed(LogicalKeyboardKey.keyA)) {
      playerPosition.x -= speed;
    }
    if (keyPressed(LogicalKeyboardKey.keyD)) {
      playerPosition.x += speed;
    }

    if (mouseClicked) {

    }
  }

  @override
  Widget build(BuildContext context) {
    return Text("Hello World");
  }
}
