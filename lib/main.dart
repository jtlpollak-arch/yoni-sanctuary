import 'package:flutter/material.dart';
import 'screens/kinetic_sand_screen.dart';

void main() {
  runApp(const DigitalSanctuaryApp());
}

class DigitalSanctuaryApp extends StatelessWidget {
  const DigitalSanctuaryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Digital Sanctuary',
      theme: ThemeData(
        // עיצוב כהה שמתאים לאווירה מרגיעה
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      home: const KineticSandScreen(),
    );
  }
}
