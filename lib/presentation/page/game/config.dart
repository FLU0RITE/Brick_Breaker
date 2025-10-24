
const gameWidth = 820.0;
const gameHeight = 1600.0;
const ballRadius = gameWidth * 0.02;

const ballSpeed = 1000.0;

const brickGutter = gameWidth * 0.015;
final brickWidth =
    (gameWidth - (brickGutter * (6 + 1))) / 6;
const brickHeight = gameHeight * 0.06;
const difficultyModifier = 1.03;