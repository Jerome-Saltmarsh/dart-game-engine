import 'dart:async';
import 'dart:math';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart' as mat;
import 'package:positioned_tap_detector/positioned_tap_detector.dart';
import 'package:vector_math/vector_math.dart';

typedef PaintGame = Function(Canvas canvas, Size size);

abstract class GameUI extends StatefulWidget {

  final int fps;
  final Color backgroundColor;
  final String title;

  void fixedUpdate();
  void draw(Canvas canvas, Size size);

  GameUI({this.fps = 60, this.backgroundColor = mat.Colors.green, this.title = 'demo'});

  @override
  _GameUIState createState() => _GameUIState();
}


class _GameUIState extends State<GameUI> {

  // variables
  double minZoom = 0.005;
  Offset mousePosition;
  Offset previousMousePosition;
  Offset mouseDelta;
  double cameraZ = 1;
  Size screenSize;
  bool initialized = false;
  FocusNode keyboardFocusNode;

  final Random random = Random();
  final Vector2 zero = Vector2.zero();

  @override
  void initState() {
    Timer.periodic(Duration(milliseconds: 1000 ~/ widget.fps), (timer) {
      // fixedUpdate();
      widget.fixedUpdate();
      setState(_doNothing);
    });
    keyboardFocusNode = FocusNode();
    super.initState();
  }

  void _doNothing(){

  }

  @override
  Widget build(BuildContext context) {
    // game.screenSize = screenSize;

    if (!initialized) {
      initialized = true;
      // game.init();
    }
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
                  // ...game.buildUI(context),
                ],
              );
            },
          ),
        ),
      ),
      debugShowCheckedModeBanner: false,
    );
  }

  @override
  void dispose() {
    // game.dispose();
    super.dispose();
  }

  Widget buildBody(BuildContext context) {
    print("buildBody()");

    return MouseRegion(
      onHover: handlePointerHoverEvent,
      child: PositionedTapDetector(
        onTap: (position) {
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

  void handlePointerHoverEvent(PointerHoverEvent pointerHoverEvent) {
    previousMousePosition = mousePosition;
    mousePosition = pointerHoverEvent.position;
    mouseDelta = pointerHoverEvent.delta;
    // handleMouseMovement();
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
