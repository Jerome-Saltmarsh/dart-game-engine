import 'dart:async';
import 'dart:collection';
import 'dart:math';

import 'package:vector_math/vector_math_64.dart';

class Planet {
  Vector2 position;
  Vector2 nextDestination;
  Vector2 shiftedDestination;
  Vector2 previousDestination;
  Vector2 velocity;
  double mass;
  double density = 0.2;

  Queue<Vector2> positionHistory = Queue();

  Planet(this.position, this.mass, this.velocity) {
    previousDestination = position - velocity;
  }

  double distance(Planet that) {
    return position.distanceTo(that.position);
  }

  Vector2 get momentum => velocity * mass;

  double get radius => sqrt(mass / pi) / density;

  void setPosition(Vector2 value){
    position = value;
    previousDestination = value - velocity;
    velocity = Vector2.zero();
  }
}

class PlanetCollision {
  Planet source;
  Planet target;

  PlanetCollision(this.source, this.target);
}

class Explosion {
  double radius;
  Vector2 position;
}

class Universe {
  List<Planet> planets = [];
  List<Explosion> explosions = [];
  double leftBound = 0;
  double rightRound = 300;
  double topBound = 0;
  double bottomBound = 300;
  int tailLength = 15;

  StreamController<PlanetCollision> onPlanetDestroyed = StreamController();

  void update() {
    planets.forEach((planet) {
      planet.nextDestination = planet.position + planet.velocity;
      planet.shiftedDestination =
          calculateSpacialShift(planet.nextDestination, planet);
    });

    planets.forEach((planet) {
      planet.position = planet.shiftedDestination;
      planet.velocity = planet.position - planet.previousDestination;
      planet.previousDestination = planet.nextDestination;
      planet.positionHistory.add(planet.position);

      if (planet.positionHistory.length > tailLength) {
        planet.positionHistory.removeFirst();
      }
    });

    // check for collisions
    for (int i = 0; i < planets.length; i++) {
      for (int j = i + 1; j < planets.length; j++) {
        double distance = planets[i].distance(planets[j]);
        double combinedRadius = planets[i].radius + planets[j].radius;

        if (distance < combinedRadius) {
          Vector2 combinedMomentum = planets[i].momentum + planets[j].momentum;
          double combinedMass = planets[i].mass + planets[j].mass;
          planets[i].mass = combinedMass;
          planets[i].velocity = combinedMomentum / combinedMass;
          onPlanetDestroyed.add(PlanetCollision(planets[i], planets[j]));
          planets.removeAt(j);
          j--;
        }
      }
    }
  }

  void dispose() {
    onPlanetDestroyed.close();
  }

  Vector2 calculateSpacialShift(Vector2 position, Planet planet) {
    Vector2 shiftedPosition = position;
    for (int i = 0; i < planets.length; i++) {
      if (planet == planets[i]) {
        continue;
      }
      shiftedPosition += calculateTranslation(position, planets[i]);
    }
    return shiftedPosition;
  }

  Vector2 calculateTranslation(Vector2 position, Planet planet) {
    double distance = planet.position.distanceTo(position);
    double speed =
        distance - calculatePull(distance, planet.radius, planet.mass);
    Vector2 translation = planet.position - position;
    translation.length = speed;
    return translation;
  }

  double calculatePull(double distance, double radius, double mass) {
    double value = sqrt((distance * distance) - mass);
    if (value.isNaN) {
      return 0;
    }
    return value;
  }

  Planet add(Vector2 position, double mass) {
    if (mass < 0.5) {
      mass = 0.5;
    }
    Planet planet = Planet(position, mass, Vector2.zero());
    planets.add(planet);
    return planet;
  }
}