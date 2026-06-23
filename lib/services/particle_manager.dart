// lib/services/particle_manager.dart
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';
import '../core/constants.dart';
import '../core/material_type.dart';
import '../physics/stone_physics.dart';
import '../physics/kinetic_sand_physics.dart';
import '../physics/dry_sand_physics.dart';

class ParticleManager {
  final int maxParticles = AppConstants.getMaxParticles();

  late Float32List px, py, vx, vy;
  late Int32List age, state, materials;
  late Float32List rstTransforms;
  late Float32List rects;
  late Int32List colors, baseColors;

  int count = 0;
  Int32List? grid;
  int gridW = 0, gridH = 0;
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

  void reset() {
    count = 0;
    if (grid != null) {
      grid!.fillRange(0, grid!.length, -1);
    }
  }

  void emitParticle(Offset position, Color color, MaterialType type) {
    if (count >= maxParticles) return;

    if (grid != null && gridW > 0 && gridH > 0) {
      int gx = (position.dx / cellSize).floor().clamp(0, gridW - 1);
      int gy = (position.dy / cellSize).floor().clamp(0, gridH - 1);

      if (grid![gy * gridW + gx] != -1) {
        if (type == MaterialType.stone && materials[grid![gy * gridW + gx]] != MaterialType.stone.index) {
          // תאפשר ציור
        } else {
          return;
        }
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
    baseColors[i] = color.value;
    colors[i] = color.value;

    rstTransforms[i * 4 + 0] = cellSize;
    rstTransforms[i * 4 + 1] = 0.0;
    rstTransforms[i * 4 + 2] = px[i];
    rstTransforms[i * 4 + 3] = py[i];

    count++;
  }

  void updateParticles(Size size) {
    if (size.width == 0) return;

    _syncGrid(size);
    _runPhysics(size);
    _updateRendering();
  }

  void _syncGrid(Size size) {
    gridW = (size.width / cellSize).ceil() + 1;
    gridH = (size.height / cellSize).ceil() + 1;
    grid = Int32List(gridW * gridH)..fillRange(0, gridW * gridH, -1);
    for (int i = 0; i < count; i++) {
      if (state[i] == 1) {
        int gx = (px[i] / cellSize).floor().clamp(0, gridW - 1);
        int gy = (py[i] / cellSize).floor().clamp(0, gridH - 1);
        grid![gy * gridW + gx] = i;
      }
    }
  }

  void _runPhysics(Size size) {
    StonePhysics.update(count: count, state: state, materials: materials, materialIndex: MaterialType.stone.index);

    KineticSandPhysics.update(count: count, px: px, py: py, vx: vx, vy: vy, state: state, materials: materials, grid: grid!, gridW: gridW, gridH: gridH, cellSize: cellSize, gravity: PhysicsConstants.getGravity(), width: size.width, height: size.height, materialIndex: MaterialType.kineticSand.index);

    DrySandPhysics.update(count: count, px: px, py: py, vx: vx, vy: vy, state: state, materials: materials, grid: grid!, gridW: gridW, gridH: gridH, cellSize: cellSize, gravity: PhysicsConstants.getGravity(), width: size.width, height: size.height, materialIndex: MaterialType.drySand.index);
  }

  void _updateRendering() {
    for (int i = 0; i < count; i++) {
      rstTransforms[i * 4 + 2] = px[i];
      rstTransforms[i * 4 + 3] = py[i];

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
