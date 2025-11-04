import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../page/game/config.dart';

enum PlayState { welcome, playing, gameOver, won }

class GameState {
  final int turnNumber;
  final int returnedBalls;
  final int currentBallCount;
  final int score;
  final PlayState playState;
  final Vector2 returnPosition;
  final List<int> randomBrickNumbers;
  final bool canLaunch;

  GameState({
    required this.returnedBalls,
    required this.currentBallCount,
    required this.score,
    required this.playState,
    required this.returnPosition,
    required this.randomBrickNumbers,
    required this.canLaunch,
    required this.turnNumber,
  });

  GameState copyWith({
    int? score,
    int? turnNumber,
    int? currentBallCount,
    PlayState? playState,
    int? returnedBalls,
    Vector2? returnPosition,
    bool? canLaunch,
    List<int>? randomBrickNumbers,
  }) {
    return GameState(
      score: score ?? this.score,
      turnNumber: turnNumber ?? this.turnNumber,
      currentBallCount: currentBallCount ?? this.currentBallCount,
      playState: playState ?? this.playState,
      returnedBalls: returnedBalls ?? this.returnedBalls,
      returnPosition: returnPosition ?? this.returnPosition,
      canLaunch: canLaunch ?? this.canLaunch,
      randomBrickNumbers: randomBrickNumbers ?? this.randomBrickNumbers,
    );
  }
}

class GameViewModel extends StateNotifier<GameState> {
  GameViewModel() : super(_initialState);
  final math.Random _random = math.Random();
  static final Vector2 _initialReturnPosition = Vector2(
    gameWidth / 2,
    gameHeight - ballRadius,
  );

  static final GameState _initialState = GameState(
    returnedBalls: 0,
    currentBallCount: 1,
    score: 0,
    playState: PlayState.welcome,
    returnPosition: _initialReturnPosition,
    randomBrickNumbers: [],
    canLaunch: true,
    turnNumber: 1,
  );

  void setPlayState(playState) {
    state = state.copyWith(playState: playState);
  }

  void startGame() {
    if (state.playState == PlayState.playing) return;
    final initialBricks = generateUniqueRandomNumbers();
    state = _initialState.copyWith(
      playState: PlayState.playing,
      randomBrickNumbers: initialBricks,
      returnPosition: _initialReturnPosition.clone(),
      canLaunch: true,
    );
  }

  void onBallReturned(Vector2 ballPosition) {
    final newReturnedBalls = state.returnedBalls + 1;
    if (newReturnedBalls == 1) {
      final newReturnPosition = Vector2(
        ballPosition.x,
        gameHeight - ballRadius,
      );
      state = state.copyWith(
        returnedBalls: newReturnedBalls,
        returnPosition: newReturnPosition,
      );
    } else {
      state = state.copyWith(returnedBalls: newReturnedBalls);
    }
  }

  void setCanLaunch(bool value) {
    state = state.copyWith(canLaunch: value);
  }

  void finalizeTurn({required bool isGameOver}) {
    if (isGameOver) {
      state = state.copyWith(playState: PlayState.gameOver);
      return;
    }

    final newRandomNumbers = generateUniqueRandomNumbers();

    state = state.copyWith(
      turnNumber: state.turnNumber + 1,
      currentBallCount: state.currentBallCount + 1,
      returnedBalls: 0,
      canLaunch: true,
      randomBrickNumbers: newRandomNumbers,
    );
  }

  void increaseScore(int points) {
    state = state.copyWith(score: state.score + points);
  }

  List<int> generateUniqueRandomNumbers() {
    final int count = _random.nextInt(6) + 1;
    List<int> availableNumbers = List.generate(6, (index) => index);
    availableNumbers.shuffle(_random);
    return availableNumbers.sublist(0, count);
  }
}

final gameViewModelProvider = StateNotifierProvider<GameViewModel, GameState>((
  ref,
) {
  return GameViewModel();
});
