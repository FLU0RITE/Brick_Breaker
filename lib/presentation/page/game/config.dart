

import 'dart:ui';

const brickColors = [
  Color(0xffffffff),
  Color(0xffececeb),
  Color(0xffe0dddd),
  Color(0xffd0cecd),
  Color(0xffb8b6b5),
  Color(0xff979797),
  Color(0xff7c7c7c),
  Color(0xff505050),
  Color(0xff242424),
  Color(0xff0a0a0a),
];

const gameWidth = 820.0;
const gameHeight = 1600.0;
const ballRadius = gameWidth * 0.02;

const ballSpeed = 1500.0;

const brickGutter = gameWidth * 0.015;
final brickWidth =
    (gameWidth - (brickGutter * (6 + 1))) / 6;
const brickHeight = gameHeight * 0.06;
const difficultyModifier = 1.03;