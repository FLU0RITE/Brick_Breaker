// equatable이 설치되었다고 가정합니다.
import 'package:equatable/equatable.dart';

class TurnState extends Equatable {
  // 현재 턴의 번호 (새 벽돌을 몇 번 내렸는지)
  final int turnNumber;
  // 현재 발사할 수 있는 공의 개수
  final int currentBallCount;
  // 현재 턴에 파괴된 벽돌들의 ID (멀티플레이 동기화용)
  final List<String> destroyedBrickIds;
  // 현재 턴의 점수
  final int score;
  // 게임이 진행 중인지 (공이 모두 회수되지 않았는지)
  final bool isTurnInProgress;

  const TurnState({
    this.turnNumber = 0,
    this.currentBallCount = 1,
    this.destroyedBrickIds = const [],
    this.score = 0,
    this.isTurnInProgress = false,
  });

  TurnState copyWith({
    int? turnNumber,
    int? currentBallCount,
    List<String>? destroyedBrickIds,
    int? score,
    bool? isTurnInProgress,
  }) {
    return TurnState(
      turnNumber: turnNumber ?? this.turnNumber,
      currentBallCount: currentBallCount ?? this.currentBallCount,
      destroyedBrickIds: destroyedBrickIds ?? this.destroyedBrickIds,
      score: score ?? this.score,
      isTurnInProgress: isTurnInProgress ?? this.isTurnInProgress,
    );
  }

  @override
  List<Object?> get props => [turnNumber, currentBallCount, destroyedBrickIds, score, isTurnInProgress];
}