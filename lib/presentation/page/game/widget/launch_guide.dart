// lib/components/launch_guide.dart (새 파일)
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class LaunchGuide extends PositionComponent {
  Vector2 _drawVector = Vector2.zero();
  final double maxGuideLength = 3000.0;
  final double startOffset = 50.0;

  LaunchGuide({required super.position});

  void updateDirection(Vector2 dragVector) {
    if (dragVector.y <= 0) {
      _drawVector = Vector2.zero();
      return;
    }

    if (dragVector.length > maxGuideLength) {
      _drawVector = dragVector.normalized() * maxGuideLength;
    } else {
      _drawVector = dragVector;
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final paint = Paint()
      ..color = Colors.red.withAlpha(200)
      ..strokeWidth = 30.0
      ..strokeCap = StrokeCap.round;

    final Vector2 launchDirection = -_drawVector.normalized();

    final Vector2 startVector = launchDirection * startOffset;

    final Vector2 endVector = -_drawVector;

    canvas.drawLine(startVector.toOffset(), endVector.toOffset(), paint);
  }
}