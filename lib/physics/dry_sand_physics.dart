// lib/physics/dry_sand_physics.dart
import 'dart:math';
import 'dart:typed_data';

class DrySandPhysics {
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

      bool hitParticle = false;
      int hitGy = targetGy;

      for (int checkGy = currentGy; checkGy <= targetGy; checkGy++) {
        if (grid[checkGy * gridW + gx] != -1) {
          hitParticle = true;
          hitGy = checkGy;
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
        int surfaceGy = hitGy;
        while (surfaceGy >= 0 && grid[surfaceGy * gridW + gx] != -1) {
          surfaceGy--;
        }
        surfaceGy = surfaceGy.clamp(0, gridH - 1);

        int leftGx = gx - 1;
        int rightGx = gx + 1;

        bool canSlideLeft = false;
        if (leftGx >= 0) {
          int botGy = (surfaceGy + 1).clamp(0, gridH - 1);
          canSlideLeft = grid[surfaceGy * gridW + leftGx] == -1 && grid[botGy * gridW + leftGx] == -1;
        }

        bool canSlideRight = false;
        if (rightGx < gridW) {
          int botGy = (surfaceGy + 1).clamp(0, gridH - 1);
          canSlideRight = grid[surfaceGy * gridW + rightGx] == -1 && grid[botGy * gridW + rightGx] == -1;
        }

        if (canSlideLeft && canSlideRight) {
          px[i] += _random.nextBool() ? -cellSize : cellSize;
          py[i] = surfaceGy * cellSize;
          vy[i] *= 0.5;
        } else if (canSlideLeft) {
          px[i] -= cellSize;
          py[i] = surfaceGy * cellSize;
          vy[i] *= 0.5;
        } else if (canSlideRight) {
          px[i] += cellSize;
          py[i] = surfaceGy * cellSize;
          vy[i] *= 0.5;
        } else {
          // עצירה מוחלטת ויצירת זווית שעון חול קלאסית של 45 מעלות
          state[i] = 1;
          vx[i] = 0;
          vy[i] = 0;
          px[i] = gx * cellSize;
          py[i] = surfaceGy * cellSize;
          grid[surfaceGy * gridW + gx] = i;
        }
      } else {
        px[i] = nextX;
        py[i] = nextY;
      }
    }
  }
}
