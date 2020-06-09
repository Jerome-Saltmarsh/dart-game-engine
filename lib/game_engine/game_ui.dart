import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:onlinepainter/game_engine/game.dart';
import 'package:positioned_tap_detector/positioned_tap_detector.dart';

class GameUI extends StatefulWidget {
  final int fps;
  final Game game;

  GameUI({@required this.game, this.fps = 60});

  @override
  _GameUIState createState() => _GameUIState();
}


class _GameUIState extends State<GameUI> {

  bool initialized = false;
  FocusNode keyboardFocusNode;
  Size screenSize;
  Game get game => widget.game;

  @override
  void initState() {
    Timer.periodic(Duration(milliseconds: 1000 ~/ widget.fps), (timer) {
      fixedUpdate();
    });
    keyboardFocusNode = FocusNode();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    game.context = context;
    screenSize = MediaQuery.of(context).size;
    game.screenSize = screenSize;

    if (!initialized) {
      initialized = true;
      game.init();
    }
    if (!keyboardFocusNode.hasFocus) {
      FocusScope.of(context).requestFocus(keyboardFocusNode);
    }

    return RawKeyboardListener(
      focusNode: keyboardFocusNode,
      onKey: (key) {
        game.handleKeyPressed(key);
      },
      child: Scaffold(
        appBar: game.buildAppBar(context),
        body: Stack(
          children: [
            buildBody(context),
            ...game.buildUI(context),
          ],
        ),
      ),
    );
  }

  void fixedUpdate() {
    game.update();
    setState(doNothing);
  }

  void doNothing() {
    // prevents creating a new lambda each frame.
  }

  @override
  void dispose() {
    game.dispose();
    super.dispose();
  }

  Widget buildBody(BuildContext context) {
    return MouseRegion(
      onHover: game.handlePointerHoverEvent,
      child: PositionedTapDetector(
        onTap: (position) {
          game.handleMouseClicked(position.relative);
        },
        child: Listener(
          onPointerSignal: (pointerSignalEvent) {
            if (pointerSignalEvent is PointerScrollEvent) {
              game.handleMouseScroll(pointerSignalEvent.scrollDelta.dy);
            }else{
              print("unhandled pointer signal event $pointerSignalEvent");
            }
          },
          child: Container(
            color: game.backgroundColor,
            width: screenSize.width,
            height: screenSize.height,
            child: CustomPaint(
              size: screenSize,
              painter: GameUIPainter(game),
            ),
          ),
        ),
      ),
    );
  }
}

class GameUIPainter extends CustomPainter {

  Game game;

  GameUIPainter(this.game);

  @override
  void paint(Canvas canvas, Size size) {
    game.draw(canvas, size);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
