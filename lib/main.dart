import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';

void main() {
  runApp(GameWidget(game: BattleArenaGame()));
}

class BattleArenaGame extends FlameGame with HasCollisionDetection, TapDetector {
  late Player player;
  int killCount = 0;
  int coinCount = 0;
  Vector2 playerMove = Vector2.zero();
  
  late TextComponent upBtn, downBtn, leftBtn, rightBtn, shootBtn;
  late TextComponent killText, coinText, titleText;
  
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    titleText = TextComponent(
      text: 'Battle Arena-Battleground',
      textRenderer: TextPaint(style: TextStyle(fontSize: 20, color: Colors.yellow, fontWeight: FontWeight.bold)),
      position: Vector2(size.x / 2, 30),
      anchor: Anchor.topCenter,
    );
    add(titleText);
    
    player = Player(position: size / 2);
    add(player);
    add(Bot(position: Vector2(100, 100)));
    
    killText = TextComponent(text: 'KILLS: 0', position: Vector2(10, 60));
    coinText = TextComponent(text: 'COINS: 0', position: Vector2(10, 80));
    addAll([killText, coinText]);
    
    upBtn = TextComponent(text: '↑', position: Vector2(80, size.y - 180), textRenderer: TextPaint(style: TextStyle(fontSize: 50)));
    downBtn = TextComponent(text: '↓', position: Vector2(80, size.y - 80), textRenderer: TextPaint(style: TextStyle(fontSize: 50)));
    leftBtn = TextComponent(text: '←', position: Vector2(30, size.y - 130), textRenderer: TextPaint(style: TextStyle(fontSize: 50)));
    rightBtn = TextComponent(text: '→', position: Vector2(130, size.y - 130), textRenderer: TextPaint(style: TextStyle(fontSize: 50)));
    shootBtn = TextComponent(text: '🔥', position: Vector2(size.x - 80, size.y - 130), textRenderer: TextPaint(style: TextStyle(fontSize: 50)));
    
    addAll([upBtn, downBtn, leftBtn, rightBtn, shootBtn]);
  }
  
  @override
  void onTapDown(TapDownInfo info) {
    Vector2 tapPos = info.eventPosition.global;
    if (upBtn.containsPoint(tapPos)) {
      playerMove = Vector2(0, -1);
    } else if (downBtn.containsPoint(tapPos)) {
      playerMove = Vector2(0, 1);
    } else if (leftBtn.containsPoint(tapPos)) {
      playerMove = Vector2(-1, 0);
    } else if (rightBtn.containsPoint(tapPos)) {
      playerMove = Vector2(1, 0);
    } else if (shootBtn.containsPoint(tapPos)) {
      player.shoot();
    } else {
      Vector2 dir = (tapPos - player.position).normalized();
      add(Bullet(position: player.position, direction: dir));
    }
  }
  
  @override
  void onTapUp(TapUpInfo info) {
    playerMove = Vector2.zero();
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    player.position += playerMove * 200 * dt;
    killText.text = 'KILLS: $killCount';
    coinText.text = 'COINS: $coinCount';
  }
}

class Player extends RectangleComponent with HasGameRef<BattleArenaGame> {
  Player({required super.position}) : super(size: Vector2(40, 40), anchor: Anchor.center);
  @override
  Future<void> onLoad() async { paint = Paint()..color = Colors.cyan; }
  void shoot() { gameRef.add(Bullet(position: position, direction: Vector2(0, -1))); }
}

class Bot extends RectangleComponent with HasGameRef<BattleArenaGame> {
  double shootTimer = 0;
  Bot({required super.position}) : super(size: Vector2(40, 40), anchor: Anchor.center);
  @override
  Future<void> onLoad() async { paint = Paint()..color = Colors.red; }
  @override
  void update(double dt) {
    super.update(dt);
    shootTimer += dt;
    if (shootTimer > 1.5) {
      shootTimer = 0;
      Vector2 dir = (gameRef.player.position - position).normalized();
      gameRef.add(Bullet(position: position, direction: dir, isPlayerBullet: false));
    }
  }
}

class Bullet extends RectangleComponent with HasGameRef<BattleArenaGame> {
  Vector2 direction;
  bool isPlayerBullet;
  Bullet({required super.position, required this.direction, this.isPlayerBullet = true}) : super(size: Vector2(10, 10), anchor: Anchor.center);
  @override
  Future<void> onLoad() async { paint = Paint()..color = isPlayerBullet ? Colors.yellow : Colors.orange; }
  @override
  void update(double dt) {
    super.update(dt);
    position += direction * 400 * dt;
    if (isPlayerBullet) {
      gameRef.children.whereType<Bot>().forEach((bot) {
        if (bot.toRect().overlaps(toRect())) {
          gameRef.killCount++;
          gameRef.coinCount += 10;
          bot.removeFromParent();
          removeFromParent();
          gameRef.add(Bot(position: Vector2.random()..multiply(gameRef.size)));
        }
      });
    }
  }
}
