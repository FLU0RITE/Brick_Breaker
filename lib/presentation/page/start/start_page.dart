import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class StartPage extends StatelessWidget {
  const StartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OutlinedButton(onPressed: (){}, child: Text("로그인")),
            OutlinedButton(onPressed: (){}, child: Text("멀티 게임")),
            OutlinedButton(onPressed: (){}, child: Text("솔로 게임")),
          ]
        )
      )
    );
  }
}
