import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/material.dart' as mat;
import 'package:onlinepainter/game.dart';
import 'package:positioned_tap_detector/positioned_tap_detector.dart';
import 'package:vector_math/vector_math_64.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: mat.Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Game game;
  CustomPainter customPainter;
  CustomPaint customPaint;

  @override
  void initState() {
    Timer.periodic(Duration(milliseconds: 100), (timer) {
      fixedUpdate();
    });
    game = Game();
    game.add(Vector2(50, 50), 10, velocity: Vector2.zero());
    game.add(Vector2(200, 50), 15, velocity: Vector2.zero());
    super.initState();
  }

  void fixedUpdate() {
    game.update();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {

    Size size = MediaQuery.of(context).size;
    customPainter = DrawCircle(game);
    customPaint = CustomPaint(
      size: size,
      painter: customPainter,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text("Online Painter"),
      ),
      body: Column(
        children: <Widget>[
          PositionedTapDetector(
            onTap: (position) {
              Vector2 pos = Vector2(position.relative.dx, position.relative.dy);
              double radius = 10;
              game.add(pos, radius, velocity: Vector2.zero());
            },
            child: Container(
              color: mat.Colors.grey,
              width: size.width,
              height: size.height,
              child: customPaint,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        tooltip: 'Increment',
        child: Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

class Line {
  Vector start;
  Vector end;

  Line(this.start, this.end);
}

class DrawCircle extends CustomPainter {
  Game game;

  DrawCircle(this.game);

  Paint circlePaint = Paint()
    ..color = mat.Colors.red
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.fill
    ..strokeWidth = 1;

  @override
  void paint(Canvas canvas, Size size) {
    game.planets.forEach((planet) {
      canvas.drawCircle(Offset(planet.position.x, planet.position.y), planet.radius, circlePaint);
    });
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
