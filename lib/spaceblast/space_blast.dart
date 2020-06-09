import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:flutter/material.dart' as mat;
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:onlinepainter/game_engine/game.dart';
import 'package:onlinepainter/spaceblast/universe.dart';
import 'package:vector_math/vector_math_64.dart';

class Tutorial {
  Function isFinished;
  String text;

  Tutorial(this.isFinished, this.text);
}

class SpaceBlast extends Game {
  bool paused = false;
  bool scrolled = false;
  bool panned = false;
  bool spawned = false;
  bool selected = false;
  bool spawnSelect = false;
  bool accelerated = false;
  bool stopped = false;
  bool massChanged = false;
  int currentTutorial = 0;
  double maxMass = 10000;
  Planet selectedPlanet;
  List<Tutorial> tutorials;
  Universe universe;

  bool get planetSelected => selectedPlanet != null;

  Paint circlePaint = Paint()
    ..color = mat.Colors.white
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.fill
    ..strokeWidth = 1;

  Paint explosionPaint = Paint()
    ..color = mat.Colors.yellow
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

  SpaceBlast() {
    tutorials = [
      Tutorial(() {
        return scrolled;
      }, "Scroll with the mouse to zoom in and out"),
      Tutorial(() {
        return panned;
      }, "Hold space bar and use mouse to pan camera"),
      Tutorial(() {
        return spawned;
      }, "Left click empty space to spawn a new body"),
      Tutorial(() {
        return selected;
      }, "Left click a body to select it"),
      Tutorial(() {
        return spawnSelect;
      }, "Hold shift and left click an empty space to spawn and select a body"),
      Tutorial(() {
        return accelerated;
      }, "Hold W,A,S,D keys to accelerate selected body"),
      Tutorial(() {
        return stopped;
      }, "Press Q to stop selected body"),
      Tutorial(() {
        return massChanged;
      }, "Hold shift and scroll to increase/decrease selected body's mass")
    ];
  }

  @override
  void init() {
    if (universe == null) {
      universe = Universe();
      universe.onPlanetDestroyed.stream.listen(handleCollision);
    }
    universe.planets.clear();
    camera = Vector2(0, 0);
    zoom = 2;
    for (int i = 0; i < 10; i++) {
      spawnRandomPlanet();
    }
    selectedPlanet = universe.planets[0];
  }

  void update() {
    if (currentTutorial >= tutorials.length) {
      return;
    }
    if (tutorials[currentTutorial].isFinished()) {
      currentTutorial++;
    }

    readUserInput();
    universe.update();

    if (planetSelected) {
      centerCamera(selectedPlanet.position);
    }
  }

  void dispose() {
    universe.dispose();
  }

