import 'dart:async';
import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart' as mat;
import 'package:flutter/services.dart';
import 'package:onlinepainter/universe.dart';
import 'package:positioned_tap_detector/positioned_tap_detector.dart';
import 'package:vector_math/vector_math_64.dart';

// StarField
// Display Mass Text
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
  StreamController<Offset> onMouseClicked = StreamController<Offset>();

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
    onKeyPressed.stream.listen(handleKeyPressed);
    onMouseClicked.stream.listen(handleMouseClicked);
    super.initState();
  }

  void selectNextPlanet() {
    if (universe.planets.isEmpty) return;

    if (selectedPlanet == null || universe.planets.length == 1) {
      selectedPlanet = universe.planets[0];
      return;
    }
    int index = universe.planets.indexOf(selectedPlanet);
    selectedPlanet = universe.planets[(index + 1) % universe.planets.length];
  }

  void selectPreviousPlanet() {
    if (universe.planets.isEmpty) return;

    if (selectedPlanet == null || universe.planets.length == 1) {
      selectedPlanet = universe.planets[0];
      return;
    }
    int index = universe.planets.indexOf(selectedPlanet);
    selectedPlanet = universe.planets[(index - 1) % universe.planets.length];
  }

  @override
  void dispose() {
    onKeyPressed.close();
    onMouseClicked.close();
    universe.dispose();
    super.dispose();
  }

  void initialize() {
    if (universe == null) {
      universe = Universe();
      universe.onPlanetDestroyed.stream.listen(handleCollision);
    }
    universe.planets.clear();
    camera = Vector2(0, 0);
    zoom = 1;
    universe.rightRound = _screenSize.width - 10;
    universe.bottomBound = _screenSize.height - appBarHeight;
    for (int i = 0; i < 10; i++) {
      spawnRandomPlanet();
    }
    selectedPlanet = universe.planets[0];
  }

  void handleCollision(PlanetCollision event) {
    if (selectedPlanet == event.target) {
      selectedPlanet = event.source;
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
    Planet planet = universe.add(getRandomPosition(), mass);
    planet.velocity = velocity;
  }

  Vector2 getRandomPosition() {
    double padding = 20;
    return Vector2(
        padding + random.nextDouble() * (universe.rightRound - padding),
        padding + (random.nextDouble() * (universe.bottomBound - padding)));
  }

  void fixedUpdate() {
    if (cameraTracking && selectedPlanet != null) {
      centerCamera(selectedPlanet.position);
    }

    if (!_paused) {
      universe.update();
    }
    setState(doNothing);
  }

  void trackAllPlanets() {
    //    double x = 0;
//    double y = 0;
//
//    universe.planets.forEach((element) {
//      x += element.position.x;
//      y += element.position.y;
//    });
//
//    x /= universe.planets.length;
//    y /= universe.planets.length;
  }

  void centerCamera(Vector2 worldPosition, {double smooth = 0.1}) {
    Vector2 centerWorldPosition = convertScreenToWorldPosition(
        _screenSize.width * 0.5, _screenSize.height * 0.5);
    Vector2 translation = worldPosition - centerWorldPosition;
    camera += (translation * zoom * smooth);
  }

  void doNothing() {
    // prevents creating a new lambda each frame.
  }

  void togglePaused() {
    _paused = !_paused;
    print("Game.paused = $_paused");
  }

  bool isPressed(LogicalKeyboardKey key){
    return RawKeyboard.instance.keysPressed.contains(key);
  }

  void handleMouseClicked(Offset offset){
    double mass = 1;
    Vector2 wPos = convertScreenToWorldPosition(offset.dx, offset.dy);
    universe.add(wPos, mass);
  }

  void handleKeyPressed(RawKeyEvent event) {
    if (!cameraTracking) {
      double speed = 10 * zoom;
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
    } else if (selectedPlanet != null) {
      double acceleration = 0.5;

      if (event.isKeyPressed(LogicalKeyboardKey.keyQ)) {
        selectedPlanet.velocity = zero;
      }
      if (event.isKeyPressed(LogicalKeyboardKey.keyA)) {
        selectedPlanet.velocity.x -= acceleration;
      }
      if (event.isKeyPressed(LogicalKeyboardKey.keyW)) {
        selectedPlanet.velocity.y -= acceleration;
      }
      if (event.isKeyPressed(LogicalKeyboardKey.keyD)) {
        selectedPlanet.velocity.x += acceleration;
      }
      if (event.isKeyPressed(LogicalKeyboardKey.keyS)) {
        selectedPlanet.velocity.y += acceleration;
      }
    }

    if (event.isKeyPressed(LogicalKeyboardKey.space)) {
      togglePaused();
    }

    if (event.isKeyPressed(LogicalKeyboardKey.arrowRight)) {
      selectNextPlanet();
    }
    if (event.isKeyPressed(LogicalKeyboardKey.arrowLeft)) {
      selectPreviousPlanet();
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
        appBar: buildAppBar(context),
        body: PositionedTapDetector(
          onTap: (position) {
            onMouseClicked.add(position.relative);
          },
          child: Listener(
            onPointerSignal: (pointerSignal) {
              if (pointerSignal is PointerScrollEvent) {
                double scroll = pointerSignal.scrollDelta.dy;
                zoom +=
                    (scroll * scrollSensitivity) * (zoom * scrollSensitivity);
                centerCamera(selectedPlanet.position, smooth: 1);
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

  Widget buildAppBar(BuildContext context) {
    return AppBar(
      actions: [
        if (universe.planets.length > 1)
          IconButton(
            icon: Icon(Icons.navigate_next),
            onPressed: selectNextPlanet,
          ),
        IconButton(
          icon: Icon(cameraTracking ? Icons.track_changes : Icons.clear),
          onPressed: () {
            cameraTracking = !cameraTracking;
          },
        ),
        if (universe != null)
          Checkbox(
            value: !universe.bounded,
            onChanged: (value) {
              universe.bounded = !value;
            },
            activeColor: mat.Colors.orange,
            checkColor: mat.Colors.black,
          ),
        if (selectedPlanet != null)
          Row(
            children: [
              Text(
                "Mass: ${selectedPlanet.mass.roundToDouble()}",
              ),
              Container(
                width: 200,
                child: Slider(
                  value: selectedPlanet.mass > maxMass
                      ? maxMass
                      : selectedPlanet.mass,
                  onChanged: (value) {
                    selectedPlanet.mass = value;
                  },
                  min: 0.1,
                  max: maxMass,
                  label: "Mass ${selectedPlanet.mass.round()}",
                  activeColor: mat.Colors.black,
                  inactiveColor: mat.Colors.white,
                ),
              ),
            ],
          ),
        SizedBox(
          width: 10,
        ),
        IconButton(
          icon: Icon(Icons.refresh),
          onPressed: initialize,
        ),
        IconButton(
          icon: Icon(_paused ? Icons.play_arrow : Icons.pause),
          onPressed: togglePaused,
        )
      ],
    );
  }
}

Paint circlePaint = Paint()
  ..color = mat.Colors.white
  ..strokeCap = StrokeCap.round
  ..style = PaintingStyle.fill
  ..strokeWidth = 1;

Paint selectedPlanetPaint = Paint()
  ..color = mat.Colors.orange
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

double maxMass = 1000;
Universe universe;
Vector2 camera = Vector2(0, 0);
double scrollSensitivity = 0.02;
Vector2 zero = Vector2.zero();
double cameraZ = 1;
bool cameraTracking = true;

double get zoom => cameraZ;

set zoom(double value) {
  if (value < minZoom) {
    value = minZoom;
  }
  cameraZ = value;
}

Planet selectedPlanet;

double minZoom = 0.005;

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

    if (selectedPlanet != null) {
      canvas.drawCircle(convertWorldToScreenPosition(selectedPlanet.position),
          selectedPlanet.radius * 2 / zoom, selectedPlanetPaint);
    }

    universe.planets.forEach((planet) {
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

    if (universe.bounded) {
      Offset topLeft = convertWorldToScreenPosition(
          Vector2(universe.leftBound, universe.topBound));
      Offset bottomRight = convertWorldToScreenPosition(
          Vector2(universe.rightRound, universe.bottomBound));
      Offset topRight = Offset(bottomRight.dx, topLeft.dy);
      Offset bottomLeft = Offset(topLeft.dx, bottomRight.dy);

      canvas.drawLine(topLeft, bottomLeft, borderPaint);
      canvas.drawLine(topLeft, topRight, borderPaint);
      canvas.drawLine(topRight, bottomRight, borderPaint);
      canvas.drawLine(bottomLeft, bottomRight, borderPaint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
