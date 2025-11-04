import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'dart:ui'; // MaskFilter를 위해 필요합니다.

import '../../../controller/game/game_view_model.dart';
import '../config.dart';
import '../brick_breaker.dart';
import 'ball.dart';

class Brick extends RectangleComponent
    with CollisionCallbacks, HasGameReference<BrickBreaker> {
  // 초기 네온 광채 강도 (sigma 값)
  static const double glowSigmaInner = 3.0;
  static const double glowSigmaOuter = 8.0;

  Color neonColor1;
  Color neonColor2;

  // 두 가지 네온 페인트 객체
  late Paint outerGlowPaint;
  late Paint innerGlowPaint;

  late final TextComponent durabilityText;

  final ValueNotifier<int> durability;
  final int _maxDurability; // 최대 내구도 저장을 위한 내부 변수

  Brick({
    required super.position,
    required this.neonColor1,
    required this.neonColor2,
    required this.durability,
  }) : _maxDurability = durability.value, // 현재 내구도 값을 최대 내구도로 설정
        super(
        size: Vector2(brickWidth, brickHeight),
        anchor: Anchor.center,
        children: [RectangleHitbox()],
      ) {
// 3. 내구도 숫자 TextComponent 설정 및 초기화
    final textStyle = TextStyle(
      fontSize: size.y * 0.5, // 벽돌 높이의 약 50% 크기
      color: Colors.white,
      fontWeight: FontWeight.bold,
      shadows: const [
        // 텍스트에도 미세한 네온/광채 효과 추가
        Shadow(color: Colors.white, blurRadius: 4.0),
      ],
    );
    // 기본 Component의 paint는 투명하게 설정하거나 사용하지 않습니다.
    paint.color = Colors.transparent;

    final regular = TextPaint(style: textStyle);

    // TextComponent 생성
    durabilityText = TextComponent(
      text: durability.value.toString(),
      textRenderer: regular,
      anchor: Anchor.center,
      position: size / 2, // 벽돌의 정중앙에 위치
    );

    // TextComponent를 Brick의 자식으로 추가합니다.
    add(durabilityText);

    // 내구도 값이 변경될 때마다 텍스트를 업데이트하는 리스너를 등록합니다.
    durability.addListener(_updateDurabilityText);




    // 1. 외부 네온 효과 Paint 설정 (가장 넓게 퍼지는 광채)
    outerGlowPaint = Paint()
      ..color = neonColor1.withAlpha(200)
      ..style = PaintingStyle.stroke // 윤곽선 스타일
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.outer, glowSigmaOuter);

    // 2. 내부 네온/충전재 Paint 설정 (더 선명한 색상)
    innerGlowPaint = Paint()
      ..color = neonColor2.withAlpha(230)
      ..style = PaintingStyle.fill // 채우기 스타일
      ..maskFilter = const MaskFilter.blur(
        BlurStyle.normal,
        glowSigmaInner,
      );

  }


  // 내구도 텍스트를 업데이트하는 메서드
  void _updateDurabilityText() {
    durabilityText.text = durability.value.toString();
  }
  // 이 메서드를 오버라이드해야 네온 페인트가 그려집니다.
  @override
  void render(Canvas canvas) {
    final rect = size.toRect();

    // 1. 외부 네온 광채 그리기 (가장 바깥쪽)
    canvas.drawRect(rect, outerGlowPaint);

    // 2. 내부 네온 충전재 그리기
    canvas.drawRect(rect, innerGlowPaint);

  }

  @override
  void onRemove() {
    // 벽돌이 게임 월드에서 제거될 때 리스너를 반드시 해제합니다.
    durability.removeListener(_updateDurabilityText);
    super.onRemove();
  }

  @override
  void onCollisionStart(
      Set<Vector2> intersectionPoints,
      PositionComponent other,
      ) {
    super.onCollisionStart(intersectionPoints, other);

    // 내구도 감소는 충돌 시작 시 즉시 처리
    durability.value--;

    outerGlowPaint.maskFilter = const MaskFilter.blur(BlurStyle.outer, 15.0);
    innerGlowPaint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.0);
    outerGlowPaint.color = neonColor1;
    innerGlowPaint.color = neonColor2;


    // 제거 로직
    if (durability.value == 0) {
      removeFromParent();
      game.viewModel.increaseScore(1);
    }

    // ✨ 핵심 수정: 일정 시간 후 네온 설정을 원래대로 되돌리는 Future.delayed 추가
    Future.delayed(const Duration(milliseconds: 100), () {
      // 네온 광채 강도를 원래 값으로 복원
      outerGlowPaint.maskFilter = const MaskFilter.blur(BlurStyle.outer, glowSigmaOuter);
      innerGlowPaint.maskFilter = const MaskFilter.blur(BlurStyle.normal, glowSigmaInner);

      // 색상도 원래의 은은한 광채 투명도로 복원 (2번에서 수정한 opacity 값 사용)
      outerGlowPaint.color = neonColor1.withAlpha(200);
      innerGlowPaint.color = neonColor2.withAlpha(230);
    });

    if (game.world.children.query<Brick>().length == 1) {
      game.viewModel.setPlayState(PlayState.won);
      game.world.removeAll(game.world.children.query<Ball>());
    }
  }
}