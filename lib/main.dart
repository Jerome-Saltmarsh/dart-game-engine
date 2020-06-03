import 'dart:async';

import 'package:flutter/gestures.dart';
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

  int get framesPerSecond => 60;

  @override
  void initState() {
    Timer.periodic(Duration(milliseconds: 1000 ~/ framesPerSecond), (timer) {
      fixedUpdate();
    });
    game = Game();
    game.add(Vector2(50, 50), 5, velocity: Vector2.zero());
    game.add(Vector2(200, 50), 5, velocity: Vector2.zero());
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
      body: PositionedTapDetector(
        onTap: (position) {
          Vector2 pos = Vector2(position.relative.dx, position.relative.dy);
          double mass = 1;
          pos.x *= camera.z;
          pos.y *= camera.z;
          game.add(pos, mass, velocity: Vector2.zero());
        },
        child: Listener(
          onPointerSignal: (pointerSignal){
            if(pointerSignal is PointerScrollEvent){
              double scroll = pointerSignal.scrollDelta.dy;
              zoom += (scroll * 0.01) * (zoom * 0.01);
            }
            if(pointerSignal is PointerDownEvent){
              print("Dragging");
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
        onPressed: () {},
        tooltip: 'Increment',
        child: Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

Paint circlePaint = Paint()
  ..color = mat.Colors.white
  ..strokeCap = StrokeCap.round
  ..style = PaintingStyle.fill
  ..strokeWidth = 1;

Vector3 camera = Vector3(0,0, 1);

double get zoom => camera.z;

set zoom(double value){
  if(value < 0.1){
    value = 0.1;
  }
  camera.z = value;
}

class DrawCircle extends CustomPainter {
  Game game;

  DrawCircle(this.game);

  @override
  void paint(Canvas canvas, Size size) {
    game.planets.forEach((planet) {
      canvas.drawCircle(Offset(planet.position.x / zoom, planet.position.y / zoom), planet.radius / zoom, circlePaint);
    });
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
