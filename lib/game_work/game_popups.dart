import 'package:flutter/material.dart';
import 'dart:math';
import 'game_models.dart';

// ==================== GAME POPUP (Generic two-image popup) ====================

class GamePopup extends StatefulWidget {
  final String firstImagePath;
  final String secondImagePath;
  final VoidCallback onClose;

  const GamePopup({
    super.key,
    required this.firstImagePath,
    required this.secondImagePath,
    required this.onClose,
  });

  @override
  _GamePopupState createState() => _GamePopupState();
}

class _GamePopupState extends State<GamePopup> {
  double opacity1 = 0.0;
  double opacity2 = 0.0;

  @override
  void initState() {
    super.initState();
    // Show the first image immediately
    Future.delayed(Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          opacity1 = 1.0;
        });
      }
    });

    // Show the second image after 2 seconds
    Future.delayed(Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          opacity2 = 1.0;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        width: double.infinity,
        height: MediaQuery.of(context).size.height * 0.5,
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          children: [
            // First Image with Animation
            AnimatedOpacity(
              opacity: opacity1,
              duration: Duration(seconds: 1),
              child: Positioned.fill(
                child: Center(
                  child: Image.asset(
                    widget.firstImagePath,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            // Second Image with Animation (appears after 2 seconds)
            AnimatedOpacity(
              opacity: opacity2,
              duration: Duration(seconds: 1),
              child: Positioned.fill(
                child: Center(
                  child: Image.asset(
                    widget.secondImagePath,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            // Cross Icon Button (for closing the popup)
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                icon: Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: widget.onClose,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== CHORE GAME POPUP ====================

class ChoreGamePopup extends StatefulWidget {
  final ChoreCard choreCard;
  final Function(ChoreCard) onChoreComplete;
  final VoidCallback onClose;

  const ChoreGamePopup({
    super.key,
    required this.choreCard,
    required this.onChoreComplete,
    required this.onClose,
  });

  @override
  _ChoreGamePopupState createState() => _ChoreGamePopupState();
}

class _ChoreGamePopupState extends State<ChoreGamePopup>
    with SingleTickerProviderStateMixin {
  double opacity1 = 0.0;
  double opacity2 = 0.0;
  bool showChoreDetails = false;

  @override
  void initState() {
    super.initState();

    // Show the first image (cleaning supplies)
    Future.delayed(Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          opacity1 = 1.0;
        });
      }
    });

    // Show the second image (full chore card with instruction) after a delay
    Future.delayed(Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          opacity1 = 0.0; // Fade out first image
          showChoreDetails = true; // Switch to showing chore details
        });
      }

      // After transition, fade in chore details
      Future.delayed(Duration(milliseconds: 300), () {
        if (mounted) {
          setState(() {
            opacity2 = 1.0;
          });
        }
      });

      // Auto apply chore effect after showing the details
      Future.delayed(Duration(seconds: 3), () {
        widget.onChoreComplete(widget.choreCard);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: double.infinity,
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Color(0xFF8B4513), // Brown color for chore theme
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black, width: 4),
          boxShadow: [
            BoxShadow(
              color: Colors.black45,
              blurRadius: 15,
              spreadRadius: 3,
            )
          ],
        ),
        child: Stack(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.choreCard.title,
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 20),
                    if (!showChoreDetails)
                      AnimatedOpacity(
                        opacity: opacity1,
                        duration: Duration(seconds: 1),
                        child: Image.asset(
                          widget.choreCard.firstImagePath,
                          width: MediaQuery.of(context).size.width * 0.6,
                          height: MediaQuery.of(context).size.width * 0.6,
                          fit: BoxFit.contain,
                        ),
                      ),
                    if (showChoreDetails)
                      AnimatedOpacity(
                        opacity: opacity2,
                        duration: Duration(seconds: 1),
                        child: Column(
                          children: [
                            Text(
                              widget.choreCard.instruction,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 20),
                            Image.asset(
                              widget.choreCard.firstImagePath,
                              width: MediaQuery.of(context).size.width * 0.5,
                              height: MediaQuery.of(context).size.width * 0.5,
                              fit: BoxFit.contain,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // Footer text
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  "SAY IT NOW SELF-LOVE KIDS LLC GAME",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                icon: Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: widget.onClose,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== REWARD GAME POPUP ====================

class RewardGamePopup extends StatefulWidget {
  final RewardCard rewardCard;
  final Function(RewardCard) onRewardComplete;
  final VoidCallback onClose;

  const RewardGamePopup({
    super.key,
    required this.rewardCard,
    required this.onRewardComplete,
    required this.onClose,
  });

  @override
  _RewardGamePopupState createState() => _RewardGamePopupState();
}

class _RewardGamePopupState extends State<RewardGamePopup> {
  double opacity1 = 0.0;
  double opacity2 = 0.0;

  @override
  void initState() {
    super.initState();

    // Show the first image immediately
    Future.delayed(Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          opacity1 = 1.0;
        });
      }
    });

    // Show the second image (reward details) after delay
    Future.delayed(Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          opacity2 = 1.0;
        });
      }

      // Auto apply reward after showing details
      Future.delayed(Duration(seconds: 3), () {
        widget.onRewardComplete(widget.rewardCard);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: double.infinity,
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Color(0xFFFFD700), // Gold color for reward theme
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black, width: 4),
          boxShadow: [
            BoxShadow(
              color: Colors.black45,
              blurRadius: 15,
              spreadRadius: 3,
            )
          ],
        ),
        child: Stack(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.rewardCard.title,
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 20),
                    AnimatedOpacity(
                      opacity: opacity2,
                      duration: Duration(seconds: 1),
                      child: Text(
                        widget.rewardCard.instruction,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    AnimatedOpacity(
                      opacity: opacity1,
                      duration: Duration(seconds: 1),
                      child: Image.asset(
                        widget.rewardCard.imagePath,
                        width: MediaQuery.of(context).size.width * 0.5,
                        height: MediaQuery.of(context).size.width * 0.5,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Footer text
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  "SAY IT NOW SELF-LOVE KIDS LLC GAME",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                icon: Icon(Icons.close, color: Colors.black, size: 30),
                onPressed: widget.onClose,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== BEHAVIOR POPUP ====================

class BehaviorPopup extends StatefulWidget {
  final void Function(BehaviorDefinition def) onResolved;
  final VoidCallback onClose;

  const BehaviorPopup({
    super.key,
    required this.onResolved,
    required this.onClose,
  });

  @override
  _BehaviorPopupState createState() => _BehaviorPopupState();
}

class _BehaviorPopupState extends State<BehaviorPopup> {
  BehaviorDefinition? selected;
  String currentImage = 'assets/behavior/behavior_01.png';
  bool _mounted = true;

  @override
  void initState() {
    super.initState();
    // Pick a random behavior after showing intro
    Future.delayed(Duration(seconds: 2), () {
      if (_mounted) {
        final random = Random();
        final randomBehavior = kBehaviorCards[random.nextInt(kBehaviorCards.length)];
        setState(() {
          selected = randomBehavior;
          currentImage = randomBehavior.imagePath;
        });

        // Auto-apply after 3 seconds
        Future.delayed(Duration(seconds: 3), () {
          if (_mounted && selected != null) {
            widget.onResolved(selected!);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _mounted = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: double.infinity,
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: Color(0xFF1FA51F), // Green background
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black, width: 4),
          boxShadow: [
            BoxShadow(
              color: Colors.black45,
              blurRadius: 15,
              spreadRadius: 3,
            )
          ],
        ),
        child: Stack(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "BEHAVIOR",
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 20),
                    if (selected != null)
                      Text(
                        selected!.description,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    SizedBox(height: 20),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.7,
                      height: MediaQuery.of(context).size.width * 0.7,
                      child: Image.asset(
                        currentImage,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Footer text
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  "SAY IT NOW SELF-LOVE KIDS LLC GAME",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                icon: Icon(Icons.close, color: Colors.black, size: 30),
                onPressed: widget.onClose,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== PENALTY POPUP ====================

class PenaltyPopup extends StatefulWidget {
  final VoidCallback onClose;
  final Function() onPenaltyApplied;

  const PenaltyPopup({
    super.key,
    required this.onClose,
    required this.onPenaltyApplied,
  });

  @override
  _PenaltyPopupState createState() => _PenaltyPopupState();
}

class _PenaltyPopupState extends State<PenaltyPopup>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );

    _scaleAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _animationController.forward();

    // Apply the penalty automatically after a short delay
    Future.delayed(Duration(seconds: 2), () {
      if (mounted) {
        widget.onPenaltyApplied();
        widget.onClose();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.black, width: 4),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.warning, color: Colors.white, size: 80),
              SizedBox(height: 20),
              Text(
                'PENALTY!',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'You landed on a penalty square!\nPay \$10 to the bank.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== BONUS POPUP ====================

class BonusPopup extends StatefulWidget {
  final VoidCallback onClose;
  final Function() onBonusApplied;

  const BonusPopup({
    super.key,
    required this.onClose,
    required this.onBonusApplied,
  });

  @override
  _BonusPopupState createState() => _BonusPopupState();
}

class _BonusPopupState extends State<BonusPopup>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );

    _scaleAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _animationController.forward();

    // Apply the bonus automatically after a short delay
    Future.delayed(Duration(seconds: 2), () {
      if (mounted) {
        widget.onBonusApplied();
        widget.onClose();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.green,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.black, width: 4),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.star, color: Colors.yellow, size: 80),
              SizedBox(height: 20),
              Text(
                'BONUS!',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'You landed on a bonus square!\nCollect \$15 from the bank!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
