import 'package:break_brick/presentation/page/game/brick_breaker.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';


import '../config.dart';
import '../widget/overlay_screen.dart';
import '../widget/score_card.dart';

class SoloGamePage extends StatefulWidget {
  const SoloGamePage({super.key});

  @override
  State<SoloGamePage> createState() => _SoloGamePageState();
}

class _SoloGamePageState extends State<SoloGamePage> {
  late final BrickBreaker game;

  @override
  void initState() {
    super.initState();
    game = BrickBreaker();
  }

  @override
  Widget build(BuildContext context) {
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
                    ScoreCard(score: game.score, turnNumber: game.turnNumber),
                    Expanded(
                      child: FittedBox(
                        child: SizedBox(
                          width: gameWidth,
                          height: gameHeight,
                          child: GameWidget(
                            game: game,
                            overlayBuilderMap: {
                              PlayState.welcome.name: (context, game) =>
                              const OverlayScreen(
                                title: '탭하여 시작',
                                subtitle: 'Use arrow keys or swipe',
                              ),
                              PlayState.gameOver.name: (context, game) =>
                              const OverlayScreen(
                                title: '게임 종료',
                                subtitle: 'Tap to Play Again',
                              ),
                              PlayState.won.name: (context, game) =>
                              const OverlayScreen(
                                title: '스테이지 클리어',
                                subtitle: 'Tap to Play Again',
                              ),
                            },
                          ),
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