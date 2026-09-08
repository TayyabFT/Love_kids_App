import 'package:flutter/material.dart';

// Welcome Screen that shows for 2 seconds before character selection
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.0,
          colors: [
            Color(0xFFFFC080), // Lighter orange-yellow (center)
            Color(0xFFFCB366), // Middle orange-yellow
            Color(0xFFFD8D3C), // Darker orange (outer)
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/circle.png', // Game logo
              width: 180,
              height: 180,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 15),
            const Text(
              'SAY IT NOW SELF-LOVE KIDS APP',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [
                  Shadow(
                    blurRadius: 10.0,
                    color: Colors.black45,
                    offset: Offset(2.0, 2.0),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Get ready for an exciting journey!',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white,
                shadows: [
                  Shadow(
                    blurRadius: 5.0,
                    color: Colors.black45,
                    offset: Offset(1.0, 1.0),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
