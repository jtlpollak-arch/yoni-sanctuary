// lib/models/particle_model.dart
import 'dart:ui';

class Particle {
  Offset position;
  Offset velocity;
  Color color;
  bool isResting;
  int age = 0;

  Particle({required this.position, required this.velocity, required this.color, this.isResting = false});

  // פונקציית Factory ליצירת חלקיק חדש בנקודת התחלה
  factory Particle.create(Offset startPosition, Color color) {
    return Particle(position: startPosition, velocity: Offset.zero, color: color);
  }

  void incrementAge() => age++;

  // פונקציית עדכון פיזיקלי של מיקום ומהירות
  void updatePhysics(double gravity, double friction) {
    if (isResting) return;
    age++;

    // הוספת כוח כבידה למהירות האנכית
    velocity = Offset(velocity.dx, velocity.dy + gravity);
    // עדכון המיקום לפי המהירות
    position = position + velocity;
  }

  // פונקציית בדיקת מצב מנוחה
  void setResting(bool value) {
    isResting = value;
    if (value) {
      velocity = Offset.zero;
    }
  }

  // פונקציית עזר לבדיקת גבולות המסך
  bool isOutOfBounds(Size screenSize) {
    return position.dy > screenSize.height;
  }

  // פונקציית שכפול (Immutable pattern)
  Particle copyWith({Offset? position, Offset? velocity, Color? color, bool? isResting}) {
    return Particle(position: position ?? this.position, velocity: velocity ?? this.velocity, color: color ?? this.color, isResting: isResting ?? this.isResting);
  }
}
