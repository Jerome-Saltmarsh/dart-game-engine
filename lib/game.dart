import 'dart:math';

import 'package:vector_math/vector_math_64.dart';

class Planet {
  Vector2 position;
  Vector2 nextDestination;
  Vector2 shiftedDestination;
  Vector2 previousDestination;
  Vector2 velocity;
  double mass;

  Planet(this.position, this.mass, this.velocity) {
    previousDestination = position - velocity;
  }

  double distance(Planet that) {
    return position.distanceTo(that.position);
  }

  Vector2 get momentum => velocity * mass;

  double get radius => sqrt(mass / pi) * Game.density;
}

class Game {
  List<Planet> planets = [];
  static double density = 1;
  bool paused = false;

  void update() {
    if (paused) {
      return;
    }

    planets.forEach((planet) {
      planet.nextDestination = planet.position + planet.velocity;
      planet.shiftedDestination =
          calculateSpacialShift(planet.nextDestination, planet);
    });

    planets.forEach((planet) {
      planet.position = planet.shiftedDestination;
      planet.velocity = planet.position - planet.previousDestination;
      planet.previousDestination = planet.nextDestination;
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
          planets.removeAt(j);
          j--;
        }
      }
    }
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
    double speed = distance - calculatePull(distance, planet.radius);
    Vector2 translation = planet.position - position;
    translation.length = speed;
    return translation;
  }

  double calculatePull(double distance, double radius) {
    double value = sqrt((distance * distance) - (radius * radius));
    if (value.isNaN) {
      return 0;
    }
    return value;
  }

  Planet add(Vector2 position, double mass, {Vector2 velocity}) {
    Planet planet = Planet(position, mass, velocity);
    planets.add(planet);
    return planet;
  }

  double convertMassToRadius(double mass) {
    return sqrt(mass / pi) * density;
  }

  double convertRadiusToMass(double radius) {
    return (pi * radius * radius) / density;
  }
}
