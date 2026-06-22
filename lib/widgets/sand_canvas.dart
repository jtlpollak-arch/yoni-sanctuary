// lib/widgets/sand_canvas.dart
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../services/particle_manager.dart';

class SandCanvas extends CustomPainter {
  final ParticleManager manager;
  final ui.Image texture;

  SandCanvas({required this.manager, required this.texture});

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint()..color = Colors.black;
    canvas.drawRect(Offset.zero & size, backgroundPaint);

    if (manager.count == 0) return;

    final transformsView = Float32List.sublistView(manager.rstTransforms, 0, manager.count * 4);
    final rectsView = Float32List.sublistView(manager.rects, 0, manager.count * 4);
    final colorsView = Int32List.sublistView(manager.colors, 0, manager.count);

    // השינוי הקריטי: BlendMode.modulate ממזג את הצבעים שלנו עם הפיקסל הלבן
    canvas.drawRawAtlas(texture, transformsView, rectsView, colorsView, BlendMode.modulate, null, Paint());
  }

  @override
  bool shouldRepaint(covariant SandCanvas oldDelegate) => true;
}
