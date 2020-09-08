import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart' as mat;
import 'package:flutter/services.dart';
import 'package:positioned_tap_detector/positioned_tap_detector.dart';
import 'package:vector_math/vector_math.dart';
import 'dart:ui' as ui;

typedef PaintGame = Function(Canvas canvas, Size size);

// private global variables
Offset _mousePosition;
Offset _previousMousePosition;
Offset _mouseDelta;
DateTime _lastLeftClicked;

// global variables
Vector2 camera = Vector2(0, 0);
double cameraZ = 1;
Paint paint = Paint()
  ..color = mat.Colors.red
  ..strokeCap = StrokeCap.round
  ..style = PaintingStyle.fill
  ..strokeWidth = 1;

// global properties
Offset get mousePosition => _mousePosition;
Offset get previousMousePosition => _previousMousePosition;
Offset get mouseVelocity => _mouseDelta;
double get mousePosX => _mousePosition.dx;
double get mousePosY => _mousePosition.dy;
bool get mouseClicked => _lastLeftClicked != null && millisecondsSince(_lastLeftClicked) < 500;

// utility methods
int millisecondsSince(DateTime value){
  return durationSince(value).inMilliseconds;
}

Duration durationSince(DateTime value){
  return DateTime.now().difference(value);
}

bool keyPressed(LogicalKeyboardKey key) {
  return RawKeyboard.instance.keysPressed.contains(key);
}

Future<ui.Image> loadImage(String url) async {

  final ByteData data = await rootBundle.load(url);
  final List<int> img = Uint8List.view(data.buffer);

  final Completer<ui.Image> completer = new Completer();
  ui.decodeImageFromList(img, (ui.Image img) {
    return completer.complete(img);
  });
  return completer.future;
}

Offset convertWorldToScreenPosition(Vector2 position) {
  double transX = camera.x / cameraZ;
  double transY = camera.y / cameraZ;
  return Offset((position.x - transX) / cameraZ, (position.y - transY) / cameraZ);
}

Vector2 convertScreenToWorldPosition(Vector2 position) {
  return (position * cameraZ) + (camera / cameraZ);
}

abstract class GameUI extends StatefulWidget {

  final int fps;
  final Color backgroundColor;
  final String title;

  Future init();

  /// used to update the game logic
  void fixedUpdate();
  /// used to draw the game
  void draw(Canvas canvas, Size size);
  /// used to build the ui
  Widget build(BuildContext context);

  GameUI({this.fps = 60, this.backgroundColor = mat.Colors.green, this.title = 'demo'});

  @override
  _GameUIState createState() => _GameUIState();
}

class _GameUIState extends State<GameUI> {

  // variables
  double minZoom = 0.005;
  double cameraZ = 1;
  Size screenSize;
  FocusNode keyboardFocusNode;
  Timer updateTimer;

  @override
  void initState() {
    updateTimer = Timer.periodic(Duration(milliseconds: 1000 ~/ widget.fps), (timer) {
      widget.fixedUpdate();
      setState(_doNothing);
    });
    keyboardFocusNode = FocusNode();
    widget.init();
    super.initState();
  }

  void _doNothing(){

  }

  @override
  Widget build(BuildContext context) {

    if (!keyboardFocusNode.hasFocus) {
      FocusScope.of(context).requestFocus(keyboardFocusNode);
    }

    return MaterialApp(
      title: widget.title,
      theme: ThemeData(
        primarySwatch: mat.Colors.orange,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: RawKeyboardListener(
        focusNode: keyboardFocusNode,
        onKey: (key) {
          // game.handleKeyPressed(key);
        },
        child: Scaffold(
          // appBar: game.buildAppBar(context),
          body: Builder(
            builder: (context){
              screenSize = MediaQuery.of(context).size;
              return Stack(
                children: [
                  buildBody(context),
                  // widget.build(context),
                ],
              );
            },
          ),
        ),
      ),
      debugShowCheckedModeBanner: false,
    );
  }

  Widget buildBody(BuildContext context) {
    return MouseRegion(
      onHover: (PointerHoverEvent pointerHoverEvent){
        _previousMousePosition = _mousePosition;
        _mousePosition = pointerHoverEvent.position;
        _mouseDelta = pointerHoverEvent.delta;
      },
      child: PositionedTapDetector(
        onTap: (position) {
          _lastLeftClicked = DateTime.now();
          // game.handleMouseClicked(position.relative);
        },
        child: Listener(
          onPointerSignal: (pointerSignalEvent) {
            if (pointerSignalEvent is PointerScrollEvent) {
              // game.handleMouseScroll(pointerSignalEvent.scrollDelta.dy);

            }else{
              print("unhandled pointer signal event $pointerSignalEvent");
            }
          },
          child: Container(
            color: widget.backgroundColor,
            width: screenSize.width,
            height: screenSize.height,
            child: CustomPaint(
              size: screenSize,
              painter: GameUIPainter(paintGame: widget.draw),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    updateTimer.cancel();
    keyboardFocusNode.dispose();
  }
}

class GameUIPainter extends CustomPainter {

  final PaintGame paintGame;

  GameUIPainter({this.paintGame});

  @override
  void paint(Canvas canvas, Size size) {
    paintGame(canvas, size);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
