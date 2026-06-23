// lib/screens/kinetic_sand_screen.dart
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../services/particle_manager.dart' as pm;
import '../widgets/sand_canvas.dart';
import '../core/constants.dart';

class KineticSandScreen extends StatefulWidget {
  const KineticSandScreen({super.key});

  @override
  State<KineticSandScreen> createState() => _KineticSandScreenState();
}

class _KineticSandScreenState extends State<KineticSandScreen> with SingleTickerProviderStateMixin {
  late AnimationController _ticker;
  final pm.ParticleManager _particleManager = pm.ParticleManager();
  final Random _random = Random();

  Offset _emitterPosition = const Offset(200, 50);
  Offset _previousEmitterPosition = const Offset(200, 50);
  ui.Image? _particleTexture;

  bool _isEmitting = false;
  Color _currentSandColor = Colors.amber[200]!;
  pm.MaterialType _currentMaterial = pm.MaterialType.sand;

  @override
  void initState() {
    super.initState();
    _createTexture().then((_) {
      _initializeTicker();
    });
  }

  Future<void> _createTexture() async {
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    final Paint paint = Paint()..color = Colors.white;
    canvas.drawRect(const Rect.fromLTWH(0, 0, 1, 1), paint);
    final ui.Picture picture = recorder.endRecording();
    _particleTexture = await picture.toImage(1, 1);
    setState(() {});
  }

  void _initializeTicker() {
    _ticker = AnimationController(vsync: this, duration: const Duration(seconds: 1))
      ..addListener(_gameLoop)
      ..repeat();
  }

  void _gameLoop() {
    setState(() {
      _spawnNewParticles();
      _particleManager.updateParticles(MediaQuery.sizeOf(context));

      if (_isEmitting) {
        _previousEmitterPosition = _emitterPosition;
      }
    });
  }

  void _startEmitting(Offset position) {
    setState(() {
      _isEmitting = true;
      _emitterPosition = position;
      _previousEmitterPosition = position;

      if (_currentMaterial == pm.MaterialType.stone) {
        _currentSandColor = Colors.grey[600]!;
      } else {
        _currentSandColor = Color.fromARGB(255, 150 + _random.nextInt(106), 150 + _random.nextInt(106), 150 + _random.nextInt(106));
      }
    });
  }

  void _updateEmitterPosition(Offset newPosition) {
    if (_isEmitting) {
      setState(() {
        _emitterPosition = newPosition;
      });
    }
  }

  void _stopEmitting() {
    setState(() {
      _isEmitting = false;
    });
  }

  void _spawnNewParticles() {
    if (!_isEmitting) return;

    int rate = AppConstants.getEmissionRate();
    for (int i = 0; i < rate; i++) {
      double t = (rate == 1) ? 1.0 : (i / (rate - 1));
      double interpX = ui.lerpDouble(_previousEmitterPosition.dx, _emitterPosition.dx, t)!;
      double interpY = ui.lerpDouble(_previousEmitterPosition.dy, _emitterPosition.dy, t)!;

      final center = Offset(interpX + (_random.nextDouble() * 20 - 10), interpY);

      _particleManager.emitParticle(center, _currentSandColor, _currentMaterial);
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  // פונקציית עזר ליצירת כפתורי החומרים (ממשק זמני לשלב זה)
  Widget _buildMaterialButton(String title, pm.MaterialType type, Color color) {
    bool isSelected = _currentMaterial == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentMaterial = type;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.4) : Colors.transparent,
          border: Border.all(color: color, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          title,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_particleTexture == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // שכבת הקנבס והציור
          GestureDetector(
            onPanDown: (details) => _startEmitting(details.localPosition),
            onPanUpdate: (details) => _updateEmitterPosition(details.localPosition),
            onPanEnd: (_) => _stopEmitting(),
            onPanCancel: () => _stopEmitting(),
            child: CustomPaint(
              painter: SandCanvas(manager: _particleManager, texture: _particleTexture!),
              size: Size.infinite,
            ),
          ),

          // שכבת הממשק הזמנית לבחירת חומרים
          Positioned(
            top: 50,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12)),
              child: Row(children: [_buildMaterialButton('חול', pm.MaterialType.sand, Colors.amber), const SizedBox(width: 10), _buildMaterialButton('אבן', pm.MaterialType.stone, Colors.grey)]),
            ),
          ),
        ],
      ),
    );
  }
}
