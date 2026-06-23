// lib/physics/stone_physics.dart
import 'dart:typed_data';

class StonePhysics {
  // אבן היא סטטית לחלוטין. הפונקציה רק מוודאת שהיא במצב מנוחה.
  static void update({required int count, required Int32List state, required Int32List materials, required int materialIndex}) {
    for (int i = 0; i < count; i++) {
      if (materials[i] == materialIndex) {
        state[i] = 1;
      }
    }
  }
}
