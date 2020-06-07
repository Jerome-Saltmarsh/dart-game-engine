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
// Implement Collision Explosion
class GameEngine extends StatefulWidget {
  /// Frames Per Second
  final int fps;

  GameEngine({this.fps = 60});

  @override
  _GameEngineState createState() => _GameEngineState();
}

class _GameEngineState extends State<GameEngine> {
  StreamController<RawKeyEvent> onKeyPressed = StreamController<RawKeyEvent>();
  StreamController<Offset> onMouseClicked = StreamController<Offset>();
  StreamController<PointerSignalEvent> onPointerSignalEvent =
      StreamController<PointerSignalEvent>();
  StreamController<double> onMouseScroll = StreamController<double>();

  bool _initialized = false;
  bool _paused = false;
  Size _screenSize;
  CustomPainter _customPainter;
  CustomPaint _customPaint;
  FocusNode _keyboardFocusNode;
  double appBarHeight = 70;
  Random random = Random();
  mat.Color _backgroundColor = mat.Colors.black;

  @override
  void initState() {
    Timer.periodic(Duration(milliseconds: 1000 ~/ widget.fps), (timer) {
      fixedUpdate();
    });
    _keyboardFocusNode = FocusNode();
    onKeyPressed.stream.listen(handleKeyPressed);
    onMouseClicked.stream.listen(handleMouseClicked);
    onPointerSignalEvent.stream.listen(handlePointerSignalEvent);
    onMouseScroll.stream.listen(handleMouseScroll);
    super.initState();
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

  void fixedUpdate() {
    handleUserInput();
    updateCamera();
    if (!_paused) {
      universe.update();
    }
    setState(doNothing);
  }

  void handleUserInput() {
    if (selectedPlanet == null) {
      double speed = 10 * zoom;
      if (keyIsPressed(LogicalKeyboardKey.keyA)) {
        camera.x -= speed;
      }
      if (keyIsPressed(LogicalKeyboardKey.keyW)) {
        camera.y -= speed;
      }
      if (keyIsPressed(LogicalKeyboardKey.keyD)) {
        camera.x += speed;
      }
      if (keyIsPressed(LogicalKeyboardKey.keyS)) {
        camera.y += speed;
      }
    }
  }

  void handlePointerSignalEvent(PointerSignalEvent pointerSignalEvent) {
    if (pointerSignalEvent is PointerScrollEvent) {
      onMouseScroll.add(pointerSignalEvent.scrollDelta.dy);
    } else {
      print("Unhandled pointer event $pointerSignalEvent");
    }
  }

  void handleMouseScroll(double scroll) {
    Vector2 preScrollMouseWorldPosition = mouseWorldPosition;
    zoom += (scroll * scrollSensitivity) * (zoom * scrollSensitivity);

    if (planetSelected) {
      centerCamera(selectedPlanet.position, smooth: 1);
      return;
    }

    Vector2 postScrollMouseWorldPos = mouseWorldPosition;
    Vector2 translation = preScrollMouseWorldPosition - postScrollMouseWorldPos;

    if (scroll < 0) {
      // zooming in
      camera += translation * zoom;
    } else {
      // zooming out
      camera += translation * zoom;
    }
  }

  @override
  void dispose() {
    onKeyPressed.close();
    onMouseClicked.close();
    onPointerSignalEvent.close();
    onMouseScroll.close();
    universe.dispose();
    super.dispose();
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

  void handleCollision(PlanetCollision planetCollision) {
    if (selectedPlanet == null) return;

    if (selectedPlanet == planetCollision.target) {
      selectPlanet(planetCollision.source);
    }
  }

  void spawnSolarSystem(Vector2 position,
      {double range = 10000, int planets = 10}) {
    print("spawnSolarSystem");
    double mass = 1000;
    double range = mass * 10;
    universe.add(position, mass);

    for (int i = 0; i < planets; i++) {
      universe.add(randomPositionAround(position, range),
          (mass * 0.5) * random.nextDouble());
    }
  }

  Vector2 randomPositionAround(Vector2 position, double range) {
    return position + Vector2(randomValue(range), randomValue(range));
  }

  void spawnGalaxy(Vector2 position) {
    // has a super massive black whole
    // surrounded by solar systems
  }

  double randomValue(double max) {
    if (random.nextBool()) {
      return -random.nextDouble() * max;
    }
    return random.nextDouble() * max;
  }

  Planet spawnRandomPlanet({int maxMass = 5, double maxDistance = 1000}) {
    Vector2 position =
        Vector2(randomValue(maxDistance), randomValue(maxDistance));
    Vector2 velocity = Vector2(randomValue(2), randomValue(2));
    Planet planet = universe.add(position, random.nextDouble() * maxMass);
    planet.velocity = velocity;
    return planet;
  }

  Vector2 getRandomPosition() {
    double padding = 20;
    return Vector2(
        padding + random.nextDouble() * (universe.rightRound - padding),
        padding + (random.nextDouble() * (universe.bottomBound - padding)));
  }

  void updateCamera() {
    if (selectedPlanet != null) {
      centerCamera(selectedPlanet.position);
    }
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

  void handleMouseClicked(Offset offset) {
    Vector2 mouseWorldPosition =
        convertScreenToWorldPosition(offset.dx, offset.dy);

    if (universe.planets.isNotEmpty) {
      Planet closestPlanet = universe.planets[0];
      double closestPlanetDistance =
          closestPlanet.position.distanceTo(mouseWorldPosition);
      for (int i = 1; i < universe.planets.length; i++) {
        double distance =
            universe.planets[i].position.distanceTo(mouseWorldPosition);
        if (distance < closestPlanetDistance) {
          closestPlanet = universe.planets[i];
          closestPlanetDistance = distance;
        }
      }

      if (closestPlanetDistance / zoom < 30) {
        selectPlanet(closestPlanet);
        return;
      }
    }

    universe.add(mouseWorldPosition, 1);
  }

  void handleKeyPressed(RawKeyEvent event) {
    if (!cameraTracking) {
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
    if (event.isKeyPressed(LogicalKeyboardKey.exit)) {
      deselectPlanet();
    }
    if (event.isKeyPressed(LogicalKeyboardKey.keyE)) {
      deselectPlanet();
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
        body: buildBody(context),
      ),
    );
  }

  Widget buildBody(BuildContext context) {
    return MouseRegion(
      onHover: (pointerHoverEvent) {
        previousMousePosition = mousePosition;
        mousePosition = pointerHoverEvent.position;
        mouseDelta = pointerHoverEvent.delta;

        if (keyIsPressed(LogicalKeyboardKey.space)) {
          deselectPlanet();
          camera -= mouseWorldVelocity;
        }
      },
      child: PositionedTapDetector(
        onTap: (position) {
          onMouseClicked.add(position.relative);
        },
        child: Listener(
          onPointerSignal: (pointerSignal) {
            onPointerSignalEvent.add(pointerSignal);
          },
          child: Container(
            color: _backgroundColor,
            width: _screenSize.width,
            height: _screenSize.height,
            child: _customPaint,
          ),
        ),
      ),
    );
  }

  Widget buildAppBar(BuildContext context) {
    return AppBar(
      actions: [
        if (selectedPlanet != null)
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10),
                decoration: const BoxDecoration(
                  border: Border(
                    left: BorderSide(
                        color: mat.Colors.black,
                        width: 1,
                        style: BorderStyle.solid),
                    right: BorderSide(
                        color: mat.Colors.black,
                        width: 1,
                        style: BorderStyle.solid),
                  ),
                ),
                child: Row(
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
              ),
              FlatButton(
                onPressed: deselectPlanet,
                child: Text(
                  "Deselect",
                ),
              ),
            ],
          ),
        FlatButton(
          onPressed: () {
//            spawnRandomPlanet(maxMass: 10000, maxDistance: 100000);
            Vector2 min = convertScreenToWorldPosition(0, 0);
            Vector2 max = convertScreenToWorldPosition(
                _screenSize.width, _screenSize.height);
            Vector2 range = max - min;
            double x = min.x + (random.nextDouble() * range.x);
            double y = min.y + (random.nextDouble() * range.y);
            universe.add(Vector2(x, y), random.nextDouble() * zoom);
          },
          child: Text(
            "Spawn Random",
          ),
        ),
        Expanded(
          child: SizedBox(),
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

  void selectPlanet(Planet planet) {
    selectedPlanet = planet;
  }

  void deselectPlanet() {
    selectedPlanet = null;
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

double maxMass = 10000;
Universe universe;
Vector2 camera = Vector2(0, 0);
Offset mousePosition;
Offset previousMousePosition;
Offset mouseDelta;
double scrollSensitivity = 0.02;
Vector2 zero = Vector2.zero();
double cameraZ = 1;
bool cameraTracking = true;

Vector2 get mouseWorldPosition =>
    convertScreenToWorldPosition(mousePosition.dx, mousePosition.dy);

Vector2 get mouseWorldVelocity {
  Vector2 previousMouseWorldPosition = convertScreenToWorldPosition(
      previousMousePosition.dx, previousMousePosition.dy);
  return (mouseWorldPosition - previousMouseWorldPosition) * zoom;
}

double get zoom => cameraZ;

bool keyIsPressed(LogicalKeyboardKey key) {
  return RawKeyboard.instance.keysPressed.contains(key);
}

set zoom(double value) {
  if (value < minZoom) {
    value = minZoom;
  }
  cameraZ = value;
}

Planet selectedPlanet;
double minZoom = 0.005;

bool get planetSelected => selectedPlanet != null;

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

Random rand = Random();

double randomVal(double max) {
  if (rand.nextBool()) {
    return -rand.nextDouble() * max;
  }
  return rand.nextDouble() * max;
}

Offset randomOffset(Offset offset, double range) {
  return Offset(offset.dx + randomVal(range), offset.dy + randomVal(range));
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
        // comet
//        Offset pos = convertWorldToScreenPosition(planet.positionHistory.elementAt(i));
//        canvas.drawCircle(randomOffset(pos, (planet.positionHistory.length - i) * 0.5), 2, circlePaint);

        canvas.drawLine(
            convertWorldToScreenPosition(planet.positionHistory.elementAt(i)),
            convertWorldToScreenPosition(
                planet.positionHistory.elementAt(i + 1)),
            linePaint);
      }
    });
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
