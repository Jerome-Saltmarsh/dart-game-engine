import 'dart:math';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart' as mat;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:vector_math/vector_math_64.dart';

// variables
Vector2 camera = Vector2(0, 0);

// methods
bool keyPressed(LogicalKeyboardKey key) {
  return RawKeyboard.instance.keysPressed.contains(key);
}

abstract class Game {

  BuildContext context;
  Color backgroundColor = mat.Colors.black;
  Random random = Random();
  double minZoom = 0.005;
  Offset mousePosition;
  Offset previousMousePosition;
  Offset mouseDelta;
  Vector2 zero = Vector2.zero();
  double cameraZ = 1;
  Size screenSize;

  double get zoom => cameraZ;

  Vector2 get mouseWorldPosition => convertScreenToWorldPosition(mousePosition.dx, mousePosition.dy);

  Vector2 get mouseWorldVelocity {
    Vector2 previousMouseWorldPosition = convertScreenToWorldPosition(
        previousMousePosition.dx, previousMousePosition.dy);
    return (mouseWorldPosition - previousMouseWorldPosition) * zoom;
  }

  set zoom(double value) {
    if (value < minZoom) {
      value = minZoom;
    }
    cameraZ = value;
  }

  void handleMouseScroll(double scroll){

  }

  void handleMouseClicked(Offset offset){

  }

  void handleKeyPressed(RawKeyEvent event){

  }

  void handleMouseMovement(){

  }

  void update();
  void draw(Canvas canvas, Size size);

  void init() {}
  void handleScroll(double amount){  }

  void centerCamera(Vector2 worldPosition, {double smooth = 0.1}) {
    Vector2 centerWorldPosition = convertScreenToWorldPosition(
        screenSize.width * 0.5, screenSize.height * 0.5);
    Vector2 translation = worldPosition - centerWorldPosition;
    camera += (translation * zoom * smooth);
  }

  // void handlePointerHoverEvent(PointerHoverEvent pointerHoverEvent) {
  //   previousMousePosition = mousePosition;
  //   mousePosition = pointerHoverEvent.position;
  //   mouseDelta = pointerHoverEvent.delta;
  //   handleMouseMovement();
  // }

  double randomVal(double max) {
    if (random.nextBool()) {
      return -random.nextDouble() * max;
    }
    return random.nextDouble() * max;
  }

  Offset randomOffset(Offset offset, double range) {
    return Offset(offset.dx + randomVal(range), offset.dy + randomVal(range));
  }

  Offset convertWorldToScreenPosition(Vector2 position) {
    double transX = camera.x / zoom;
    double transY = camera.y / zoom;
    return Offset((position.x - transX) / zoom, (position.y - transY) / zoom);
  }

  Vector2 convertScreenToWorldPosition(double x, double y) {
    Vector2 screenPosition = Vector2(x, y);
    Vector2 cameraPosition = Vector2(camera.x, camera.y);
    return (screenPosition * zoom) + (cameraPosition / zoom);
  }

  Widget buildAppBar(BuildContext context) {
    return null;
  }

  List<Widget> buildUI(BuildContext context) {
    return [];
  }

  void dispose() {

  }
}
