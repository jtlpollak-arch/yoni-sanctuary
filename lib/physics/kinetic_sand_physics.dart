// lib/physics/kinetic_sand_physics.dart
import 'dart:math';
import 'dart:typed_data';

class KineticSandPhysics {
  static final Random _random = Random();

  static void update({required int count, required Float32List px, required Float32List py, required Float32List vx, required Float32List vy, required Int32List state, required Int32List materials, required Int32List grid, required int gridW, required int gridH, required double cellSize, required double gravity, required double width, required double height, required int materialIndex}) {
    for (int i = 0; i < count; i++) {
      if (state[i] == 1 || materials[i] != materialIndex) continue;

      vy[i] += gravity;
      double nextX = px[i] + vx[i];
      double nextY = py[i] + vy[i];

      if (nextX < 0) {
        nextX = 0;
        vx[i] *= -0.5;
      } else if (nextX > width - cellSize) {
        nextX = width - cellSize;
        vx[i] *= -0.5;
      }

      int currentGy = (py[i] / cellSize).floor().clamp(0, gridH - 1);
      int targetGy = (nextY / cellSize).floor().clamp(0, gridH - 1);
      int gx = (nextX / cellSize).floor().clamp(0, gridW - 1);

      // תיקון Tunneling
      bool hitParticle = false;
      int gy = targetGy;
      for (int checkGy = currentGy; checkGy <= targetGy; checkGy++) {
        if (grid[checkGy * gridW + gx] != -1) {
          hitParticle = true;
          gy = checkGy; // נקודת הפגיעה האמיתית
          break;
        }
      }

      bool hitBottom = nextY >= height - cellSize;

      if (hitBottom && !hitParticle) {
        state[i] = 1;
        vx[i] = 0;
        vy[i] = 0;
        px[i] = gx * cellSize;

        int bottomGy = gridH - 1;
        while (bottomGy >= 0 && grid[bottomGy * gridW + gx] != -1) {
          bottomGy--;
        }
        bottomGy = bottomGy.clamp(0, gridH - 1);

        py[i] = bottomGy * cellSize;
        grid[bottomGy * gridW + gx] = i;
      } else if (hitParticle) {
        int currentCheckGy = (gy - 1).clamp(0, gridH - 1);
        int leftGx = gx - 1;
        int rightGx = gx + 1;

        bool canSlideLeft = false;
        if (leftGx >= 0) {
          bool leftClear = grid[currentCheckGy * gridW + leftGx] == -1;
          bool botLeftClear = grid[gy * gridW + leftGx] == -1;
          canSlideLeft = leftClear && botLeftClear;
        }

        bool canSlideRight = false;
        if (rightGx < gridW) {
          bool rightClear = grid[currentCheckGy * gridW + rightGx] == -1;
          bool botRightClear = grid[gy * gridW + rightGx] == -1;
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
          int climbTargetGy = gy;
          int climbCount = 0;

          while (climbTargetGy >= 0 && grid[climbTargetGy * gridW + gx] != -1 && climbCount < 3) {
            climbTargetGy--;
            climbCount++;
          }

          climbTargetGy = climbTargetGy.clamp(0, gridH - 1);

          state[i] = 1;
          vx[i] = 0;
          vy[i] = 0;
          px[i] = gx * cellSize;
          py[i] = climbTargetGy * cellSize;
          grid[climbTargetGy * gridW + gx] = i;
        }
      } else {
        px[i] = nextX;
        py[i] = nextY;
      }
    }
  }
}
