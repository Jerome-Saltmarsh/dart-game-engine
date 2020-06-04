import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart' as mat;
import 'package:flutter/services.dart';
import 'package:onlinepainter/universe.dart';
import 'package:positioned_tap_detector/positioned_tap_detector.dart';
import 'package:vector_math/vector_math_64.dart';

class GameEngine extends StatefulWidget {
  /// Frames Per Second
  final int fps;

  GameEngine({this.fps = 60});

  @override
  _GameEngineState createState() => _GameEngineState();
}

class _GameEngineState extends State<GameEngine> {
  CustomPainter customPainter;
  CustomPaint customPaint;
  StreamController<RawKeyEvent> onKeyPressed = StreamController<RawKeyEvent>();
  FocusNode _keyboardFocusNode = FocusNode();
  bool initialized = false;
  Size screenSize;

  @override
  void initState() {
    Timer.periodic(Duration(milliseconds: 1000 ~/ widget.fps), (timer) {
      fixedUpdate();
    });
    onKeyPressed.stream.listen(onKeyEvent);
    super.initState();
  }

  @override
  void dispose() {
    onKeyPressed.close();
    super.dispose();
  }

  void initialize() {
    game = Universe();
    game.add(Vector2(50, 50), 1, velocity: Vector2.zero());
    game.add(Vector2(200, 50), 2, velocity: Vector2.zero());
    game.add(Vector2(150, 200), 3, velocity: Vector2.zero());
    camera = Vector3(0, 0, 1);
    game.rightRound = screenSize.width;
    game.bottomBound = screenSize.height;
  }

  void fixedUpdate() {
    game.update();
    setState(doNothing);
  }

  void doNothing() {
    // prevents creating a new lambda each frame.
  }

  void onKeyEvent(RawKeyEvent event) {
    double speed = 10 * camera.z;

    if (event.isKeyPressed(LogicalKeyboardKey.keyA)) {
      camera.x -= speed;
    }
    if (event.isKeyPressed(LogicalKeyboardKey.keyW)) {
      camera.y -= speed;
    }
    if (event.isKeyPressed(LogicalKeyboardKey.keyD)) {
      camera.x += speed;
    }
    if (event.isKeyPressed(LogicalKeyboardKey.keyS)) {
      camera.y += speed;
    }
    if (event.isKeyPressed(LogicalKeyboardKey.space)) {
      game.togglePaused();
    }
  }

  @override
  Widget build(BuildContext context) {
    screenSize = MediaQuery.of(context).size;

    if (!initialized) {
      initialized = true;
      initialize();
    }
    if (!_keyboardFocusNode.hasFocus) {
      FocusScope.of(context).requestFocus(_keyboardFocusNode);
    }

    Size size = MediaQuery.of(context).size;
    customPainter = DrawCircle();
    customPaint = CustomPaint(
      size: size,
      painter: customPainter,
    );

    return RawKeyboardListener(
      focusNode: _keyboardFocusNode,
      onKey: (key) {
        onKeyPressed.add(key);
      },
      child: Scaffold(
        appBar: AppBar(
          title: GestureDetector(onTap: initialize, child: Text("Reset")),
        ),
        body: PositionedTapDetector(
          onTap: (position) {
            double mass = 1;
            Vector2 wPos = convertScreenToWorldPosition(position.relative.dx, position.relative.dy);
            game.add(wPos, mass, velocity: Vector2.zero());
          },
          child: Listener(
            onPointerSignal: (pointerSignal) {
              if (pointerSignal is PointerScrollEvent) {
                double scroll = pointerSignal.scrollDelta.dy;
                zoom += (scroll * 0.01) * (zoom * 0.01);
//
//              Offset _getWidgetTopLeft() {
//                final translation =
//                context?.findRenderObject()?.getTransformTo(null)?.getTranslation();
//                return translation != null ? Offset(translation.x, translation.y) : null;
//              }
//              final topLeft = _getWidgetTopLeft();
//              final global = Offset(pointerSignal.position.dx, pointerSignal.position.dy);
//              final relative = topLeft != null ? global - topLeft : null;
//
//
//              Vector2 pos = Vector2(relative.dx, relative.dy);
//              toWorldPosition(pos);
//              game.add(pos, 2, velocity: Vector2.zero());
              }
            },
            child: Container(
              color: mat.Colors.black,
              width: size.width,
              height: size.height,
              child: customPaint,
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: game.togglePaused,
          child: Icon(game.paused ? Icons.play_arrow : Icons.pause),
        ), // This trailing comma makes auto-formatting nicer for build methods.
      ),
    );
  }
}

Paint circlePaint = Paint()
  ..color = mat.Colors.white
  ..strokeCap = StrokeCap.round
  ..style = PaintingStyle.fill
  ..strokeWidth = 1;

Paint borderPaint = Paint()
  ..color = mat.Colors.white
  ..strokeCap = StrokeCap.round
  ..style = PaintingStyle.fill
  ..strokeWidth = 2;

Universe game;
Vector3 camera = Vector3(0, 0, 1);

double get zoom => camera.z;

set zoom(double value) {
  if (value < 0.1) {
    value = 0.1;
  }
  camera.z = value;
}

Offset convertWorldToScreenPosition(Vector2 position){
  double transX = camera.x / zoom;
  double transY = camera.y / zoom;
  return  Offset((position.x - transX) / zoom, (position.y - transY) / zoom);
}

Vector2 convertScreenToWorldPosition(double x, double y){
  double transX = camera.x * zoom;
  double transY = camera.y * zoom;
  return  Vector2((x - transX) * zoom, (y - transY) * zoom);
}

class DrawCircle extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    double transX = camera.x / zoom;
    double transY = camera.y / zoom;

    game.planets.forEach((planet) {
      canvas.drawCircle(
          Offset((planet.position.x - transX) / zoom,
              (planet.position.y - transY) / zoom),
          planet.radius / zoom,
          circlePaint);
    });

    Offset topLeft = convertWorldToScreenPosition(Vector2(game.leftBound, game.topBound));
    Offset bottomRight = convertWorldToScreenPosition(Vector2(game.rightRound, game.bottomBound));
    Offset topRight = Offset(bottomRight.dx, topLeft.dy);
    Offset bottomLeft = Offset(topLeft.dx, bottomRight.dy);

    canvas.drawLine(topLeft, bottomLeft, borderPaint);
    canvas.drawLine(topLeft, topRight, borderPaint);
    canvas.drawLine(topRight, bottomRight, borderPaint);
    canvas.drawLine(bottomLeft, bottomRight, borderPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
