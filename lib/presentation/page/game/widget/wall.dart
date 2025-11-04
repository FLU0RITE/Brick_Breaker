import 'dart:async';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flame/collisions.dart';

import '../brick_breaker.dart';

class Wall extends RectangleComponent with CollisionCallbacks {
  Wall({required Vector2 position, required Vector2 size})
    : super(
        position: position,
        size: size,
        paint: Paint()..color = Colors.transparent,
        children: [RectangleHitbox()],
      );
}
