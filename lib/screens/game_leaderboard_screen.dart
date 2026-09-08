import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' show pi;
import 'game_screen_bk.dart';

class GameLeaderboardScreen extends StatefulWidget {
  final List<PlayerData> players;
  final VoidCallback onPlayAgain;
  final VoidCallback onExit;

  const GameLeaderboardScreen({
    super.key,
    required this.players,
    required this.onPlayAgain,
    required this.onExit,
  });

  @override
  State<GameLeaderboardScreen> createState() => _GameLeaderboardScreenState();
}

class _GameLeaderboardScreenState extends State<GameLeaderboardScreen>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _slideAnimations;
  late List<Animation<double>> _fadeAnimations;
  late AnimationController _confettiController;
  late AnimationController _trophyController;
  late Animation<double> _trophyRotation;
  late Animation<double> _trophyScale;

  List<PlayerData> _sortedPlayers = [];
  final AudioPlayer _winnerAudioPlayer = AudioPlayer();
  bool _winnerSoundPlayed = false;

  // Win sound played when a player wins (reaches 200 points).
  static const String _winnerSoundAsset = 'game_sound/winner_sound.mp3';

  @override
  void initState() {
    super.initState();

    _playWinnerSoundOnce();

    // Sort players by total money (descending)
    _sortedPlayers = List.from(widget.players);
    _sortedPlayers.sort((a, b) => b.totalMoney.compareTo(a.totalMoney));

    // Initialize animation controllers for each player card
    _controllers = List.generate(
      _sortedPlayers.length,
      (index) => AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 600),
      ),
    );

    _slideAnimations = _controllers.map((controller) {
      return Tween<double>(begin: 100.0, end: 0.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeOutBack),
      );
    }).toList();

    _fadeAnimations = _controllers.map((controller) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeIn),
      );
    }).toList();

    // Trophy animation
    _trophyController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1500),
    );

    _trophyRotation = Tween<double>(begin: -0.2, end: 0.2).animate(
      CurvedAnimation(parent: _trophyController, curve: Curves.easeInOut),
    );

    _trophyScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _trophyController,
        curve: Curves.elasticOut,
      ),
    );

    // Confetti animation
    _confettiController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 3),
    );

    // Start animations with staggered delays
    _startAnimations();
  }

  Future<void> _playWinnerSoundOnce() async {
    if (_winnerSoundPlayed) return;
    _winnerSoundPlayed = true;

    try {
      await _winnerAudioPlayer.setVolume(1.0);
      await _winnerAudioPlayer.setPlayerMode(PlayerMode.mediaPlayer);
      await _winnerAudioPlayer.setReleaseMode(ReleaseMode.stop);
      await _winnerAudioPlayer.play(
        AssetSource(_winnerSoundAsset),
        volume: 1.0,
      );
    } catch (e) {
      debugPrint('Error playing winner sound: $e');
    }
  }

  void _startAnimations() async {
    // Start trophy animation first
    _trophyController.forward();
    _confettiController.repeat();

    // Stagger player card animations
    for (int i = 0; i < _controllers.length; i++) {
      await Future.delayed(Duration(milliseconds: 200 * i));
      if (mounted) {
        _controllers[i].forward();
      }
    }
  }

  @override
  void dispose() {
    _winnerAudioPlayer.dispose();
    for (var controller in _controllers) {
      controller.dispose();
    }
    _trophyController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 0:
        return Color(0xFFFFD700); // Gold
      case 1:
        return Color(0xFFC0C0C0); // Silver
      case 2:
        return Color(0xFFCD7F32); // Bronze
      default:
        return Color(0xFF64B5F6); // Blue
    }
  }

  String _getRankLabel(int rank) {
    switch (rank) {
      case 0:
        return '1st';
      case 1:
        return '2nd';
      case 2:
        return '3rd';
      default:
        return '${rank + 1}th';
    }
  }

  IconData _getRankIcon(int rank) {
    switch (rank) {
      case 0:
        return Icons.emoji_events; // Trophy
      case 1:
        return Icons.workspace_premium; // Medal
      case 2:
        return Icons.military_tech; // Bronze medal
      default:
        return Icons.star; // Star
    }
  }

  @override
  Widget build(BuildContext context) {
    final winner = _sortedPlayers.first;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1A237E), // Deep indigo
              Color(0xFF283593), // Indigo
              Color(0xFF3949AB), // Light indigo
              Color(0xFF5E35B1), // Deep purple
            ],
          ),
        ),
        child: Stack(
          children: [
            // Confetti animation
            _buildConfetti(),

            // Main content
            SafeArea(
              child: Column(
                children: [
                  SizedBox(height: 20),

                  // Trophy and winner announcement
                  _buildWinnerSection(winner),

                  SizedBox(height: 30),

                  // Leaderboard title
                  Text(
                    'FINAL STANDINGS',
                    style: GoogleFonts.roboto(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),

                  SizedBox(height: 20),

                  // Player cards
                  Expanded(
                    child: ListView.builder(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _sortedPlayers.length,
                      itemBuilder: (context, index) {
                        return AnimatedBuilder(
                          animation: _controllers[index],
                          builder: (context, child) {
                            return Transform.translate(
                              offset: Offset(_slideAnimations[index].value, 0),
                              child: Opacity(
                                opacity: _fadeAnimations[index].value,
                                child: _buildPlayerCard(
                                  _sortedPlayers[index],
                                  index,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),

                  // Action buttons
                  _buildActionButtons(),

                  SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfetti() {
    return AnimatedBuilder(
      animation: _confettiController,
      builder: (context, child) {
        return CustomPaint(
          painter: ConfettiPainter(_confettiController.value),
          size: Size.infinite,
        );
      },
    );
  }

  Widget _buildWinnerSection(PlayerData winner) {
    return AnimatedBuilder(
      animation: _trophyController,
      builder: (context, child) {
        return Column(
          children: [
            // Trophy icon with animation
            Transform.rotate(
              angle: _trophyRotation.value,
              child: Transform.scale(
                scale: _trophyScale.value,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Color(0xFFFFD700),
                        Color(0xFFFFA500),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber.withValues(alpha: 0.6),
                        blurRadius: 30,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.emoji_events,
                    size: 70,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            SizedBox(height: 20),

            // Winner announcement
            Text(
              '🎉 WINNER! 🎉',
              style: GoogleFonts.roboto(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.amber[300],
                letterSpacing: 3,
              ),
            ),

            SizedBox(height: 10),

            // Winner name
            Text(
              winner.name,
              style: GoogleFonts.roboto(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),

            SizedBox(height: 5),

            // Winner money
            Container(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.amber, width: 2),
              ),
              child: Text(
                '\$${winner.totalMoney}',
                style: GoogleFonts.roboto(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber[300],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPlayerCard(PlayerData player, int rank) {
    final rankColor = _getRankColor(rank);
    final rankLabel = _getRankLabel(rank);
    final rankIcon = _getRankIcon(rank);

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.9),
            Colors.white.withValues(alpha: 0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: rankColor.withValues(alpha: 0.3),
            blurRadius: rank == 0 ? 20 : 10,
            spreadRadius: rank == 0 ? 5 : 2,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            // Rank badge
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    rankColor,
                    rankColor.withValues(alpha: 0.7),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: rankColor.withValues(alpha: 0.5),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(rankIcon, color: Colors.white, size: 28),
                ],
              ),
            ),

            SizedBox(width: 16),

            // Player avatar
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: player.color, width: 3),
                image: DecorationImage(
                  image: AssetImage(player.imagePath),
                  fit: BoxFit.cover,
                ),
              ),
            ),

            SizedBox(width: 16),

            // Player info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        rankLabel,
                        style: GoogleFonts.roboto(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: rankColor,
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        player.name,
                        style: GoogleFonts.roboto(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A237E),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.attach_money, color: Colors.green[700], size: 18),
                      Text(
                        '\$${player.totalMoney}',
                        style: GoogleFonts.roboto(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.green[700],
                        ),
                      ),
                      SizedBox(width: 16),
                      Icon(Icons.loop, color: Colors.blue[700], size: 18),
                      SizedBox(width: 4),
                      Text(
                        '${player.lapsCompleted} laps',
                        style: GoogleFonts.roboto(
                          fontSize: 16,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Trophy for top 3
            if (rank < 3)
              Icon(
                rank == 0
                    ? Icons.emoji_events
                    : rank == 1
                        ? Icons.workspace_premium
                        : Icons.military_tech,
                color: rankColor,
                size: 32,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 32),
      child: ElevatedButton.icon(
        onPressed: widget.onExit,
        icon: Icon(Icons.exit_to_app, size: 28),
        label: Text(
          'Exit to Home',
          style: GoogleFonts.roboto(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red[400],
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 8,
        ),
      ),
    );
  }
}

// Custom painter for confetti animation
class ConfettiPainter extends CustomPainter {
  final double animationValue;
  final List<ConfettiParticle> particles;

  ConfettiPainter(this.animationValue)
      : particles = List.generate(
          50,
          (index) => ConfettiParticle(index),
        );

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      final paint = Paint()
        ..color = particle.color.withValues(alpha: 0.8)
        ..style = PaintingStyle.fill;

      final x = particle.startX * size.width;
      final y = (particle.startY + animationValue * particle.speed) % 1.0 * size.height;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(animationValue * particle.rotation * 2 * pi);

      // Draw confetti piece
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: 8, height: 12),
          Radius.circular(2),
        ),
        paint,
      );

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(ConfettiPainter oldDelegate) => true;
}

class ConfettiParticle {
  final double startX;
  final double startY;
  final double speed;
  final double rotation;
  final Color color;

  ConfettiParticle(int seed)
      : startX = (seed * 0.1) % 1.0,
        startY = (seed * 0.05) % 1.0,
        speed = 0.5 + (seed % 5) * 0.1,
        rotation = (seed % 10) * 0.2,
        color = [
          Colors.red,
          Colors.blue,
          Colors.green,
          Colors.yellow,
          Colors.purple,
          Colors.orange,
          Colors.pink,
          Colors.teal,
        ][seed % 8];
}
