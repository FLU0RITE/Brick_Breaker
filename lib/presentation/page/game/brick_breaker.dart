import 'dart:async';
import 'dart:math' as math;

import 'package:break_brick/presentation/page/game/widget/launch_guide.dart';
import 'package:break_brick/presentation/page/game/widget/wall.dart';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flame/game.dart';
import 'package:flame/events.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../controller/game/game_view_model.dart';
import 'config.dart';
import 'components.dart';

class BrickBreaker extends FlameGame
    with HasCollisionDetection, KeyboardEvents, TapCallbacks, DragCallbacks {
  final GameViewModel viewModel;

  GameState get gameState => viewModel.state;

  BrickBreaker({required this.viewModel})
    : super(
        camera: CameraComponent.withFixedResolution(
          width: gameWidth,
          height: gameHeight,
        ),
      );

  Vector2? _dragStartPosition;
  Vector2? _dragLastPosition;
  LaunchGuide? _guide;

  @override
  FutureOr<void> onLoad() async {
    super.onLoad();
    camera.viewfinder.anchor = Anchor.topLeft;

    world.addAll([
      _createWall(Vector2(0, 0), Vector2(gameWidth, 1)),
      _createWall(Vector2(0, gameHeight - 1), Vector2(gameWidth, 1)),
      _createWall(Vector2(0, 0), Vector2(1, gameHeight)),
      _createWall(Vector2(gameWidth - 1, 0), Vector2(1, gameHeight)),
    ]);

    _spawnInitialBall(gameState.returnPosition);
    _spawnBricks();
    _handlePlayStateChange(gameState.playState);
  }

  Wall _createWall(Vector2 position, Vector2 size) {
    return Wall(position: position, size: size);
  }

  void onBallReturned(Ball ball) {
    viewModel.onBallReturned(ball.position);
    debugPrint("볼 돌아옴");
    if (gameState.returnedBalls == 1) {
      ball.velocity.setFrom(Vector2.zero());
      ball.position.setFrom(gameState.returnPosition);
    } else {
      ball.removeFromParent();
    }

    if (gameState.returnedBalls >= gameState.currentBallCount) {
      _endTurnFlameLogic();
    }
  }

  void _endTurnFlameLogic() {
    final existingBricks = world.children.query<Brick>();
    bool gameOver = false;
    for (var brick in existingBricks) {
      brick.position.y += brickHeight + brickGutter;
      if (brick.position.y >= gameHeight - (brickHeight * 1.5)) {
        gameOver = true;
        break;
      }
    }
    viewModel.finalizeTurn(isGameOver: gameOver);
    if (!gameOver) {
      _respawnObjectsForNextTurn();
    }
    _handlePlayStateChange(gameState.playState);
  }

  void _respawnObjectsForNextTurn() {
    _spawnBricks();
    _updateInitialBallPosition(gameState.returnPosition);
  }

  void startGame() {
    if (gameState.playState == PlayState.playing) return;
    viewModel.startGame();
    world.removeAll(world.children.query<Ball>());
    world.removeAll(world.children.query<Brick>());
    _spawnInitialBall(gameState.returnPosition);
    _spawnBricks();
    _handlePlayStateChange(gameState.playState);
  }

  void _spawnInitialBall(Vector2 position) {
    final initialBall = Ball(
      isInitialBall: true,
      radius: ballRadius,
      position: position.clone(),
      velocity: Vector2(0, 0),
    );
    world.add(initialBall);
  }

  void _spawnBricks() {
    final randomNums = gameState.randomBrickNumbers;
    world.addAll([
      for (var i = 0; i < randomNums.length; i++)
        Brick(
          position: Vector2(
            (randomNums[i] + 0.5) * brickWidth +
                (randomNums[i] + 1) * brickGutter,
            (1.0) * brickHeight + 1 * brickGutter,
          ),
          neonColor1: Colors.white,
          neonColor2: Colors.black,
          durability: ValueNotifier(gameState.turnNumber),
        ),
    ]);
    // TODO: (멀티 플레이) 이 시점에 Firestore에 파괴된 벽돌 목록을 기록합니다.
  }

  void _updateInitialBallPosition(Vector2 returnPosition) {
    final initialBall =
        world.children.query<Ball>().where((b) => b.isInitialBall).firstOrNull;
    if (initialBall != null) {
      initialBall.position.setFrom(returnPosition);
      viewModel.setCanLaunch(true);
    }
  }

  void _handlePlayStateChange(PlayState playState) {
    switch (playState) {
      case PlayState.welcome:
      case PlayState.gameOver:
      case PlayState.won:
        overlays.add(playState.name);
      case PlayState.playing:
        overlays.remove(PlayState.welcome.name);
        overlays.remove(PlayState.gameOver.name);
        overlays.remove(PlayState.won.name);
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);
    startGame();
  }

  @override
  void onDragStart(DragStartEvent event) {
    event.handled = true;
    if (gameState.playState != PlayState.playing || !gameState.canLaunch)
      return;
    _dragStartPosition = event.canvasPosition;
    _guide = LaunchGuide(position: gameState.returnPosition);
    world.add(_guide!);
  }

  @override
  void onDragEnd(DragEndEvent event) {
    event.handled = true;
    if (_dragStartPosition == null ||
        _dragLastPosition == null ||
        gameState.playState != PlayState.playing ||
        !gameState.canLaunch) {
      _dragStartPosition = null;
      _dragLastPosition = null;
      _guide?.removeFromParent(); // 가이드 제거
      return;
    }
    final dragVector = _dragLastPosition! - _dragStartPosition!;
    const double minDragLength = 20.0;
    if (dragVector.length > minDragLength && dragVector.y < 0) {
      _launchBalls(dragVector.normalized());
      viewModel.setCanLaunch(true);
    }
    _guide?.removeFromParent();
    _guide = null;
    _dragStartPosition = null;
    _dragLastPosition = null;
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    event.handled = true;
    if (_dragStartPosition == null || !gameState.canLaunch) return;

    _dragLastPosition = event.canvasEndPosition;

    Vector2 dragVector = _dragStartPosition! - _dragLastPosition!;

    _guide?.updateDirection(dragVector);
  }

  void _launchBalls(Vector2 direction) {
    final normalizedDirection = direction.normalized();
    final launchVelocity = normalizedDirection * ballSpeed;
    final currentBallCount = gameState.currentBallCount;
    final initialBall =
        world.children.query<Ball>().where((b) => b.isInitialBall).firstOrNull;

    if (initialBall != null) {
      initialBall.velocity.setFrom(launchVelocity);
      debugPrint("이니셜볼이 널아님");
      debugPrint(initialBall.toString());
    }
    if (initialBall == null) {
      debugPrint("이니셜볼이 널");
    }
    if (currentBallCount > 1) {
      for (int i = 1; i < currentBallCount; i++) {
        Future.delayed(
          Duration(milliseconds: (ballSpawnDelay * 300 * i).toInt()),
          () {
            final newBall = Ball(
              isInitialBall: false,
              radius: ballRadius,
              position: gameState.returnPosition.clone(),
              velocity: launchVelocity.clone(),
            );
            world.add(newBall);
          },
        );
      }
    }
    debugPrint("런치 됨");
  }

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    super.onKeyEvent(event, keysPressed);
    switch (event.logicalKey) {
      case LogicalKeyboardKey.space:
      case LogicalKeyboardKey.enter:
        startGame();
    }
    return KeyEventResult.handled;
  }

  @override
  Color backgroundColor() => const Color(0xff000000);
}
