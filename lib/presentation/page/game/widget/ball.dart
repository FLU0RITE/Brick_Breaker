
import 'package:break_brick/presentation/page/game/widget/play_area.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flame/collisions.dart';
import 'package:flame/effects.dart';

import '../brick_breaker.dart';

import 'brick.dart';

class Ball extends CircleComponent
    with CollisionCallbacks, HasGameReference<BrickBreaker> {
  Ball({
    required this.velocity,
    required super.position,
    required double radius,
    required this.difficultyModifier,
    this.isInitialBall = false,
  }) : super(
         radius: radius,
         anchor: Anchor.center,
         paint:
             Paint()
               ..color = const Color(0xff1e6091)
               ..style = PaintingStyle.fill,
         children: [CircleHitbox()],
       );

  final Vector2 velocity;
  final double difficultyModifier;
  final bool isInitialBall; // 새로 추가된 속성

  @override
  void update(double dt) {
    super.update(dt);
    position += velocity * dt;
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is PlayArea) {
      if (intersectionPoints.first.y <= 0) {
        velocity.y = -velocity.y;
      } else if (intersectionPoints.first.x <= 0) {
        velocity.x = -velocity.x;
      } else if (intersectionPoints.first.x >= game.width) {
        velocity.x = -velocity.x;
      } else if (intersectionPoints.first.y >= game.height) {
        // 공의 속도를 0으로 설정하여 멈춥니다.
        velocity.setFrom(Vector2.zero());

        // BrickBreaker에 공 회수를 알립니다.
        game.onBallReturned(this); // Ball 객체 자체를 전달

        // 이 공이 첫 공이 아니라면 스스로 제거됩니다. (onBallReturned 내부 로직에서 처리)
        return;

      }
    }else if (other is Brick) {
      if (position.y < other.position.y - other.size.y / 2) {
        velocity.y = -velocity.y;
      } else if (position.y > other.position.y + other.size.y / 2) {
        velocity.y = -velocity.y;
      } else if (position.x < other.position.x) {
        velocity.x = -velocity.x;
      } else if (position.x > other.position.x) {
        velocity.x = -velocity.x;
      }
      velocity.setFrom(velocity * difficultyModifier);
    }
  }
}
