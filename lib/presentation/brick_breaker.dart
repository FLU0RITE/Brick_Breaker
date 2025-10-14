import 'dart:async';
import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config.dart';
import '../components/components.dart';
import '../components/launch_guide.dart';

enum PlayState { welcome, playing, gameOver, won }

class BrickBreaker extends FlameGame
    with HasCollisionDetection, KeyboardEvents, TapDetector, DragCallbacks {
  BrickBreaker()
    : super(
        camera: CameraComponent.withFixedResolution(
          width: gameWidth,
          height: gameHeight,
        ),
      );

  final ValueNotifier<int> score = ValueNotifier(0);
  final rand = math.Random();

  double get width => size.x;

  double get height => size.y;

  late PlayState _playState;

  PlayState get playState => _playState;

  // 턴 상태 관리 변수 (Riverpod 사용 시 대체 가능)
  int _returnedBalls = 0;
  int _currentBallCount = 1; // 스와이프 벽돌깨기에서는 이 값이 증가합니다.
  int _turnNumber = 0;

  // 1. 공 회수 시 BallComponent에서 호출할 메서드 (수정됨)
  void onBallReturned(Ball ball) {
    _returnedBalls++;

    // 첫 번째 공이 아닌 경우에만 제거합니다.
    if (!ball.isInitialBall) {
      ball.removeFromParent();
    } else {
      // 첫 번째 공은 위치를 회수 위치로 고정하고 속도를 0으로 설정합니다.
      ball.velocity.setFrom(Vector2.zero());
      ball.position.setFrom(_returnPosition);
    }

    // 현재 턴의 모든 공이 회수되었는지 확인
    if (_returnedBalls >= _currentBallCount) {
      endTurn();
    }
  }
// 2. 턴 종료 및 벽돌 이동/생성 로직
  void endTurn() {
    // 1. 벽돌 내리기 및 게임 오버 체크
    final existingBricks = world.children.query<Brick>();
    bool gameOver = false;

    for (var brick in existingBricks) {
      // 벽돌을 한 칸 내립니다. (Config.dart의 brickHeight 및 brickGutter 사용)
      brick.position.y += brickHeight + brickGutter;
      // TODO: brick.increaseDurability(); (Brick 클래스에 로직 추가 필요)

      // 벽돌이 발사선(화면 하단)에 도달했는지 확인
      if (brick.position.y >= height - (brickHeight * 1.5)) {
        gameOver = true;
        break;
      }
    }

    if (gameOver) {
      playState = PlayState.gameOver;
      return;
    }

    // 2. 새 벽돌 생성 (턴 번호 증가)
    _turnNumber++;
    // TODO: 파괴된 벽돌 수에 따라 _currentBallCount 업데이트 로직 추가

    // 새 벽돌 추가 (기존 startGame의 벽돌 생성 로직을 재활용/수정)
    // 화면 최상단에 새로운 줄의 벽돌을 추가합니다.
    world.addAll([
      for (var i = 0; i < brickColors.length; i++)
      // 새 벽돌은 Y 좌표를 초기 벽돌보다 위에 배치합니다. (예: 1.0 * brickHeight)
        Brick(
          position: Vector2(
            (i + 0.5) * brickWidth + (i + 1) * brickGutter,
            (1.0) * brickHeight + 1 * brickGutter,
          ),
          color: brickColors[rand.nextInt(brickColors.length)],
        ),
    ]);

    // 3. 다음 턴 준비 완료
    _returnedBalls = 0; // 카운터 초기화
    _canLaunch = true; // 다음 발사 허용

    // TODO: (멀티 플레이) 이 시점에 Firestore에 파괴된 벽돌 목록을 기록합니다.
  }

  set playState(PlayState playState) {
    _playState = playState;
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
  FutureOr<void> onLoad() async {
    super.onLoad();

    camera.viewfinder.anchor = Anchor.topLeft;

    world.add(PlayArea());

    playState = PlayState.welcome;
  }

  void startGame() {
    if (playState == PlayState.playing) return;

    world.removeAll(world.children.query<Ball>());
    world.removeAll(world.children.query<Brick>());
    _returnedBalls = 0;
    _turnNumber = 0;
    _canLaunch = true;

    playState = PlayState.playing;
    score.value = 0;

    // 1. 첫 공 생성 및 _returnPosition 설정
    final initialBall = Ball(
      isInitialBall: true, // 첫 공으로 표
      difficultyModifier: difficultyModifier,
      radius: ballRadius,
      position: Vector2(width/2, height - ballRadius), // 화면 바닥 근처
      velocity: Vector2(0,0),

    );
    world.add(initialBall);
    _returnPosition = initialBall.position.clone(); // 첫 공의 위치를 회수 기준으로 설정

    // 2. 초기 벽돌 배치 (요청에 따라 1줄만 배치하도록 간소화)
    world.addAll([
      for (var i = 0; i < brickColors.length; i++)
        Brick(
          position: Vector2(
            (i + 0.5) * brickWidth + (i + 1) * brickGutter,
            (1.0) * brickHeight + 1 * brickGutter,
          ),
          color: brickColors[rand.nextInt(brickColors.length)], // 랜덤 색상
        ),
    ]);
  }


  @override
  void onTap() {
    super.onTap();
    startGame();
  }

  // 발사 로직을 위한 변수 수정
  Vector2? _dragStartPosition;
  Vector2? _dragLastPosition; // 드래그 업데이트 시 마지막 위치 추적
  bool _canLaunch = true;

  LaunchGuide? _guide; // 발사 가이드 라인 컴포넌트

  // 첫 공이 돌아올 위치 (기준 위치)
  Vector2 _returnPosition = Vector2(gameWidth / 2, gameHeight - ballRadius);


  @override
  void onDragStart(DragStartEvent event) {
    event.handled = true;
    if (playState != PlayState.playing || !_canLaunch) return;

    // 캔버스 좌표를 월드 좌표로 변환하여 시작 위치 기록 (표준 방식)
    _dragStartPosition = event.canvasPosition;

    // 발사 가이드라인 생성 및 추가
    _guide = LaunchGuide(position: _returnPosition);
    world.add(_guide!);
  }
  // 6. onDragEnd 수정 (위치 차이를 이용한 발사 방향 결정, 속도 무시)
  @override
  void onDragEnd(DragEndEvent event) {
    event.handled = true;

    if (_dragStartPosition == null || _dragLastPosition == null || playState != PlayState.playing || !_canLaunch) {
      _dragStartPosition = null;
      _dragLastPosition = null;
      _guide?.removeFromParent(); // 가이드 제거
      return;
    }

    // 드래그 방향 벡터 계산 (시작점 - 끝점)
    final dragVector = _dragStartPosition! - _dragLastPosition!;

    const double minDragLength = 20.0; // 최소 드래그 길이 (추측한 내용입니다)

    // Y 축이 음수일 때(위로 스와이프) && 최소 길이 충족 시 발사
    if (dragVector.length > minDragLength && dragVector.y < 0) {
      // 발사: 정규화된 방향 벡터만 전달 (스와이프 속도 무시)
      _launchBalls(dragVector.normalized());

      _canLaunch = false;
    }

    // 가이드라인 제거
    _guide?.removeFromParent();
    _guide = null;

    _dragStartPosition = null;
    _dragLastPosition = null;
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    event.handled = true;
    if (_dragStartPosition == null || !_canLaunch) return;

    // 현재 위치를 월드 좌표로 변환하여 기록
    _dragLastPosition = event.canvasEndPosition;

    // 드래그 방향 벡터 계산 (시작점 - 현재점)
    Vector2 dragVector = _dragStartPosition! - _dragLastPosition!;

    // 가이드라인 업데이트 (최대 길이 제한 적용)
    _guide?.updateDirection(dragVector);
  }

  // 7. _launchBalls 수정 (공 발사 시점)
  void _launchBalls(Vector2 direction) {
    // 1. 첫 공 (isInitialBall=true)의 속도만 변경하여 발사합니다.
    final initialBall = world.children.query<Ball>().where((b) => b.isInitialBall).firstOrNull;

    if (initialBall != null) {
      final launchVelocity = direction * ballSpeed; // ballSpeed는 config.dart에 정의되었다고 가정
      initialBall.velocity.setFrom(launchVelocity);

      // TODO: 멀티볼 로직 (for문으로 _currentBallCount만큼 공 추가 생성 및 발사) 추가 필요
      // ...
    }
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
  Color backgroundColor() => const Color(0xfff2e8cf);
}
