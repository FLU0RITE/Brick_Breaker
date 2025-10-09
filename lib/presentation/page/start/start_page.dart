import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class StartPage extends StatelessWidget {
  const StartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OutlinedButton(
              onPressed: () => context.go('/login'),
              child: Text("로그인"),
            ),
            OutlinedButton(
              onPressed: () => context.go('/multi'),
              child: Text("멀티 게임"),
            ),
            OutlinedButton(
              onPressed: () => context.go('/solo'),
              child: Text("솔로 게임"),
            ),
          ],
        ),
      ),
    );
  }
}
