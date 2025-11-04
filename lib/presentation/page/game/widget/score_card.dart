import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../controller/game/game_view_model.dart';

class ScoreCard extends ConsumerWidget {
  const ScoreCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final turnNumber = ref.watch(
      gameViewModelProvider.select((value) => value.turnNumber),
    );
    final score = ref.watch(
      gameViewModelProvider.select((value) => value.score),
    );
    return Row(
      children: [
        Text(
          '점수: $score'.toUpperCase(),
          style: Theme.of(
            context,
          ).textTheme.titleLarge!.copyWith(color: Colors.white),
        ),
        Text(
          '단계: $turnNumber'.toUpperCase(),
          style: Theme.of(
            context,
          ).textTheme.titleLarge!.copyWith(color: Colors.white),
        ),
      ],
    );
  }
}
