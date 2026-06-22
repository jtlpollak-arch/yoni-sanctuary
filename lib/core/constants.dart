class AppConstants {
  static int getMaxParticles() => 100000;
  static int getEmissionRate() => 100; // פליטה מסיבית של חלקיקים בכל פריים
}

class PhysicsConstants {
  static double getGravity() => 0.5;
  static double getFriction() => 0.9;
  static double getParticleRadius() => 1.5; // חלקיקים קטנים נראים טוב יותר במסה גדולה
}
