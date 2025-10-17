import 'package:flutter/material.dart';

class ScoreCard extends StatelessWidget {
  const ScoreCard({super.key, required this.score, required this.turnNumber});

  final ValueNotifier<int> score;

  final ValueNotifier<int> turnNumber;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ValueListenableBuilder<int>(
          valueListenable: score,
          builder: (context, score, child) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 18),
              child: Text(
                '점수: $score'.toUpperCase(),
                style: Theme.of(context).textTheme.titleLarge!.copyWith(color: Colors.white),
              ),
            );
          },
        ),
        ValueListenableBuilder<int>(
          valueListenable: turnNumber,
          builder: (context, turnNumber, child) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 18),
              child: Text(
                '단계: $turnNumber'.toUpperCase(),
                style: Theme.of(context).textTheme.titleLarge!.copyWith(color: Colors.white),
              ),
            );
          },
        ),
      ],
    );
  }
}