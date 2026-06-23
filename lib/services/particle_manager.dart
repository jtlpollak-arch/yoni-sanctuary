// lib/services/particle_manager.dart
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';
import '../core/constants.dart';

enum MaterialType { sand, stone, water, acid }

class ParticleManager {
  final int maxParticles = AppConstants.getMaxParticles();

  late Float32List px;
  late Float32List py;
  late Float32List vx;
  late Float32List vy;
  late Int32List age;
  late Int32List state;
  late Int32List materials;

  late Float32List rstTransforms;
  late Float32List rects;
  late Int32List colors;
  late Int32List baseColors;

  int count = 0;

  Int32List? grid;
  int gridW = 0;
  int gridH = 0;
  final double cellSize = PhysicsConstants.getParticleRadius() * 2;
  final Random _random = Random();

  ParticleManager() {
    px = Float32List(maxParticles);
    py = Float32List(maxParticles);
    vx = Float32List(maxParticles);
    vy = Float32List(maxParticles);
    age = Int32List(maxParticles);
    state = Int32List(maxParticles);
    materials = Int32List(maxParticles);

    rstTransforms = Float32List(maxParticles * 4);
    rects = Float32List(maxParticles * 4);
    colors = Int32List(maxParticles);
    baseColors = Int32List(maxParticles);

    for (int i = 0; i < maxParticles; i++) {
      rects[i * 4 + 0] = 0.0;
      rects[i * 4 + 1] = 0.0;
      rects[i * 4 + 2] = 1.0;
      rects[i * 4 + 3] = 1.0;
    }
  }

  void emitParticle(Offset position, Color particleColor, MaterialType type) {
    if (count >= maxParticles) return;

    if (grid != null && gridW > 0 && gridH > 0) {
      int gx = (position.dx / cellSize).floor().clamp(0, gridW - 1);
      int gy = (position.dy / cellSize).floor().clamp(0, gridH - 1);

      bool isBlocked = false;

      // תיקון 1: ציור אטום לאבן. חול ממשיך למנוע הצטברות יתר.
      if (type == MaterialType.stone) {
        if (grid![gy * gridW + gx] != -1) {
          isBlocked = true;
        }
      } else {
        for (int dy = -2; dy <= 8; dy++) {
          int checkGy = (gy + dy).clamp(0, gridH - 1);
          if (grid![checkGy * gridW + gx] != -1) {
            isBlocked = true;
            break;
          }
        }
      }

      if (isBlocked) {
        return;
      }
    }

    int i = count;
    px[i] = position.dx;
    py[i] = position.dy;

    if (type == MaterialType.stone) {
      vx[i] = 0.0;
      vy[i] = 0.0;
      state[i] = 1;
    } else {
      vx[i] = (_random.nextDouble() - 0.5) * 6;
      vy[i] = _random.nextDouble() * 3;
      state[i] = 0;
    }

    age[i] = 0;
    materials[i] = type.index;

    rstTransforms[i * 4 + 0] = cellSize;
    rstTransforms[i * 4 + 1] = 0.0;
    rstTransforms[i * 4 + 2] = px[i];
    rstTransforms[i * 4 + 3] = py[i];

    baseColors[i] = particleColor.value;
    colors[i] = particleColor.value;

    count++;
  }

