// lib/components/launch_guide.dart (새 파일)
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class LaunchGuide extends PositionComponent {
  // 가이드라인이 그릴 벡터 (방향과 길이)
  Vector2 _drawVector = Vector2.zero();
  final double maxGuideLength = 3000.0; // 가이드라인의 최대 길이 (추측한 내용입니다)
// 가이드라인이 공의 중심에서 떨어져 시작할 최소 거리(픽셀)
  final double startOffset = 50.0;

  LaunchGuide({required super.position});

  // 드래그 방향을 받아 가이드라인을 업데이트합니다.
  void updateDirection(Vector2 dragVector) {
    if (dragVector.y <= 0) {
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
      ..color = Colors.red.withAlpha(200)
      ..strokeWidth = 30.0
      ..strokeCap = StrokeCap.round;


    // 1. 발사 방향 벡터를 계산합니다 (드래그 벡터의 반대 방향).
    // _drawVector의 반대 방향이 발사 방향이며, 이를 정규화하여 단위 벡터를 얻습니다.
    final Vector2 launchDirection = -_drawVector.normalized();

    // 2. 가이드라인의 시작점 벡터를 계산합니다.
    // 발사 방향 단위 벡터에 startOffset을 곱하여 공의 중심에서 일정 거리 떨어진 지점을 시작점으로 설정합니다.
    final Vector2 startVector = launchDirection * startOffset;

    // 3. 가이드라인의 끝점 벡터를 계산합니다.
    // 기존과 동일하게 -_drawVector를 사용하여 드래그의 반대 방향 끝점을 설정합니다.
    final Vector2 endVector = -_drawVector;

    // 4. 공의 중심(Offset.zero)이 아닌, startVector 위치에서 endVector 위치까지 라인을 그립니다.
    canvas.drawLine(startVector.toOffset(), endVector.toOffset(), paint);
  }
}