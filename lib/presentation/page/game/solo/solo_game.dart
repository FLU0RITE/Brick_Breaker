import 'package:break_brick/presentation/page/game/brick_breaker.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../controller/game/game_view_model.dart';
import '../config.dart';
import '../widget/overlay_screen.dart';
import '../widget/score_card.dart';

class SoloGamePage extends ConsumerStatefulWidget {
  SoloGamePage({super.key});
  @override
  ConsumerState<SoloGamePage> createState() => _SoloGamePageState();
}

class _SoloGamePageState extends ConsumerState<SoloGamePage> {
  // ⭐️ 1. BrickBreaker 인스턴스를 State에 저장하여 고정합니다.
  late final BrickBreaker _game;

  @override
  void initState() {
    super.initState();

    // ⭐️ 2. initState에서 ViewModel 인스턴스를 가져와 게임을 초기화합니다.
    // ref.read()를 사용하여 한 번만 인스턴스를 읽어옵니다.
    final viewModel = ref.read(gameViewModelProvider.notifier);
    _game = BrickBreaker(viewModel: viewModel);

    // ⭐️ 3. (선택 사항) 게임 오버 시 Flutter UI 레벨에서 특정 작업을 수행하려면 여기서 ref.listen을 사용할 수 있습니다.
  }

  // ⭐️ 4. dispose 시 게임 자원을 정리합니다.
  @override
  void dispose() {
    _game.pauseEngine(); // 게임 엔진 일시 정지/정리
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ⭐️ 5. 상태(점수, 턴)는 여기서 구독하여 UI만 리빌드합니다.
    final gameState = ref.watch(gameViewModelProvider);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        textTheme: GoogleFonts.pressStart2pTextTheme().apply(
          bodyColor: const Color(0xff184e77),
          displayColor: const Color(0xff184e77),
        ),
      ),
      home: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xff500000), Color(0xff000000)],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Column(
                  children: [
                    ScoreCard(),
                    const SizedBox(height: 16),
                    FittedBox(
                      child: SizedBox(
                        width: gameWidth,
                        height: gameHeight,
                        child: GameWidget(
                          game: _game,
                          overlayBuilderMap: {
                            PlayState.welcome.name:
                                (context, game) => const OverlayScreen(
                                  title: '탭하여 시작',
                                  subtitle: 'Use arrow keys or swipe',
                                ),
                            PlayState.gameOver.name:
                                (context, game) => const OverlayScreen(
                                  title: '게임 종료',
                                  subtitle: 'Tap to Play Again',
                                ),
                            PlayState.won.name:
                                (context, game) => const OverlayScreen(
                                  title: '스테이지 클리어',
                                  subtitle: 'Tap to Play Again',
                                ),
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
