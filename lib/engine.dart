import 'dart:async';
import 'dart:math';

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
  // public
  StreamController<RawKeyEvent> onKeyPressed = StreamController<RawKeyEvent>();

  // private
  bool _initialized = false;
  bool _paused = false;
  Size _screenSize;
  CustomPainter _customPainter;
  CustomPaint _customPaint;
  FocusNode _keyboardFocusNode;
  double appBarHeight = 70;
  Random random = Random();

  @override
  void initState() {
    Timer.periodic(Duration(milliseconds: 1000 ~/ widget.fps), (timer) {
      fixedUpdate();
    });
    _keyboardFocusNode = FocusNode();
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
    camera = Vector3(0, 0, 1);
    game.rightRound = _screenSize.width - 10;
    game.bottomBound = _screenSize.height - appBarHeight;
    for (int i = 0; i < 10; i++) {
      spawnRandomPlanet();
    }
  }

  void spawnRandomPlanet() {
    double mass = random.nextDouble() * 5;

    double rValue(double max) {
      double v = random.nextDouble() * max;
      if (random.nextBool()) {
        return -v;
      }
      return v;
    }

    Vector2 velocity = Vector2(rValue(2), rValue(2));
    Planet planet = game.add(getRandomPosition(), mass);
    planet.velocity = velocity;
  }

  Vector2 getRandomPosition() {
    double padding = 20;
    return Vector2(padding + random.nextDouble() * (game.rightRound - padding),
        padding + (random.nextDouble() * (game.bottomBound - padding)));
  }

  void fixedUpdate() {
    if (!_paused) {
      game.update();
    }
    setState(doNothing);
  }

  void doNothing() {
    // prevents creating a new lambda each frame.
  }

  void togglePaused() {
    _paused = !_paused;
    print("Game.paused = $_paused");
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
      togglePaused();
    }
  }

  @override
  Widget build(BuildContext context) {
    _screenSize = MediaQuery.of(context).size;

    if (!_initialized) {
      _initialized = true;
      initialize();
    }
    if (!_keyboardFocusNode.hasFocus) {
      FocusScope.of(context).requestFocus(_keyboardFocusNode);
    }

    _customPainter = EnginePainter();
    _customPaint = CustomPaint(
      size: _screenSize,
      painter: _customPainter,
    );

    return RawKeyboardListener(
      focusNode: _keyboardFocusNode,
      onKey: (key) {
        onKeyPressed.add(key);
      },
      child: Scaffold(
        appBar: AppBar(
//          title: GestureDetector(onTap: initialize, child: Text("Reset")),
          actions: [
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: initialize,
            ),
            if (game != null)
              Checkbox(
                value: !game.bounded,
                onChanged: (value) {
                  game.bounded = !value;
                },
                activeColor: mat.Colors.orange,
                checkColor: mat.Colors.black,
              ),
            if (selectedPlanet != null)
              Container(
                width: 200,
                child: Slider(
                  value: selectedPlanet.mass,
                  onChanged: (value) {
                    selectedPlanet.mass = value;
                  },
                  min: 0.1,
                  max: 100,
                  label: "Mass",
                  activeColor: mat.Colors.black,
                  inactiveColor: mat.Colors.white,
                ),
              ),
            IconButton(
              icon: Icon(_paused ? Icons.play_arrow : Icons.pause),
              onPressed: togglePaused,
            )
          ],
        ),
        body: PositionedTapDetector(
          onTap: (position) {

            print("Click x:${position.relative.dx}, y:${position.relative.dy}");

            double mass = 1;
            Vector2 wPos = convertScreenToWorldPosition(
                position.relative.dx, position.relative.dy);
            game.add(wPos, mass);
          },
          child: Listener(
            onPointerSignal: (pointerSignal) {
              if (pointerSignal is PointerScrollEvent) {
                double scroll = pointerSignal.scrollDelta.dy;
                zoom +=
                    (scroll * scrollSensitivity) * (zoom * scrollSensitivity);
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
              width: _screenSize.width,
              height: _screenSize.height,
              child: _customPaint,
            ),
          ),
        ),
      ),
    );
  }
}

Paint circlePaint = Paint()
  ..color = mat.Colors.white
  ..strokeCap = StrokeCap.round
  ..style = PaintingStyle.fill
  ..strokeWidth = 1;

Paint linePaint = Paint()
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
double scrollSensitivity = 0.02;
Vector2 zero = Vector2.zero();

double get zoom => camera.z;
Planet selectedPlanet;

double minZoom = 0.005;

set zoom(double value) {
  if (value < minZoom) {
    value = minZoom;
  }
  camera.z = value;
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

class EnginePainter extends CustomPainter {
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

      for (int i = 0; i < planet.positionHistory.length - 1; i++) {
        canvas.drawLine(
            convertWorldToScreenPosition(planet.positionHistory.elementAt(i)),
            convertWorldToScreenPosition(
                planet.positionHistory.elementAt(i + 1)),
            linePaint);
      }
    });

    if (game.bounded) {
      Offset topLeft =
          convertWorldToScreenPosition(Vector2(game.leftBound, game.topBound));
      Offset bottomRight = convertWorldToScreenPosition(
          Vector2(game.rightRound, game.bottomBound));
      Offset topRight = Offset(bottomRight.dx, topLeft.dy);
      Offset bottomLeft = Offset(topLeft.dx, bottomRight.dy);

      canvas.drawLine(topLeft, bottomLeft, borderPaint);
      canvas.drawLine(topLeft, topRight, borderPaint);
      canvas.drawLine(topRight, bottomRight, borderPaint);
      canvas.drawLine(bottomLeft, bottomRight, borderPaint);
    }

    Offset gridCenter = convertWorldToScreenPosition(zero);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
