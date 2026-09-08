import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import '../game_work/welcome_screen.dart';
// Import ALL game components from backup (PlayerData, CharacterSelection, Board)
import 'game_screen_bk.dart' show CirclePatternPage, CharacterSelectionScreen, PlayerData;

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  bool showWelcome = true;
  bool showCharacterSelection = false;
  bool showGameBoard = false;
  List<PlayerData> selectedPlayers = [];

  @override
  void initState() {
    super.initState();
    // Show welcome screen for 2 seconds, then character selection
    Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          showWelcome = false;
          showCharacterSelection = true;
        });
      }
    });
  }

  void startGame(List<PlayerData> players) {
    setState(() {
      selectedPlayers = players;
      showCharacterSelection = false;
      showGameBoard = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    // Show welcome screen first
    if (showWelcome) {
      return Scaffold(
        body: WelcomeScreen(),
      );
    }

    // Then show character selection or game board
    return Scaffold(
      appBar: showCharacterSelection && !showWelcome
          ? AppBar(
              title: Text(
                'Game Setup',
                style: GoogleFonts.roboto(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              backgroundColor: Color(0xFFF9A826),
              elevation: 0,
              leading: IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            )
          : null,
      backgroundColor: Colors.transparent,
      body: showCharacterSelection
          ? Stack(
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.center,
                        radius: 1.0,
                        colors: [
                          Color(0xFFFFC080),
                          Color(0xFFFCB366),
                          Color(0xFFFD8D3C),
                        ],
                      ),
                    ),
                  ),
                ),
                CharacterSelectionScreen(onGameStart: startGame),
                if (isLandscape)
                  Positioned.fill(
                    child: IgnorePointer(
                      ignoring: false,
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.75),
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.screen_rotation, size: 48, color: Colors.red),
                                const SizedBox(height: 12),
                                Text(
                                  'Game can\'t run in landscape mode',
                                  style: GoogleFonts.roboto(fontSize: 18, fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Please rotate your device to portrait to continue.',
                                  style: GoogleFonts.roboto(fontSize: 14, color: Colors.black54),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            )
          : Stack(
              children: [
                CirclePatternPage(players: selectedPlayers),
                if (isLandscape)
                  Positioned.fill(
                    child: IgnorePointer(
                      ignoring: false,
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.75),
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.screen_rotation, size: 48, color: Colors.red),
                                const SizedBox(height: 12),
                                Text(
                                  'Game can\'t run in landscape mode',
                                  style: GoogleFonts.roboto(fontSize: 18, fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Please rotate your device to portrait to continue.',
                                  style: GoogleFonts.roboto(fontSize: 14, color: Colors.black54),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

// The complete game board (CirclePatternPage) is now imported from game_screen_bk.dart
// This includes:
// - 40-square circular board with all images
// - Dice rolling with animations and sounds
// - Player movement and turn management  
// - Money system with denominations
// - All game popups (chores, rewards, behaviors, education, etc.)
// - Complete game logic and win conditions