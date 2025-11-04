import 'package:break_brick/presentation/page/game/widget/wall.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flame/collisions.dart';

import '../brick_breaker.dart';

import 'brick.dart';

class Ball extends CircleComponent
    with CollisionCallbacks, HasGameReference<BrickBreaker> {
  Ball({
    required this.velocity,
    required super.position,
    required double radius,
    this.isInitialBall = false,
  }) : super(
         radius: radius,
         anchor: Anchor.center,
         paint:
             Paint()
               ..color = const Color(0xfffbfbfb)
               ..style = PaintingStyle.fill,
         children: [CircleHitbox()],
       );

  final Vector2 velocity;
  final bool isInitialBall;

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
    if (other is Wall) {
      if (other.position.y >= game.size.y - 1 && velocity.y > 0) {
        velocity.setFrom(Vector2.zero());
        game.onBallReturned(this);
      } else {
        if (position.y - radius <= 0) {
          velocity.y = -velocity.y;
        }
        if (position.x - radius <= 0 || position.x + radius >= game.size.x) {
          velocity.x = -velocity.x;
        }
      }
    } else if (other is Brick) {
      debugPrint("충돌");
      if (position.y < other.position.y - other.size.y / 2) {
        velocity.y = -velocity.y;
      } else if (position.y > other.position.y + other.size.y / 2) {
        velocity.y = -velocity.y;
      } else if (position.x < other.position.x) {
        velocity.x = -velocity.x;
      } else if (position.x > other.position.x) {
        velocity.x = -velocity.x;
      }
    }
  }
}
