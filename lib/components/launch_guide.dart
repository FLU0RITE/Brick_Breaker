// lib/components/launch_guide.dart (새 파일)
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class LaunchGuide extends PositionComponent {
  // 가이드라인이 그릴 벡터 (방향과 길이)
  Vector2 _drawVector = Vector2.zero();
  final double maxGuideLength = 150.0; // 가이드라인의 최대 길이 (추측한 내용입니다)

  LaunchGuide({required super.position});

  // 드래그 방향을 받아 가이드라인을 업데이트합니다.
  void updateDirection(Vector2 dragVector) {
    if (dragVector.y >= 0) {
      // 아래로 향하는 드래그는 무시합니다.
      _drawVector = Vector2.zero();
      return;
    }

    // 벡터의 길이를 최대 길이로 제한합니다.
    if (dragVector.length > maxGuideLength) {
      _drawVector = dragVector.normalized() * maxGuideLength;
    } else {
      _drawVector = dragVector;
    }

    // 강제적으로 다시 그리도록 요청
    // 이 컴포넌트는 PositionComponent이므로, onDragUpdate에서 업데이트된 후 다음 프레임에 자동으로 그려집니다.
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final paint = Paint()
      ..color = Colors.blue.withOpacity(0.7)
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    // 공의 현재 위치(0, 0)에서 드래그 벡터의 끝점까지 라인을 그립니다.
    canvas.drawLine(Offset.zero, _drawVector.toOffset(), paint);
  }
}