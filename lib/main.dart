
import 'package:break_brick/presentation/page/game/brick_breaker.dart';
import 'package:break_brick/presentation/page/custom_router.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    // 먼저 Router 사용을 위해 MaterialApp을 MaterialApp.router로 변경을 해주도록 하자.
    // 라우터를 등록하고 사용하기 위해 .router 메소드를 사용하는 것이다.
    // home 옵션 파라미터가 없다.
    return MaterialApp.router(
      routerConfig: CustomRouter.router,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
    );
  }
}