  void updateParticles(Size size) {
    if (size.width == 0 || size.height == 0) return;

    int expectedGridW = (size.width / cellSize).ceil() + 1;
    int expectedGridH = (size.height / cellSize).ceil() + 1;

    if (grid == null || gridW != expectedGridW || gridH != expectedGridH) {
      gridW = expectedGridW;
      gridH = expectedGridH;
      grid = Int32List(gridW * gridH);
    }

    grid!.fillRange(0, grid!.length, -1);

    for (int i = 0; i < count; i++) {
      if (state[i] == 1) {
        int gx = (px[i] / cellSize).floor().clamp(0, gridW - 1);
        int gy = (py[i] / cellSize).floor().clamp(0, gridH - 1);
        grid![gy * gridW + gx] = i;
      }
    }

    final double gravity = PhysicsConstants.getGravity();

    for (int i = 0; i < count; i++) {
      if (state[i] == 1) continue;

      age[i]++;
      vy[i] += gravity;

      double nextX = px[i] + vx[i];
      double nextY = py[i] + vy[i];

      if (nextX < 0) {
        nextX = 0;
        vx[i] *= -0.5;
      } else if (nextX > size.width - cellSize) {
        nextX = size.width - cellSize;
        vx[i] *= -0.5;
      }

      int gx = (nextX / cellSize).floor().clamp(0, gridW - 1);
      int gy = (nextY / cellSize).floor().clamp(0, gridH - 1);

      bool hitBottom = nextY >= size.height - cellSize;
      bool hitParticle = !hitBottom && grid![gy * gridW + gx] != -1;

      if (hitBottom) {
        state[i] = 1;
        vx[i] = 0;
        vy[i] = 0;
        px[i] = gx * cellSize;

        int targetGy = gridH - 1;
        while (targetGy >= 0 && grid![targetGy * gridW + gx] != -1) {
          targetGy--;
        }
        targetGy = targetGy.clamp(0, gridH - 1);

        py[i] = targetGy * cellSize;
        grid![targetGy * gridW + gx] = i;
      } else if (hitParticle) {
        // תיקון 2: מניעת חיתוך פינות. בודקים גם את התא מהצד וגם את התא למטה מהצד.
        int currentGy = (gy - 1).clamp(0, gridH - 1);
        int leftGx = gx - 1;
        int rightGx = gx + 1;

        bool canSlideLeft = false;
        if (leftGx >= 0) {
          bool leftClear = grid![currentGy * gridW + leftGx] == -1; // האם פנוי שמאלה?
          bool botLeftClear = grid![gy * gridW + leftGx] == -1; // האם פנוי שמאלה ולמטה?
          canSlideLeft = leftClear && botLeftClear;
        }

        bool canSlideRight = false;
        if (rightGx < gridW) {
          bool rightClear = grid![currentGy * gridW + rightGx] == -1; // האם פנוי ימינה?
          bool botRightClear = grid![gy * gridW + rightGx] == -1; // האם פנוי ימינה ולמטה?
          canSlideRight = rightClear && botRightClear;
        }

        if (canSlideLeft && canSlideRight) {
          px[i] += _random.nextBool() ? -cellSize : cellSize;
          vy[i] *= 0.5;
        } else if (canSlideLeft) {
          px[i] -= cellSize;
          vy[i] *= 0.5;
        } else if (canSlideRight) {
          px[i] += cellSize;
          vy[i] *= 0.5;
        } else {
          int targetGy = gy;
          int climbCount = 0;

          while (targetGy >= 0 && grid![targetGy * gridW + gx] != -1 && climbCount < 3) {
            targetGy--;
            climbCount++;
          }

          targetGy = targetGy.clamp(0, gridH - 1);

          state[i] = 1;
          vx[i] = 0;
          vy[i] = 0;
          px[i] = gx * cellSize;
          py[i] = targetGy * cellSize;
          grid![targetGy * gridW + gx] = i;
        }
      } else {
        px[i] = nextX;
        py[i] = nextY;
      }

      rstTransforms[i * 4 + 2] = px[i];
      rstTransforms[i * 4 + 3] = py[i];
    }

    for (int i = 0; i < count; i++) {
      int baseColor = baseColors[i];
      int baseR = (baseColor >> 16) & 0xFF;
      int baseG = (baseColor >> 8) & 0xFF;
      int baseB = baseColor & 0xFF;

      if (state[i] == 1) {
        if (materials[i] == MaterialType.stone.index) {
          colors[i] = baseColor;
        } else {
          int gx = (px[i] / cellSize).floor().clamp(0, gridW - 1);
          int gy = (py[i] / cellSize).floor().clamp(0, gridH - 1);
          int shadowDepth = 0;

          for (int dy = 1; dy <= 6; dy++) {
            int checkGy = gy - dy;
            if (checkGy >= 0 && grid![checkGy * gridW + gx] != -1) {
              shadowDepth++;
            }
          }

          int r = (baseR - (shadowDepth * 18)).clamp(0, 255);
          int g = (baseG - (shadowDepth * 20)).clamp(0, 255);
          int b = (baseB - (shadowDepth * 12)).clamp(0, 255);

          colors[i] = Color.fromARGB(255, r, g, b).value;
        }
      } else {
        double op = (1.0 - (age[i] / 500)).clamp(0.6, 1.0);
        int alpha = (op * 255).toInt();
        colors[i] = Color.fromARGB(alpha, baseR, baseG, baseB).value;
      }
    }
  }
}
