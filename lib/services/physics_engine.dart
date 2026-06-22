// lib/services/physics_engine.dart
import 'dart:ui';

import 'package:sanctuary/models/particle_model.dart';

class PhysicsEngine {
  // חישוב המיקום הבא של החלקיק בהתחשב בכוח כבידה
  static Offset calculateNextPosition(Offset currentPosition, Offset velocity, double gravity) {
    return Offset(currentPosition.dx, currentPosition.dy + velocity.dy + gravity);
  }

  // חישוב המהירות הבאה בהתחשב בחיכוך
  static Offset calculateNextVelocity(Offset currentVelocity, double gravity, double friction) {
    double newDy = (currentVelocity.dy + gravity) * friction;
    return Offset(currentVelocity.dx, newDy);
  }

  // בדיקת התנגשות בין חלקיק למשטח או לחלקיקים אחרים
  static bool checkCollision(Offset position, Size screenSize, List<Particle> neighbors) {
    // בודק אם החלקיק הגיע לרצפה
    if (position.dy >= screenSize.height) return true;

    // כאן בעתיד נוסיף את הבדיקה מול חלקיקים שכבר נחים (Neighbors)
    return false;
  }

  // חישוב הטיה (כדי שהחול "ייערם" ולא רק ייפול בקו ישר)
  static Offset calculateSandFlow(Offset currentVelocity) {
    // לוגיקה שתגרום לחול לסטות מעט הצידה כשהוא נתקל במכשול
    return Offset(currentVelocity.dx * 0.1, currentVelocity.dy);
  }
}
