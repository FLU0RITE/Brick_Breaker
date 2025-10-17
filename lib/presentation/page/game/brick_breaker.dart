import 'dart:async';
import 'dart:math' as math;

import 'package:break_brick/presentation/page/game/widget/launch_guide.dart';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flame/game.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'config.dart';
import 'components.dart';

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

  final double ballSpawnDelay = 0.1; // 공이 순차적으로 발사되는 시간 간격 (초)

  double get width => size.x;
  double get height => size.y;

  late PlayState _playState;
  PlayState get playState => _playState;

  // 턴 상태 관리 변수 (Riverpod 사용 시 대체 가능)
  int _returnedBalls = 0;
  int _currentBallCount = 1; // 스와이프 벽돌깨기에서는 이 값이 증가합니다.
  final ValueNotifier<int> turnNumber = ValueNotifier(1);

  late List<int> randomNums = generateUniqueRandomNumbers();

  // 첫 공이 돌아올 위치 (기준 위치) - 게임 시작 시 초기화
  Vector2 _returnPosition = Vector2(gameWidth / 2, gameHeight - ballRadius);

  // 1. 공 회수 시 BallComponent에서 호출할 메서드 (수정됨)
  void onBallReturned(Ball ball) {
    _returnedBalls++;

    // ⭐️ 첫 번째로 돌아온 공의 위치를 다음 턴의 발사 위치로 저장합니다.
    if (_returnedBalls == 1) {
      // ball.position을 저장하면 회수 벽(PlayArea)에 닿은 Y 좌표로 저장되므로,
      // 발사할 공의 위치를 맞추기 위해 Y 좌표는 화면 하단으로 고정하고 X 좌표만 사용합니다.
      _returnPosition.x = ball.position.x;
      _returnPosition.y = height - ballRadius;

      // ⭐️ 첫 공만 위치를 회수 위치로 고정하고 속도를 0으로 설정합니다.
      ball.velocity.setFrom(Vector2.zero());
      ball.position.setFrom(_returnPosition);
    } else {
      // 첫 공이 아닌 나머지 공들은 제거합니다.
      ball.removeFromParent();
    }

    // 현재 턴의 모든 공이 회수되었는지 확인
    if (_returnedBalls >= _currentBallCount) {
      endTurn();
    }
  }

  // 2. 턴 종료 및 벽돌 이동/생성 로직 (수정됨)
  void endTurn() {
    // 1. 벽돌 내리기 및 게임 오버 체크
    final existingBricks = world.children.query<Brick>();
    bool gameOver = false;

    for (var brick in existingBricks) {
      brick.position.y += brickHeight + brickGutter;

      if (brick.position.y >= height - (brickHeight * 1.5)) {
        gameOver = true;
        break;
      }
    }

    if (gameOver) {
      playState = PlayState.gameOver;
      return;
    }

    // 2. 새 벽돌 생성 및 턴 상태 업데이트
    turnNumber.value++;
    // ⭐️ 턴이 끝날 때마다 발사할 공 개수를 1 증가시킵니다.
    _currentBallCount++;

    // 새 벽돌 추가 (화면 최상단에 새로운 줄의 벽돌을 추가합니다.)

    randomNums = generateUniqueRandomNumbers();
    world.addAll([
      for (var i = 0; i < randomNums.length; i++)
        Brick(
          position: Vector2(
            (randomNums[i] + 0.5) * brickWidth + (randomNums[i] + 1) * brickGutter,
            (1.0) * brickHeight + 1 * brickGutter,
          ),
          neonColor1: Colors.white,
          neonColor2: Colors.black,
          durability: ValueNotifier(_currentBallCount),
        ),
    ]);

    // 3. 다음 턴 준비 완료
    _returnedBalls = 0; // 카운터 초기화
    _canLaunch = true; // 다음 발사 허용

    // 첫 공의 위치를 확정된 _returnPosition으로 이동시킵니다.
    final initialBall =
        world.children.query<Ball>().where((b) => b.isInitialBall).firstOrNull;
    if (initialBall != null) {
      initialBall.position.setFrom(_returnPosition);
    }

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
    turnNumber.value = 1;
    _canLaunch = true;
    _currentBallCount = 1;

    playState = PlayState.playing;
    score.value = 0;

    // 1. 첫 공 생성 및 _returnPosition 설정
    final initialBall = Ball(
      isInitialBall: true,
      // 첫 공으로 표
      difficultyModifier: difficultyModifier,
      radius: ballRadius,
      position: Vector2(width / 2, height - ballRadius),
      // 화면 바닥 근처
      velocity: Vector2(0, 0),
    );
    world.add(initialBall);
    _returnPosition = initialBall.position.clone(); // 첫 공의 위치를 회수 기준으로 설정

    // 2. 초기 벽돌 배치 (요청에 따라 1줄만 배치하도록 간소화)
    randomNums = generateUniqueRandomNumbers();
    world.addAll([
      for (var i = 0; i < randomNums.length; i++)
        Brick(
          position: Vector2(
            (randomNums[i] + 0.5) * brickWidth + (randomNums[i] + 1) * brickGutter,
            (1.0) * brickHeight + 1 * brickGutter,
          ),
          neonColor1: Colors.white,
          neonColor2: Colors.black,
          durability: ValueNotifier(_currentBallCount),
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

  List<int> generateUniqueRandomNumbers() {
    final random = math.Random();

    // 1. 리스트의 개수(N)를 랜덤으로 결정 (1부터 6까지)
    // nextInt(6)은 0~5를 반환하므로, +1을 더해 1~6 범위를 만듭니다.
    final int count = random.nextInt(6) + 1;

    // 2. 가능한 전체 숫자 범위 (1, 2, 3, 4, 5, 6)를 가진 리스트를 생성합니다.
    List<int> availableNumbers = List.generate(6, (index) => index);

    // 3. 리스트를 무작위로 섞습니다. (중복 없이 뽑는 핵심 로직)
    availableNumbers.shuffle(random);

    // 4. 결정된 개수(count)만큼 리스트의 앞에서부터 잘라내어 반환합니다.
    // sublist(0, count)는 인덱스 0부터 count-1까지의 요소를 추출합니다.
    return availableNumbers.sublist(0, count);
  }

  // 6. onDragEnd 수정 (위치 차이를 이용한 발사 방향 결정, 속도 무시)
  @override
  void onDragEnd(DragEndEvent event) {
    event.handled = true;

    if (_dragStartPosition == null ||
        _dragLastPosition == null ||
        playState != PlayState.playing ||
        !_canLaunch) {
      _dragStartPosition = null;
      _dragLastPosition = null;
      _guide?.removeFromParent(); // 가이드 제거
      return;
    }

    // 드래그 방향 벡터 계산 (시작점 - 끝점)
    final dragVector = _dragLastPosition! - _dragStartPosition!;

    const double minDragLength = 20.0; // 최소 드래그 길이 (추측한 내용입니다)

    // Y 축이 음수일 때(위로 스와이프) && 최소 길이 충족 시 발사
    if (dragVector.length > minDragLength && dragVector.y < 0) {
      // 발사: 정규화된 방향 벡터만 전달 (스와이프 속도 무시)
      _launchBalls(dragVector.normalized());

      _canLaunch = true;
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

  // 7. _launchBalls 수정 (공 발사 시점 - 멀티볼 발사 로직 추가)
  void _launchBalls(Vector2 direction) {
    // 1. 발사 속도 벡터 계산
    // ⭐️ 최소 발사 속도를 보장하기 위해 direction 벡터를 정규화하여 사용합니다.
    final normalizedDirection = direction.normalized();

    // final launchVelocity = direction * ballSpeed; // 이 대신 정규화된 벡터 사용
    final launchVelocity = normalizedDirection * ballSpeed;

    // 참고: normalizedDirection는 이미 길이가 1이므로, ballSpeed는 공이 가질 최대 속도가 됩니다.

    // 2. 첫 공 (isInitialBall=true)을 찾아 속도를 변경하여 발사합니다.
    final initialBall =
        world.children.query<Ball>().where((b) => b.isInitialBall).firstOrNull;

    if (initialBall != null) {
      // ⭐️ 첫 공 발사
      initialBall.velocity.setFrom(launchVelocity);
    }

    // 3. 나머지 공들은 순차적으로 생성 및 발사합니다. (Async 지연 로직)
    if (_currentBallCount > 1) {
      for (int i = 1; i < _currentBallCount; i++) {
        // 공 발사 간격만큼 지연
        Future.delayed(
          Duration(milliseconds: (ballSpawnDelay * 300 * i).toInt()),
          () {
            // ⭐️ 다음 공 생성 (isInitialBall=false)
            final newBall = Ball(
              isInitialBall: false,
              difficultyModifier: difficultyModifier,
              radius: ballRadius,
              position: _returnPosition.clone(),
              // _returnPosition에서 생성
              velocity: launchVelocity.clone(), // 동일한 속도로 발사
            );
            world.add(newBall);
          },
        );
      }
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