  @override
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
            ],
          ),
        Expanded(
          child: SizedBox(),
        ),
        IconButton(
          icon: Icon(Icons.refresh),
          onPressed: init,
        ),
        IconButton(
          icon: Icon(paused ? Icons.play_arrow : Icons.pause),
          onPressed: togglePaused,
        )
      ],
    );
  }

  void handleCollision(PlanetCollision planetCollision) {
    if (selectedPlanet == null) return;

    if (selectedPlanet == planetCollision.target) {
      selectPlanet(planetCollision.source);
    }
  }

  void selectPlanet(Planet planet) {
    selectedPlanet = planet;
  }

  void deselectPlanet() {
    selectedPlanet = null;
  }

  @override
  List<Widget> buildUI(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    bool isMobile = size.width < 700;

    return [
      if (!isMobile && currentTutorial < tutorials.length)
        Positioned(
          bottom: 50,
          left: 50,
          right: 50,
          child: Text(
            tutorials[currentTutorial].text,
            textAlign: TextAlign.center,
            style: TextStyle(color: mat.Colors.blueAccent, fontSize: 20),
          ),
        ),
      if (isMobile)
        Container(
          width: double.infinity,
          height: size.height,
          alignment: Alignment.bottomRight,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: Icon(
                  Icons.zoom_out,
                  color: mat.Colors.orange,
                  size: 30,
                ),
                onPressed: () {
                  zoom *= 1.1;
                  if (planetSelected) {
                    centerCamera(selectedPlanet.position, smooth: 1);
                    return;
                  }
                },
              ),
              IconButton(
                icon: Icon(
                  Icons.zoom_in,
                  color: mat.Colors.orange,
                  size: 30,
                ),
                onPressed: () {
                  zoom *= 0.9;
                  if (planetSelected) {
                    centerCamera(selectedPlanet.position, smooth: 1);
                    return;
                  }
                },
              ),
            ],
          ),
        )
    ];
  }

  @override
  void draw(Canvas canvas, Size size) {
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

  void readUserInput() {
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
    } else {
      double acceleration = 0.5;
      if (keyIsPressed(LogicalKeyboardKey.keyA)) {
        selectedPlanet.velocity.x -= acceleration;
        accelerated = true;
      }
      if (keyIsPressed(LogicalKeyboardKey.keyW)) {
        selectedPlanet.velocity.y -= acceleration;
        accelerated = true;
      }
      if (keyIsPressed(LogicalKeyboardKey.keyD)) {
        selectedPlanet.velocity.x += acceleration;
        accelerated = true;
      }
      if (keyIsPressed(LogicalKeyboardKey.keyS)) {
        selectedPlanet.velocity.y += acceleration;
        accelerated = true;
      }
    }
  }

  @override
  void handleMouseMovement() {
    if (keyIsPressed(LogicalKeyboardKey.space)) {
      camera -= mouseWorldVelocity;
      panned = true;
    }
  }

  @override
  void handleMouseScroll(double scroll) {
    scrolled = true;

    if (planetSelected && keyIsPressed(LogicalKeyboardKey.shiftLeft)) {
      selectedPlanet.mass += 0.05 + selectedPlanet.mass * 0.001 * -scroll;
      massChanged = true;
      return;
    }

    double scrollSensitivity = 0.02;

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

  void spawnRandomVisiblePlanet() {
    Vector2 min = convertScreenToWorldPosition(0, 0);
    Vector2 max =
        convertScreenToWorldPosition(screenSize.width, screenSize.height);
    Vector2 range = max - min;
    double x = min.x + (random.nextDouble() * range.x);
    double y = min.y + (random.nextDouble() * range.y);
    universe.add(Vector2(x, y), random.nextDouble() * zoom);
  }

  Vector2 getRandomPosition() {
    double padding = 20;
    return Vector2(padding + random.nextDouble() * (-padding),
        padding + (random.nextDouble() * (-padding)));
  }

  void updateCamera() {
    if (selectedPlanet != null) {
      centerCamera(selectedPlanet.position);
    }
  }

  void togglePaused() {
    paused = !paused;
    print("paused = $paused");
  }

  @override
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
        selected = true;
        return;
      }
    }

    Planet planet = universe.add(mouseWorldPosition, 1);

    spawned = true;

    if (keyIsPressed(LogicalKeyboardKey.shiftLeft)) {
      selectPlanet(planet);
      spawnSelect = true;
    }
  }

  @override
  void handleKeyPressed(RawKeyEvent event) {
    if (selectedPlanet != null && event.isKeyPressed(LogicalKeyboardKey.keyQ)) {
      selectedPlanet.velocity = Vector2.zero();
      stopped = true;
    }
    if (event.isKeyPressed(LogicalKeyboardKey.space) ||
        event.isKeyPressed(LogicalKeyboardKey.keyE)) {
      deselectPlanet();
    }
    if (event.isKeyPressed(LogicalKeyboardKey.keyR)) {
      spawnRandomVisiblePlanet();
    }
    if (event.isKeyPressed(LogicalKeyboardKey.arrowRight)) {
      selectNextPlanet();
    }
    if (event.isKeyPressed(LogicalKeyboardKey.keyG) && planetSelected) {
      selectedPlanet.setPosition(mouseWorldPosition);
    }
    if (event.isKeyPressed(LogicalKeyboardKey.arrowLeft)) {
      selectPreviousPlanet();
    }
  }
}
