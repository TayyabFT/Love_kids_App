import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' show min, max, Random;
import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'game_leaderboard_screen.dart';

// Main GameScreen widget that manages the game flow
class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  // Game state
  bool showWelcome = true;
  bool showCharacterSelection = false;
  bool showGameBoard = false;
  List<PlayerData> _selectedPlayers = [];

  // Orientation popup state
  bool _showOrientationPopup = false;
  Orientation? _currentOrientation;

  @override
  void initState() {
    super.initState();
    // Allow all orientations but we'll show popup for landscape
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    // Start with welcome screen and navigate to character selection after 2 seconds
    Timer(const Duration(seconds: 2), () {
      setState(() {
        showWelcome = false;
        showCharacterSelection = true;
      });
    });
  }

  @override
  void dispose() {
    // Reset orientation to allow all orientations when leaving the game screen
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  void startGame(List<PlayerData> selectedPlayers) {
    // Reset question tracking when starting a new game
    EducationQuestionBank.resetQuestionTracking();

    setState(() {
      _selectedPlayers = selectedPlayers;
      showCharacterSelection = false;
      showGameBoard = true;
    });
  }

  // Check if device is in landscape mode
  bool _isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }

  // Show orientation popup if in landscape mode
  void _checkOrientationAndShowPopup(BuildContext context) {
    if (_isLandscape(context) && showGameBoard && !_showOrientationPopup) {
      setState(() {
        _showOrientationPopup = true;
      });

      // Add a small delay to ensure the dialog shows properly
      Future.delayed(Duration(milliseconds: 100), () {
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                title: Row(
                  children: [
                    Icon(Icons.screen_rotation, color: Colors.orange, size: 30),
                    SizedBox(width: 10),
                    Text(
                      'Rotate Your Device',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.phone_android, size: 60, color: Colors.blue),
                    SizedBox(height: 15),
                    Text(
                      'Please rotate your device to portrait mode for the best gaming experience!',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      setState(() {
                        _showOrientationPopup = false;
                      });
                    },
                    child: Text(
                      'OK',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ],
              );
            },
          ).then((_) {
            if (mounted) {
              setState(() {
                _showOrientationPopup = false;
              });
            }
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get current orientation
    final currentOrientation = MediaQuery.of(context).orientation;

    // Check if orientation changed and show popup if needed
    if (_currentOrientation != currentOrientation) {
      _currentOrientation = currentOrientation;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkOrientationAndShowPopup(context);
      });
    }

    return MaterialApp(
      title: 'SAY IT NOW SELF-LOVE KIDS APP',
      theme: ThemeData(primarySwatch: Colors.blue),
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body:
            showWelcome
                ? WelcomeScreen()
                : showCharacterSelection
                ? CharacterSelectionScreen(onGameStart: startGame)
                : CirclePatternPage(players: _selectedPlayers),
      ),
    );
  }
}

// Apply behavior effects to the active player and game state
extension on _CirclePatternState {
  void _applyBehaviorEffects(PlayerData player, BehaviorDefinition def) {
    print("=== BEHAVIOR EFFECTS DEBUG ===");
    print("Player: ${player.name} at position ${player.position}");
    print("Number of effects: ${def.effects.length}");

    for (final effect in def.effects) {
      print("Applying effect: ${effect.type}");

      switch (effect.type) {
        case BehaviorEffectType.collectFromBank:
          player.addMoney(effect.amount);
          print("  Collected ${effect.amount} from bank");
          break;
        case BehaviorEffectType.collectFromParents:
          // Assume 2 parents
          player.addMoney(effect.amount * 2);
          print("  Collected ${effect.amount * 2} from parents");
          break;
        case BehaviorEffectType.collectFromEachPlayer:
          int collected = 0;
          for (final other in widget.players) {
            if (other == player) continue;
            other.payWithLoan(effect.amount);
            collected += effect.amount;
          }
          if (collected > 0) player.addMoney(collected);
          print("  Collected $collected from other players");
          break;
        case BehaviorEffectType.payBank:
          player.payWithLoan(effect.amount);
          print("  Paid ${effect.amount} to bank");
          break;
        case BehaviorEffectType.payParents:
          // Pay total to parents (2 x amount)
          player.payWithLoan(effect.amount * 2);
          print("  Paid ${effect.amount * 2} to parents");
          break;
        case BehaviorEffectType.payEachPlayer:
          for (final other in widget.players) {
            if (other == player) continue;
            player.payWithLoan(effect.amount);
            other.addMoney(effect.amount);
          }
          print("  Paid ${effect.amount} to each other player");
          break;
        case BehaviorEffectType.moveAhead:
          print("  Moving ${effect.amount} steps ahead");
          _movePlayerSteps(player, effect.amount);
          break;
        case BehaviorEffectType.goToDetention:
          print("  Behavior detention penalty applied (no jail move)");
          player.skipNextTurn = true;
          break;
        case BehaviorEffectType.loseTurn:
          player.skipNextTurn = true;
          print("  Player will skip next turn");
          break;
      }
    }

    print("Final player position: ${player.position}");
    print("==============================");

    setState(() {});

    // CRITICAL FIX: Check winner after frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _checkForWinner();
      }
    });
  }
}

// Data class to hold player information with money
class PlayerData {
  final String name;
  final Color color;
  final int characterIndex;
  final String imagePath;

  // Money properties
  int totalMoney = 100; // Starting money
  int ones = 5; // $1 x 5
  int fives = 3; // $5 x 3
  int tens = 1; // $10 x 1
  int twenties = 1; // $20 x 1
  int fifties = 1; // $50 x 1
  int hundreds = 0; // $100 x 0

  // Add player position property
  int position = 0; // Starting position (0 = first square)

  // Add turn tracking
  int turnsCompleted = 0;

  int lapsCompleted = 0;

  // Add question history tracking
  List<QuestionHistoryItem> questionHistory = [];

  // Skip turn property
  bool skipNextTurn = false;

  int debt = 0;
  bool inJail = false;
  int jailFeeDue = 0;

  PlayerData({
    required this.name,
    required this.color,
    required this.characterIndex,
    required this.imagePath,
  });

  // Calculate total money based on denominations
  void recalculateTotal() {
    totalMoney =
        ones +
        (fives * 5) +
        (tens * 10) +
        (twenties * 20) +
        (fifties * 50) +
        (hundreds * 100) -
        debt;
  }

  // Add money by denomination
  void addMoney(int amount) {
    if (debt > 0 && amount > 0) {
      int applied = amount < debt ? amount : debt;
      debt -= applied;
      amount -= applied;
    }
    // Add money in the most efficient way (largest denominations first)
    while (amount >= 100 && amount > 0) {
      hundreds++;
      amount -= 100;
    }

    while (amount >= 50 && amount > 0) {
      fifties++;
      amount -= 50;
    }

    while (amount >= 20 && amount > 0) {
      twenties++;
      amount -= 20;
    }

    while (amount >= 10 && amount > 0) {
      tens++;
      amount -= 10;
    }

    while (amount >= 5 && amount > 0) {
      fives++;
      amount -= 5;
    }

    while (amount >= 1 && amount > 0) {
      ones++;
      amount -= 1;
    }

    recalculateTotal();
  }

  // Subtract money
  bool subtractMoney(int amount) {
    int available =
        ones +
        (fives * 5) +
        (tens * 10) +
        (twenties * 20) +
        (fifties * 50) +
        (hundreds * 100);
    if (amount > available) {
      return false; // Not enough money
    }

    // Make a copy of current denominations
    int tempOnes = ones;
    int tempFives = fives;
    int tempTens = tens;
    int tempTwenties = twenties;
    int tempFifties = fifties;
    int tempHundreds = hundreds;

    // Take money from largest denominations first
    while (amount >= 100 && tempHundreds > 0) {
      tempHundreds--;
      amount -= 100;
    }

    while (amount >= 50 && tempFifties > 0) {
      tempFifties--;
      amount -= 50;
    }

    while (amount >= 20 && tempTwenties > 0) {
      tempTwenties--;
      amount -= 20;
    }

    while (amount >= 10 && tempTens > 0) {
      tempTens--;
      amount -= 10;
    }

    while (amount >= 5 && tempFives > 0) {
      tempFives--;
      amount -= 5;
    }

    while (amount >= 1 && tempOnes > 0) {
      tempOnes--;
      amount -= 1;
    }

    // If we couldn't subtract the full amount, we need to make change
    if (amount > 0) {
      // Try to make change from smallest bill that can cover the amount
      if (amount > 0 && amount <= 5 && tempFives > 0) {
        tempFives--;
        tempOnes += 5 - amount;
        amount = 0;
      } else if (amount > 0 && amount <= 10 && tempTens > 0) {
        tempTens--;
        // Give change in smaller denominations
        int change = 10 - amount;
        while (change >= 5 && tempFives < 100) {
          tempFives++;
          change -= 5;
        }
        tempOnes += change;
        amount = 0;
      } else if (amount > 0 && amount <= 20 && tempTwenties > 0) {
        tempTwenties--;
        // Give change
        int change = 20 - amount;
        while (change >= 10 && tempTens < 100) {
          tempTens++;
          change -= 10;
        }
        while (change >= 5 && tempFives < 100) {
          tempFives++;
          change -= 5;
        }
        tempOnes += change;
        amount = 0;
      } else if (amount > 0 && amount <= 50 && tempFifties > 0) {
        tempFifties--;
        // Give change
        int change = 50 - amount;
        while (change >= 20 && tempTwenties < 100) {
          tempTwenties++;
          change -= 20;
        }
        while (change >= 10 && tempTens < 100) {
          tempTens++;
          change -= 10;
        }
        while (change >= 5 && tempFives < 100) {
          tempFives++;
          change -= 5;
        }
        tempOnes += change;
        amount = 0;
      } else if (amount > 0 && amount <= 100 && tempHundreds > 0) {
        tempHundreds--;
        // Give change
        int change = 100 - amount;
        while (change >= 50 && tempFifties < 100) {
          tempFifties++;
          change -= 50;
        }
        while (change >= 20 && tempTwenties < 100) {
          tempTwenties++;
          change -= 20;
        }
        while (change >= 10 && tempTens < 100) {
          tempTens++;
          change -= 10;
        }
        while (change >= 5 && tempFives < 100) {
          tempFives++;
          change -= 5;
        }
        tempOnes += change;
        amount = 0;
      }
    }

    if (amount == 0) {
      // Apply the changes
      ones = tempOnes;
      fives = tempFives;
      tens = tempTens;
      twenties = tempTwenties;
      fifties = tempFifties;
      hundreds = tempHundreds;
      recalculateTotal();
      return true;
    }

    return false; // Couldn't make exact change
  }

  // Pay even if cash is insufficient; convert shortfall to debt
  bool payWithLoan(int amount) {
    int available =
        ones +
        (fives * 5) +
        (tens * 10) +
        (twenties * 20) +
        (fifties * 50) +
        (hundreds * 100);
    if (available >= amount) {
      // Try to subtract money normally
      bool success = subtractMoney(amount);
      if (success) {
        return true;
      } else {
        // If subtractMoney fails (change-making issue), convert entire amount to debt
        // This ensures payment ALWAYS succeeds
        debt += amount;
        recalculateTotal();
        return true;
      }
    } else {
      if (available > 0) {
        // Use all available cash first
        subtractMoney(available);
      }
      int shortfall = amount - available;
      debt += shortfall;
      recalculateTotal();
      return true;
    }
  }

  // Method to add completed turn
  void completeTurn() {
    turnsCompleted++;
  }

  // Method to add question to history
  void addQuestionToHistory(
    EducationQuestion question,
    int answeredIndex,
    bool wasCorrect,
  ) {
    questionHistory.add(
      QuestionHistoryItem(
        question: question,
        answeredIndex: answeredIndex,
        wasCorrect: wasCorrect,
      ),
    );
  }
}

// Class to store question history items
class QuestionHistoryItem {
  final EducationQuestion question;
  final int answeredIndex;
  final bool wasCorrect;

  QuestionHistoryItem({
    required this.question,
    required this.answeredIndex,
    required this.wasCorrect,
  });
}

// Add this code right after your imports

// Define reward types
enum ChoreRewardType {
  collectFromBank, // Collect money from the bank
  collectFromPlayers, // Collect money from all players
  collectFromParents, // Collect money from parents
  collectFromPlayerAhead, // Collect from players ahead of you
}

// Chore card model
class ChoreCard {
  final String title = "CHORES";
  final String instruction;
  final String firstImagePath; // First image (cleaning supplies)
  final ChoreRewardType rewardType;
  final int rewardAmount;
  final String targetType;

  ChoreCard({
    required this.instruction,
    required this.firstImagePath,
    required this.rewardType,
    required this.rewardAmount,
    required this.targetType,
  });
}

// Full chore catalog — all cards stay in rotation via getRandomChore().
final List<ChoreCard> kAllChoreCards = [
  ChoreCard(
    instruction: "Do the laundry and earn \$7 from each player ahead of you.",
    firstImagePath: "assets/rewards/chores_02.png",
    rewardType: ChoreRewardType.collectFromPlayerAhead,
    rewardAmount: 7,
    targetType: "each player ahead of you",
  ),
  ChoreCard(
    instruction: "Take the trash out home and earn \$3 from each player.",
    firstImagePath: "assets/rewards/chores_03.png",
    rewardType: ChoreRewardType.collectFromPlayers,
    rewardAmount: 3,
    targetType: "each player",
  ),
  ChoreCard(
    instruction: "Mop and sweep the floor and earn \$12 from the bank.",
    firstImagePath: "assets/rewards/chores_04.png",
    rewardType: ChoreRewardType.collectFromBank,
    rewardAmount: 12,
    targetType: "the bank",
  ),
  ChoreCard(
    instruction: "You washed the car, you earn \$10 from each player.",
    firstImagePath: "assets/rewards/chores_05.png",
    rewardType: ChoreRewardType.collectFromPlayers,
    rewardAmount: 10,
    targetType: "each player",
  ),
  ChoreCard(
    instruction: "Clean your refrigerator and earn \$5 from the bank.",
    firstImagePath: "assets/rewards/chores_06.png",
    rewardType: ChoreRewardType.collectFromBank,
    rewardAmount: 5,
    targetType: "the bank",
  ),
  ChoreCard(
    instruction: "Vacuum your bedroom and earn \$1 from each parent.",
    firstImagePath: "assets/rewards/chores_07.png",
    rewardType: ChoreRewardType.collectFromParents,
    rewardAmount: 1,
    targetType: "each parent",
  ),
  ChoreCard(
    instruction: "Clean bathroom and earn \$4 from the bank.",
    firstImagePath: "assets/rewards/chores_08.png",
    rewardType: ChoreRewardType.collectFromBank,
    rewardAmount: 4,
    targetType: "the bank",
  ),
  ChoreCard(
    instruction: "Clean kitchen and earn \$2 from parents.",
    firstImagePath: "assets/rewards/chores_09.png",
    rewardType: ChoreRewardType.collectFromParents,
    rewardAmount: 2,
    targetType: "parents",
  ),
];

/// Chore squares on the board (reduced so education is ~74% of card squares).
final Set<int> choreSquarePositions = {3, 13, 23, 33};

enum RewardType {
  collectFromBank, // Collect money from the bank
  collectFromParents, // Collect money from parents
  giftCard, // Special gift card reward
}

// Behavior types and effects
enum BehaviorKind { positive, negative }

enum BehaviorEffectType {
  collectFromBank,
  collectFromParents,
  collectFromEachPlayer,
  payBank,
  payParents,
  payEachPlayer,
  moveAhead,
  goToDetention,
  loseTurn,
}

class BehaviorDefinition {
  final String imagePath;
  final BehaviorKind kind;
  final String description;
  final List<BehaviorEffect> effects;

  const BehaviorDefinition({
    required this.imagePath,
    required this.kind,
    required this.description,
    required this.effects,
  });
}

class BehaviorEffect {
  final BehaviorEffectType type;
  final int amount; // For money or steps; 0 if N/A

  const BehaviorEffect({required this.type, this.amount = 0});
}

// Intro image (01) will be shown first, then we randomly pick one from below
final List<BehaviorDefinition> kBehaviorCards = [
  // 02 - Helped change the baby diaper
  BehaviorDefinition(
    imagePath: 'assets/behavior/behavior_02.png',
    kind: BehaviorKind.positive,
    description:
        "You helped change the baby diaper. Earn \$2 from both parents.",
    effects: [
      BehaviorEffect(type: BehaviorEffectType.collectFromParents, amount: 2),
    ],
  ),
  // 03 - Wrote your name correctly
  BehaviorDefinition(
    imagePath: 'assets/behavior/behavior_03.png',
    kind: BehaviorKind.positive,
    description:
        "You wrote your name correctly. Each player gives you a hug and \$1.",
    effects: [
      BehaviorEffect(type: BehaviorEffectType.collectFromEachPlayer, amount: 1),
    ],
  ),
  // 04 - Helped a friend with schoolwork
  BehaviorDefinition(
    imagePath: 'assets/behavior/behavior_04.png',
    kind: BehaviorKind.positive,
    description:
        "You helped a friend with schoolwork. You earn \$2 from each player.",
    effects: [
      BehaviorEffect(type: BehaviorEffectType.collectFromEachPlayer, amount: 2),
    ],
  ),
  // 05 - Untruthful about homework
  BehaviorDefinition(
    imagePath: 'assets/behavior/behavior_05.png',
    kind: BehaviorKind.negative,
    description:
        "You were untruthful about doing your homework. Pay parents \$5 each and lose a turn.",
    effects: [
      BehaviorEffect(type: BehaviorEffectType.payParents, amount: 5),
      BehaviorEffect(type: BehaviorEffectType.loseTurn),
    ],
  ),
  // 05
  BehaviorDefinition(
    imagePath: 'assets/behavior/behavior_06.png',
    kind: BehaviorKind.negative,
    description: "You used profanity 'a Bad word' pay each player \$3.",
    effects: [
      BehaviorEffect(type: BehaviorEffectType.payEachPlayer, amount: 3),
    ],
  ),
  // 06
  BehaviorDefinition(
    imagePath: 'assets/behavior/behavior_07.png',
    kind: BehaviorKind.negative,
    description: "You did not complete your chore. Pay bank \$10.",
    effects: [BehaviorEffect(type: BehaviorEffectType.payBank, amount: 10)],
  ),
  // 07
  BehaviorDefinition(
    imagePath: 'assets/behavior/behavior_08.png',
    kind: BehaviorKind.negative,
    description: "You skipped class. Pay each player \$5.",
    effects: [
      BehaviorEffect(type: BehaviorEffectType.payEachPlayer, amount: 5),
    ],
  ),
  // 08
  BehaviorDefinition(
    imagePath: 'assets/behavior/behavior_09.png',
    kind: BehaviorKind.negative,
    description:
        "You acted out in class and did not follow instructions. Pay each parent \$10 and lose a turn.",
    effects: [
      BehaviorEffect(type: BehaviorEffectType.payParents, amount: 10),
      BehaviorEffect(type: BehaviorEffectType.loseTurn),
    ],
  ),
  // 09
  BehaviorDefinition(
    imagePath: 'assets/behavior/behavior_10.png',
    kind: BehaviorKind.negative,
    description:
        "You got caught stealing. Go to Behavior Detention Center space and lose 2 turns. Pay bank \$20.",
    effects: [
      BehaviorEffect(type: BehaviorEffectType.goToDetention),
      BehaviorEffect(type: BehaviorEffectType.loseTurn),
      BehaviorEffect(type: BehaviorEffectType.payBank, amount: 20),
    ],
  ),
  // 10
  BehaviorDefinition(
    imagePath: 'assets/behavior/behavior_11.png',
    kind: BehaviorKind.positive,
    description:
        "You helped an elderly person with crossing the street. Move ahead 1 space. Earn \$5 from the bank.",
    effects: [
      BehaviorEffect(type: BehaviorEffectType.moveAhead, amount: 1),
      BehaviorEffect(type: BehaviorEffectType.collectFromBank, amount: 5),
    ],
  ),
  // 11
  BehaviorDefinition(
    imagePath: 'assets/behavior/behavior_12.png',
    kind: BehaviorKind.negative,
    description:
        "You were fighting in school. Apologize to your teacher and parents. Pay each player \$1.",
    effects: [
      BehaviorEffect(type: BehaviorEffectType.payEachPlayer, amount: 1),
    ],
  ),
  // 12 (fallback generic positive)
  // Removed generic; all 02-12 now mapped to specific behaviors
];

// Reward card model
class RewardCard {
  final String title = "REWARDS";
  final String instruction;
  final String imagePath; // Image for the reward
  final RewardType rewardType;
  final int rewardAmount;
  final String targetType;

  RewardCard({
    required this.instruction,
    required this.imagePath,
    required this.rewardType,
    required this.rewardAmount,
    required this.targetType,
  });
}

// Definition for game reward images with suggested payout options
class GameRewardDefinition {
  final String imagePath;
  final List<int> possiblePayouts; // e.g., [3,5,7,10,15]
  final String title; // short label for UI flavor

  const GameRewardDefinition({
    required this.imagePath,
    required this.possiblePayouts,
    required this.title,
  });
}

// All reward images (01 is intro), 02-12 are candidates
final List<GameRewardDefinition> kGameRewards = [
  // index 0 is reserved for intro (01)
  const GameRewardDefinition(
    imagePath: "assets/game_reward/rewards_02.png",
    possiblePayouts: [3, 5, 7, 10],
    title: "Treat Time",
  ),
  const GameRewardDefinition(
    imagePath: "assets/game_reward/rewards_03.png",
    possiblePayouts: [3, 5, 7, 12],
    title: "Star Player",
  ),
  const GameRewardDefinition(
    imagePath: "assets/game_reward/rewards_04.png",
    possiblePayouts: [5, 7, 10, 15],
    title: "Great Job",
  ),
  const GameRewardDefinition(
    imagePath: "assets/game_reward/rewards_05.png",
    possiblePayouts: [3, 4, 6, 8, 10],
    title: "Surprise Gift",
  ),
  const GameRewardDefinition(
    imagePath: "assets/game_reward/rewards_06.png",
    possiblePayouts: [5, 7, 9, 11, 13],
    title: "Bonus Bucks",
  ),
  const GameRewardDefinition(
    imagePath: "assets/game_reward/rewards_07.png",
    possiblePayouts: [3, 5, 8, 12],
    title: "Lucky Day",
  ),
  const GameRewardDefinition(
    imagePath: "assets/game_reward/rewards_08.png",
    possiblePayouts: [4, 6, 9, 14],
    title: "Level Up",
  ),
  const GameRewardDefinition(
    imagePath: "assets/game_reward/rewards_09.png",
    possiblePayouts: [3, 5, 7, 10, 15],
    title: "Win Win",
  ),
  const GameRewardDefinition(
    imagePath: "assets/game_reward/rewards_10.png",
    possiblePayouts: [6, 8, 10, 12],
    title: "Power Up",
  ),
  const GameRewardDefinition(
    imagePath: "assets/game_reward/rewards_11.png",
    possiblePayouts: [3, 5, 7, 9, 11],
    title: "Big Smile",
  ),
  const GameRewardDefinition(
    imagePath: "assets/game_reward/rewards_12.png",
    possiblePayouts: [5, 10, 15, 20],
    title: "Jackpot Jr.",
  ),
];

// Reward definition with explicit description and amount
class RewardDefinition {
  final String imagePath;
  final String description;
  final int amount;

  const RewardDefinition({
    required this.imagePath,
    required this.description,
    required this.amount,
  });
}

// Full reward catalog for random selection
final List<RewardDefinition> kRewardCards = [
  // 02 - Exercise and diet routine
  RewardDefinition(
    imagePath: 'assets/game_reward/rewards_02.png',
    description:
        "You stayed with your exercise and diet routine plan. Earn \$25.00 Gift Card from Say it Now Self-Love Bank",
    amount: 25,
  ),
  // 03 - Straight A's on report card
  RewardDefinition(
    imagePath: 'assets/game_reward/rewards_03.png',
    description:
        "You got straight A's on your report card. You earn \$10.00 from each parent.",
    amount: 10,
  ),
  // 04 - Helped sibling with homework
  RewardDefinition(
    imagePath: 'assets/game_reward/rewards_04.png',
    description:
        "You helped your sibling with her homework. You earn an extra hour to stay up late.",
    amount: 0,
  ),
  // 05 - Helped mom clean garage and kitchen
  RewardDefinition(
    imagePath: 'assets/game_reward/rewards_05.png',
    description:
        "You helped your mom clean the garage and kitchen. You earn a free movie and popcorn.",
    amount: 0,
  ),
  // 06 - Helped with planting garden (gardening card — rewards_06.png)
  RewardDefinition(
    imagePath: 'assets/game_reward/rewards_06.png',
    description:
        "You helped with planting the garden. You earn free ice cream.",
    amount: 0,
  ),
  // 07 - Encouraged a friend (spa / nails)
  RewardDefinition(
    imagePath: 'assets/game_reward/rewards_07.png',
    description:
        "You encouraged a friend that they could do a task. You receive spa time to get nails done.",
    amount: 0,
  ),
  // 08 - Helped teacher clean desks and chalkboard
  RewardDefinition(
    imagePath: 'assets/game_reward/rewards_08.png',
    description:
        "You helped your teacher with cleaning the desks and chalk board. You earn extra snacks.",
    amount: 0,
  ),
  // 09 - Got up on time and helped feed brother
  RewardDefinition(
    imagePath: 'assets/game_reward/rewards_09.png',
    description:
        "You got up on time for school and helped feed your brother. You earn \$2.00 from the bank.",
    amount: 2,
  ),
  // 10 - Helped lost student (sticker — 0 points)
  RewardDefinition(
    imagePath: 'assets/game_reward/rewards_10.png',
    description:
        "You helped a student lost in school. You receive a free heart sticker.",
    amount: 0,
  ),
  // 11 - Helped crying student (hug — 0 points)
  RewardDefinition(
    imagePath: 'assets/game_reward/rewards_11.png',
    description:
        "You helped a student crying at school. You receive a hug from both your parents.",
    amount: 0,
  ),
  // 12 - Won soccer game (pizza — 0 points)
  RewardDefinition(
    imagePath: 'assets/game_reward/rewards_12.png',
    description: "You won your soccer game. You earn a pizza treat.",
    amount: 0,
  ),
];

// Reward square intro card (actual reward is picked randomly from kRewardCards).
Map<int, RewardCard> rewardCards = {
  15: RewardCard(
    instruction:
        "Congratulations! You've earned a special reward! Collect your prize and continue your journey.",
    imagePath: "assets/game_reward/rewards_01.png",
    rewardType: RewardType.giftCard,
    rewardAmount: 25,
    targetType: "Say it Now Self-Love Bank",
  ),
};

final Set<int> rewardSquarePositions = {7, 15, 19, 37};

enum QuestionCategory {
  history,
  science,
  math,
  english,
  spelling,
  geography,
  sports,
  tvShow,
  hbcu,
  bible,
}

// Education Review question model
class EducationQuestion {
  final String question;
  final List<String> options;
  final int correctAnswerIndex; // Index of the correct answer in options list
  final QuestionCategory category;
  final String imagePath; // Path to the image file (edu_01.png, etc.)

  EducationQuestion({
    required this.question,
    required this.options,
    required this.correctAnswerIndex,
    required this.category,
    required this.imagePath,
  });
}

class EducationQuestionBank {
  // Random generator for questions
  static final Random _random = Random();

  // List of all history questions
  static final List<EducationQuestion> historyQuestions = [
    // Your existing history questions here...
    EducationQuestion(
      question:
          'What producer, director, screenplay writer and actor established their own production company on the former Army Military base, Fort McPherson in Atlanta, Georgia?',
      options: [
        'Ava Duvernay',
        'John Singleton',
        'Antoine Fuqua',
        'Tyler Perry',
        'Will Packer',
      ],
      correctAnswerIndex: 3,
      category: QuestionCategory.history,
      imagePath: 'assets/rewards/edu_02.png',
    ),

    EducationQuestion(
      question:
          'Name the female rapper, singer and actress who played in movies as a physical therapist and cab driver.',
      options: [
        'Dana Owens AKA “Queen Latifah”',
        'Cardi B',
        'Gloria "Glorilla" Woods',
        'Megan The Stallion',
        'Nicki Minaj',
      ],
      correctAnswerIndex: 0,
      category: QuestionCategory.history,
      imagePath: 'assets/rewards/edu_03.png',
    ),

    EducationQuestion(
      question:
          'What is the name of the country/pop singer who was a member of a female group who later became an actress in Dreamgirls and Obsessed movie?',
      options: [
        'Aretha Franklin',
        'Kelly Rowland',
        'Dolly Parton',
        'Beyoncé Knowles-Carter',
      ],
      correctAnswerIndex: 3,
      category: QuestionCategory.history,
      imagePath: 'assets/rewards/edu_04.png',
    ),

    EducationQuestion(
      question:
          'Who was born in Mississippi, employed as a writer, news anchor, actress, producer, and created OWN and founder of a leadership academy for young women in Africa?',
      options: [
        'Viola Davis',
        'Caroline Kennedy',
        'Oprah "Opah" Winfrey',
        'Melinda French Gates',
      ],
      correctAnswerIndex: 2,
      category: QuestionCategory.history,
      imagePath: 'assets/rewards/edu_08.png',
    ),

    EducationQuestion(
      question:
          'Who was a great writer, poet, actress, dancer, and recipient of the Pulitzer Prize and Presidential Medal of Freedom Award?',
      options: [
        'Shirley Caesar',
        'Angela Bassett',
        'Cicely Tyson',
        'Maya Angelo',
      ],
      correctAnswerIndex: 3,
      category: QuestionCategory.history,
      imagePath: 'assets/rewards/edu_09.png',
    ),

    EducationQuestion(
      question:
          'Who served as the district attorney in 2004, elected attorney general of California and became the 49th Vice President of the USA in 2021?',
      options: [
        'Barbara Bush',
        'Mary Jane McLeod Bethune',
        'Betty White',
        'Kamala Devi Harris',
        'Marilyn Monroe',
      ],
      correctAnswerIndex: 3,
      category: QuestionCategory.history,
      imagePath: 'assets/rewards/edu_10.png',
    ),

    EducationQuestion(
      question:
          'Who was the first black woman born in Brooklyn, New York to be elected to the United States Congress in 1968 and later became the first candidate to run for a major-party nomination for President of the USA?',
      options: [
        'Madam C. J. Walker',
        'Rosa Parks',
        'Shirley Chisholm',
        'Michelle Obama',
        'Eleanor Roosevelt',
      ],
      correctAnswerIndex: 2,
      category: QuestionCategory.history,
      imagePath: 'assets/rewards/edu_11.png',
    ),

    EducationQuestion(
      question: 'Who was the first black president of the United States?',
      options: [
        'President John Lewis',
        'President James Jefferson',
        'President Barack Obama',
        'None of the above.',
      ],
      correctAnswerIndex: 2,
      category: QuestionCategory.history,
      imagePath: 'assets/rewards/edu_12.png',
    ),

    EducationQuestion(
      question:
          'What are the names of four sororities belonging to the Divine Nine Black Greek Sororities and Fraternities?',
      options: [
        'Alpha Phi Alpha, Zeta Phi Beta, Delta Sigma Theta and Sigma Gamma Rho',
        'Delta Sigma Theta, Alpha Kappa Alpha, Omega Psi Phi and Kappa Alpha Psi',
        'Alpha Phi Alpha, Iota Phi Theta, Delta Sigma Theta and Alpha Kappa Alpha',
        'Alpha Kappa Alpha, Delta Sigma Theta, Sigma Gamma Rho and Zeta Phi Beta.',
      ],
      correctAnswerIndex: 3,
      category: QuestionCategory.history,
      imagePath: 'assets/rewards/edu_13.png',
    ),

    EducationQuestion(
      question: 'Who were the first persons to create and fly an airplane?',
      options: [
        'The Simpsons sisters',
        'Johnson Brothers',
        'Wright Brothers',
        'None of the above',
      ],
      correctAnswerIndex: 2,
      category: QuestionCategory.history,
      imagePath: 'assets/rewards/edu_14.png',
    ),

    EducationQuestion(
      question: 'Who was Dr. Martin Luther King Jr?',
      options: [
        'A lawyer',
        'A Civil Rights Leader',
        'A pastor',
        'A Nobel Peace Award Prize Winner',
        'Both B, C, and D',
        'None of the above.',
      ],
      correctAnswerIndex: 4,
      category: QuestionCategory.history,
      imagePath: 'assets/rewards/edu_15.png',
    ),

    EducationQuestion(
      question:
          'What politician was born in Georgia and served as a veteran, governor, and president of the USA?',
      options: [
        'President Ronald Regan',
        'President Andrew Jackson',
        'President James Earl Carter Jr.',
        'President Franklin Roosevelt',
      ],
      correctAnswerIndex: 2,
      category: QuestionCategory.history,
      imagePath: 'assets/rewards/edu_16.png',
    ),

    EducationQuestion(
      question: 'Who was the first astronaut to walk on the moon for NASA?',
      options: [
        'Andrew Jackson',
        'Thomas Wilson',
        'Neil Armstrong',
        'All the above.',
      ],
      correctAnswerIndex: 2,
      category: QuestionCategory.history,
      imagePath: 'assets/rewards/edu_17.png',
    ),

    EducationQuestion(
      question:
          'Name three NBA players who played on the Los Angeles Lakers team and won championships.',
      options: [
        'Shaquille "Shaq" O\'Neal, Kobe Bryant and Larry Bird',
        'LeBron James, Kobe Bryant and Michael Jordan',
        'Scottie Pippen Sr., Earvin "Magic" Johnson Jr., and Kobe Bryant',
        'Kobe Bryant, Shaquille "Shaq" O\'Neal and LeBron James',
      ],
      correctAnswerIndex: 3,
      category: QuestionCategory.sports,
      imagePath: '',
    ),
    EducationQuestion(
      question:
          'Name the first black female gymnast that won gold medal awards during the 2012 and 2016 team and All-around Olympic Games in London and Rio de Janeiro.',
      options: [
        'Gabby Douglas',
        'Simone Biles',
        'Dianne Durham',
        'Jordyn Wieber',
      ],
      correctAnswerIndex: 0,
      category: QuestionCategory.sports,
      imagePath: '',
    ),
    EducationQuestion(
      question:
          'Name two sisters from California who played professional American tennis and won double title championships and gold medal awards in tennis?',
      options: [
        'Venus and Serena Jackson',
        'Manuela and Katerina Maleeva',
        'Serena and Venus Williams',
        'Agnieszka Radwanska and Serena Williams',
      ],
      correctAnswerIndex: 2,
      category: QuestionCategory.sports,
      imagePath: '',
    ),
  ];

  // List of all science questions
  static final List<EducationQuestion> scienceQuestions = [
    EducationQuestion(
      question: 'What makes up a cloud in the sky?',
      options: [
        'Rain and snow particle on the ground.',
        'Dirt particles and rain floating in the sky.',
        'Water drops and ice crystals floating in the sky.',
        'None of the above.',
      ],
      correctAnswerIndex: 2,
      category: QuestionCategory.science,
      imagePath: 'assets/rewards/edu_18.png',
    ),

    EducationQuestion(
      question: 'What is the chemical compound name for NaCl?',
      options: ['Sugar', 'Salt', 'Water', 'All the above.'],
      correctAnswerIndex: 1,
      category: QuestionCategory.science,
      imagePath: 'assets/rewards/edu_19.png',
    ),

    EducationQuestion(
      question: 'What is the chemical compound name for H2O?',
      options: ['Sugar', 'Soap', 'Water', 'All the above.'],
      correctAnswerIndex: 2,
      category: QuestionCategory.science,
      imagePath: 'assets/rewards/edu_20.png',
    ),

    EducationQuestion(
      question: 'What are the two elements\' names for Ag and Na?',
      options: [
        'Gold and Sodium',
        'Silver and Sodium',
        'Gold and Nitrogen',
        'None of the above.',
      ],
      correctAnswerIndex: 1,
      category: QuestionCategory.science,
      imagePath: 'assets/rewards/edu_21.png',
    ),

    EducationQuestion(
      question: 'What is biology?',
      options: [
        'Study of musical instruments.',
        'Study of dance.',
        'Study of living things and their vital processes of life.',
        'None of the above.',
      ],
      correctAnswerIndex: 2,
      category: QuestionCategory.science,
      imagePath: 'assets/rewards/edu_22.png',
    ),

    EducationQuestion(
      question: 'What is an atom?',
      options: [
        'Smallest part of a substance that cannot be broken down chemically.',
        'Is a particle that consists of a nucleus and electrons surrounded by electrons.',
        'Both A and B.',
        'None of the above',
      ],
      correctAnswerIndex: 2,
      category: QuestionCategory.science,
      imagePath: 'assets/rewards/edu_23.png',
    ),
  ];

  // List of all math questions
  static final List<EducationQuestion> mathQuestions = [
    EducationQuestion(
      question:
          'If a is equal to 2 and b is equal to 3 solve the algebra problem.\n6a(2 × b + 2)=__',
      options: ['91', '95', '96', '89'],
      correctAnswerIndex: 2,
      category: QuestionCategory.math,
      imagePath: 'assets/rewards/edu_24.png',
    ),
    EducationQuestion(
      question:
          'If a is equal to 2 and b is equal to 3 solve the algebra problem.\n7 - a + b = __',
      options: ['7', '8', '9', '5'],
      correctAnswerIndex: 1,
      category: QuestionCategory.math,
      imagePath: 'assets/rewards/edu_25.png',
    ),
    EducationQuestion(
      question:
          'If a is equal to 2 and b is equal to 3 solve the algebra problem.\n4( a + b + 7 ) = __',
      options: ['15', '48', '49', '28'],
      correctAnswerIndex: 1,
      category: QuestionCategory.math,
      imagePath: 'assets/rewards/edu_26.png',
    ),
    EducationQuestion(
      question: 'What is the square root of the math problem?\n√96 = __',
      options: ['9.251', '9.797', '8.976', '9.716'],
      correctAnswerIndex: 1,
      category: QuestionCategory.math,
      imagePath: 'assets/rewards/edu_27.png',
    ),
    EducationQuestion(
      question: 'What is the square root of the math problem?\n√27 = __',
      options: ['3.876', '5.197', '5.297', '5.196'],
      correctAnswerIndex: 3,
      category: QuestionCategory.math,
      imagePath: 'assets/rewards/edu_28.png',
    ),
    EducationQuestion(
      question: 'What is the square root of the math problem?\n√900 = __',
      options: ['27', '30', '60', '10'],
      correctAnswerIndex: 1,
      category: QuestionCategory.math,
      imagePath: 'assets/rewards/edu_29.png',
    ),
    EducationQuestion(
      question:
          'What is the sum of the math multiplication problems?\n11 × 14 = __',
      options: ['104', '165', '154', '151'],
      correctAnswerIndex: 2,
      category: QuestionCategory.math,
      imagePath: 'assets/rewards/edu_30.png',
    ),
    EducationQuestion(
      question:
          'What is the sum of the math multiplication problems?\n105 × 13 = __',
      options: ['1264', '1345', '1367', '1365'],
      correctAnswerIndex: 3,
      category: QuestionCategory.math,
      imagePath: 'assets/rewards/edu_31.png',
    ),
    EducationQuestion(
      question:
          'What is the sum of the math multiplication problems?\n60 × 24 = __',
      options: ['978', '1141', '1139', '1440'],
      correctAnswerIndex: 3,
      category: QuestionCategory.math,
      imagePath: 'assets/rewards/edu_32.png',
    ),
    EducationQuestion(
      question:
          'What is the sum of the math multiplication problems?\n333 × 12 = __',
      options: ['4132', '3997', '3996', '3101'],
      correctAnswerIndex: 2,
      category: QuestionCategory.math,
      imagePath: 'assets/rewards/edu_33.png',
    ),

    EducationQuestion(
      question:
          'What is the sum of the math subtraction problem?\n1,967-652=__',
      options: ['1123', '2318', '1314', '1315'],
      correctAnswerIndex: 3,
      category: QuestionCategory.math,
      imagePath: 'assets/rewards/edu_34.png',
    ),

    EducationQuestion(
      question: 'What is the sum of the math subtraction problem?\n897-241=__',
      options: ['616', '687', '646', '656'],
      correctAnswerIndex: 3,
      category: QuestionCategory.math,
      imagePath: 'assets/rewards/edu_35.png',
    ),

    EducationQuestion(
      question: 'What is the sum of the math subtraction problem?\n719-501=__',
      options: ['309', '218', '123', 'None of the above'],
      correctAnswerIndex: 1,
      category: QuestionCategory.math,
      imagePath: 'assets/rewards/edu_36.png',
    ),

    EducationQuestion(
      question: 'What is the sum of the math addition problem?\n4317+ 1,241=__',
      options: ['7154', '6514', '5,558', '5517'],
      correctAnswerIndex: 2,
      category: QuestionCategory.math,
      imagePath: 'assets/rewards/edu_37.png',
    ),

    EducationQuestion(
      question: 'What is the sum of the math addition problem?\n114+231+347=__',
      options: ['567', '628', '692', '680'],
      correctAnswerIndex: 2,
      category: QuestionCategory.math,
      imagePath: 'assets/rewards/edu_38.png',
    ),

    EducationQuestion(
      question:
          'What is the sum of the following math multiplication problem?\n9x6=__',
      options: ['53', '54', '57', 'None of the above'],
      correctAnswerIndex: 1,
      category: QuestionCategory.math,
      imagePath: 'assets/rewards/edu_39.png',
    ),

    EducationQuestion(
      question:
          'What is the sum of the following math multiplication problem?\n12x10=__',
      options: ['130', '121', '120', 'None of the above'],
      correctAnswerIndex: 2,
      category: QuestionCategory.math,
      imagePath: 'assets/rewards/edu_40.png',
    ),

    EducationQuestion(
      question:
          'What is the sum of the following math multiplication problem?\n9x4=__',
      options: ['36', '45', '27', 'None of the above'],
      correctAnswerIndex: 0,
      category: QuestionCategory.math,
      imagePath: 'assets/rewards/edu_41.png',
    ),

    EducationQuestion(
      question:
          'What is the sum of the following math multiplication problem?\n8x7=__',
      options: ['36', '54', '56', 'None of the above'],
      correctAnswerIndex: 2,
      category: QuestionCategory.math,
      imagePath: 'assets/rewards/edu_42.png',
    ),

    EducationQuestion(
      question:
          'What is the sum of the following math subtraction problem?\n12-4=__',
      options: ['8', '6', '7', 'None of the above'],
      correctAnswerIndex: 0,
      category: QuestionCategory.math,
      imagePath: 'assets/rewards/edu_43.png',
    ),

    EducationQuestion(
      question:
          'What is the sum of the following math subtraction problem?\n89-31=__',
      options: ['47', '48', '50', 'None of the above'],
      correctAnswerIndex: 3,
      category: QuestionCategory.math,
      imagePath: 'assets/rewards/edu_44.png',
    ),

    EducationQuestion(
      question:
          'What is the sum of the following math subtraction problem?\n21-16=__',
      options: ['7', '4', '5', 'None of the above'],
      correctAnswerIndex: 2,
      category: QuestionCategory.math,
      imagePath: 'assets/rewards/edu_45.png',
    ),

    EducationQuestion(
      question:
          'What is the sum of the following math addition problem?\n19+67=__',
      options: ['83', '71', '86', 'None of the above'],
      correctAnswerIndex: 2,
      category: QuestionCategory.math,
      imagePath: 'assets/rewards/edu_46.png',
    ),

    EducationQuestion(
      question:
          'What is the sum of the following math addition problem?\n16+35=__',
      options: ['53', '51', '50', 'None of the above'],
      correctAnswerIndex: 1,
      category: QuestionCategory.math,
      imagePath: 'assets/rewards/edu_47.png',
    ),

    EducationQuestion(
      question:
          'What is the sum of the following math addition problem?\n22+13=__',
      options: ['37', '29', '35', 'None of the above'],
      correctAnswerIndex: 2,
      category: QuestionCategory.math,
      imagePath: 'assets/rewards/edu_48.png',
    ),

    // NEW MATH QUESTIONS (Division, Number Placement, Percentages)
    EducationQuestion(
      question:
          'If there are 400 students in class A and 2000 notebooks, how many notebooks does each student receive?',
      options: ['6', '3', '7', '5'],
      correctAnswerIndex: 3,
      category: QuestionCategory.math,
      imagePath: 'assets/rewards/edu_48.png',
    ),
    EducationQuestion(
      question: 'What is 120 ÷ 20?',
      options: ['4', '5', '3', '6'],
      correctAnswerIndex: 3,
      category: QuestionCategory.math,
      imagePath: 'assets/rewards/edu_48.png',
    ),
    EducationQuestion(
      question: 'What is 84 ÷ 7?',
      options: ['12', '11', '13', '9'],
      correctAnswerIndex: 0,
      category: QuestionCategory.math,
      imagePath: 'assets/rewards/edu_48.png',
    ),

    // Number Placement
    EducationQuestion(
      question: 'What number is in the one\'s place in the number 6873?',
      options: ['7', '3', '8', '6'],
      correctAnswerIndex: 1,
      category: QuestionCategory.math,
      imagePath: 'assets/rewards/edu_48.png',
    ),
    EducationQuestion(
      question: 'What number is in the tens place in the number 9527?',
      options: ['2', '7', '9', '5'],
      correctAnswerIndex: 0,
      category: QuestionCategory.math,
      imagePath: 'assets/rewards/edu_48.png',
    ),
    EducationQuestion(
      question: 'What number is in the hundreds place in the number 3457?',
      options: ['5', '4', '7', '3'],
      correctAnswerIndex: 1,
      category: QuestionCategory.math,
      imagePath: 'assets/rewards/edu_48.png',
    ),
    EducationQuestion(
      question: 'What number is in the thousands place in the number 6857?',
      options: ['5', '8', '6', '7'],
      correctAnswerIndex: 2,
      category: QuestionCategory.math,
      imagePath: 'assets/rewards/edu_48.png',
    ),

    // Percentages
    EducationQuestion(
      question:
          'Jane bought two shirts for a subtotal of \$15 and received an additional 10% discount off the \$15. How much is her discount?',
      options: ['\$3.00', '\$1.75', '\$1.50', '\$6.00'],
      correctAnswerIndex: 2,
      category: QuestionCategory.math,
      imagePath: 'assets/rewards/edu_48.png',
    ),
    EducationQuestion(
      question: 'What is 50% of \$150?',
      options: ['\$60', '\$75', '\$70', '\$55'],
      correctAnswerIndex: 1,
      category: QuestionCategory.math,
      imagePath: 'assets/rewards/edu_48.png',
    ),
    EducationQuestion(
      question: 'What is 25% of \$30?',
      options: ['\$5.75', '\$4.75', '\$6.00', '\$7.50'],
      correctAnswerIndex: 3,
      category: QuestionCategory.math,
      imagePath: 'assets/rewards/edu_48.png',
    ),
  ];

  // List of all English questions
  static final List<EducationQuestion> englishQuestions = [
    EducationQuestion(
      question: 'Jessica walked to the park. What is the verb in the sentence?',
      options: ['Walked', 'Jessica', 'To', 'None of the above'],
      correctAnswerIndex: 0,
      category: QuestionCategory.english,
      imagePath: 'assets/rewards/edu_49.png',
    ),

    EducationQuestion(
      question:
          'She crossed the street by herself. What are the pronouns in the sentence?',
      options: ['She', 'herself', 'by', 'Both A and B', 'None of the above'],
      correctAnswerIndex: 3,
      category: QuestionCategory.english,
      imagePath: 'assets/rewards/edu_50.png',
    ),

    EducationQuestion(
      question:
          'Would you like to come to my party? Is this sentence asking a question or making a statement?',
      options: ['Statement', 'Question', 'Both A and B', 'None of the above'],
      correctAnswerIndex: 1,
      category: QuestionCategory.english,
      imagePath: 'assets/rewards/edu_51.png',
    ),

    EducationQuestion(
      question:
          'Jaime is going to the store. What are the nouns in the sentence?',
      options: ['Store', 'Jaime', 'Jaime and store', 'None of the above'],
      correctAnswerIndex: 2,
      category: QuestionCategory.english,
      imagePath: 'assets/rewards/edu_52.png',
    ),

    EducationQuestion(
      question:
          'Mitchell won the basketball game. What are the nouns in the sentence?',
      options: [
        'Mitchell',
        'basketball and game',
        'A and B',
        'None of the above',
      ],
      correctAnswerIndex: 2,
      category: QuestionCategory.english,
      imagePath: 'assets/rewards/edu_53.png',
    ),

    EducationQuestion(
      question:
          'Place the correct word to make a complete sentence structure.\nDavid won the mathematics _______ award.',
      options: ['acheevement', 'achievement', 'archievement'],
      correctAnswerIndex: 1,
      category: QuestionCategory.english,
      imagePath: 'assets/rewards/edu_54.png',
    ),

    EducationQuestion(
      question:
          'Place the correct word to make a complete sentence structure.\nAnn _______ what dress she wanted to wear to the dance.',
      options: ['know', 'knew', 'knows'],
      correctAnswerIndex: 1,
      category: QuestionCategory.english,
      imagePath: 'assets/rewards/edu_55.png',
    ),

    EducationQuestion(
      question:
          'Place the correct word to make a complete sentence structure.\nChrissy _______ her package in the mail.',
      options: ['recieved', 'received', 'receved'],
      correctAnswerIndex: 1,
      category: QuestionCategory.english,
      imagePath: 'assets/rewards/edu_56.png',
    ),

    EducationQuestion(
      question:
          'Place the correct word to make a complete sentence structure.\nRalph _______ the yellow and red truck.',
      options: ['chose', 'choice', 'choose'],
      correctAnswerIndex: 0,
      category: QuestionCategory.english,
      imagePath: 'assets/rewards/edu_57.png',
    ),

    EducationQuestion(
      question:
          'Place the correct word to make a complete sentence structure.\nWendy _______ a new computer.',
      options: ['brought', 'buys', 'bought'],
      correctAnswerIndex: 2,
      category: QuestionCategory.english,
      imagePath: 'assets/rewards/edu_58.png',
    ),
  ];

  // List of all spelling questions
  static final List<EducationQuestion> spellingQuestions = [
    EducationQuestion(
      question: 'What is the correct Spelling word?',
      options: ['Embarrassed', 'Embareassed', 'Emborassed'],
      correctAnswerIndex: 0,
      category: QuestionCategory.spelling,
      imagePath: 'assets/rewards/edu_59.png',
    ),

    EducationQuestion(
      question: 'What is the correct Spelling word?',
      options: ['Calculater', 'Calkulator', 'Calculator'],
      correctAnswerIndex: 2,
      category: QuestionCategory.spelling,
      imagePath: 'assets/rewards/edu_60.png',
    ),

    EducationQuestion(
      question: 'What is the correct Spelling word?',
      options: ['Umbrela', 'Umbrilla', 'Umbrella'],
      correctAnswerIndex: 2,
      category: QuestionCategory.spelling,
      imagePath: 'assets/rewards/edu_61.png',
    ),

    EducationQuestion(
      question: 'What is the correct Spelling word?',
      options: ['Computer', 'Compater', 'Competer'],
      correctAnswerIndex: 0,
      category: QuestionCategory.spelling,
      imagePath: 'assets/rewards/edu_62.png',
    ),

    EducationQuestion(
      question: 'What is the correct Spelling word?',
      options: ['Refigerator', 'Refrigerator', 'Refragerator'],
      correctAnswerIndex: 1,
      category: QuestionCategory.spelling,
      imagePath: 'assets/rewards/edu_63.png',
    ),
  ];

  // List of all Geography questions
  static final List<EducationQuestion> geographyQuestions = [
    EducationQuestion(
      question: 'What continent and country was Robyn Rihanna Fenty born in?',
      options: [
        'South America and Barbados',
        'Africa and Barbados',
        'Europe and Jamaica',
        'North America and Barbados',
      ],
      correctAnswerIndex: 3,
      category: QuestionCategory.geography,
      imagePath: 'assets/rewards/edu_64.png',
    ),
    EducationQuestion(
      question: 'Is France a country on the continent of Europe?',
      options: ['Yes', 'No'],
      correctAnswerIndex: 0,
      category: QuestionCategory.geography,
      imagePath: 'assets/rewards/edu_64.png',
    ),
    EducationQuestion(
      question: 'Name two territories of the US.',
      options: [
        'Cayman Island and Jamaica',
        'Puerto Rico and US Virgin Islands',
        'None of the above',
      ],
      correctAnswerIndex: 1,
      category: QuestionCategory.geography,
      imagePath: 'assets/rewards/edu_64.png',
    ),
    EducationQuestion(
      question:
          'Which is the smallest country in population in Australia/Oceania?',
      options: ['New England', 'Fiji', 'Tonga', 'Nauru'],
      correctAnswerIndex: 3,
      category: QuestionCategory.geography,
      imagePath: 'assets/rewards/edu_64.png',
    ),
    EducationQuestion(
      question: 'Name three countries in the continent North America.',
      options: [
        'Honduras, Guatemala, and USA',
        'USA, Dominican Republic, and Mexico',
        'Costa Rica, Panama, and Haiti',
        'None of the above',
        'All of the above',
      ],
      correctAnswerIndex: 4,
      category: QuestionCategory.geography,
      imagePath: 'assets/rewards/edu_64.png',
    ),
    EducationQuestion(
      question:
          'Finland, Monaco, Vatican City, Netherlands, and Greece are in what continent?',
      options: ['Asia', 'South America', 'Europe', 'Antarctica'],
      correctAnswerIndex: 2,
      category: QuestionCategory.geography,
      imagePath: 'assets/rewards/edu_64.png',
    ),
  ];

  // Sports questions use slide card images in the education popup.
  static final List<EducationQuestion> sportsQuestions = [
    // Add sports slide cards here when assets are available (edu sports slides).
  ];

  // List of all TV Shows questions
  static final List<EducationQuestion> tvShowQuestions = [
    EducationQuestion(
      question:
          'Who created the sitcom tv shows, the Jeffersons, Good Times, All In the Family, Sanford and Son, and Maude?',
      options: ['Redd Foxx', 'Norman Lear', 'William Cosby', 'Glen Larson'],
      correctAnswerIndex: 1,
      category: QuestionCategory.tvShow,
      imagePath: 'assets/rewards/edu_65.png',
    ),
    EducationQuestion(
      question:
          'Which four actors starred in, created, directed, and or produced the television sitcoms Fat Albert, A Different World, Malcolm and Eddie, and the Cosby Show?',
      options: [
        'Phylicia Rashad, Aretha Franklin, Chaka Khan, and Malcolm Jamal Warner',
        'Debbie Allen, William Cosby, Eddie Jones, and Phylicia Rashad',
        'William Cosby, Debbie Allen, Malcolm Jamal Warner, and Phylicia Rashad',
        'Lisa Bonet, Jasmine Guy, Richard Pryor, and Debbie Allen',
      ],
      correctAnswerIndex: 2,
      category: QuestionCategory.tvShow,
      imagePath: 'assets/rewards/edu_65.png',
    ),
    EducationQuestion(
      question: 'Who was the star of the tv sitcom Knight Rider?',
      options: [
        'Bruce Willis',
        'David Hasselhoff',
        'Dwayne Johnson',
        'Kevin Hart',
      ],
      correctAnswerIndex: 1,
      category: QuestionCategory.tvShow,
      imagePath: 'assets/rewards/edu_65.png',
    ),
    EducationQuestion(
      question:
          'Who is an author, actor, comedian, radio talk show host, and the 6th person to host the Family Feud Sitcom TV Game Show?',
      options: ['Al Roker', 'Richard Dawson', 'Steve Harvey', 'Louie Anderson'],
      correctAnswerIndex: 2,
      category: QuestionCategory.tvShow,
      imagePath: 'assets/rewards/edu_65.png',
    ),
    EducationQuestion(
      question:
          'Name three of the characters names in the shows Good Times and Maude.',
      options: [
        'J.J, Janet, and Florida.',
        'James, Sara, and Maude',
        'Florida, Wilona, and Penny',
        'Wilona, Bookman T, and Maude',
      ],
      correctAnswerIndex: 2,
      category: QuestionCategory.tvShow,
      imagePath: 'assets/rewards/edu_65.png',
    ),
  ];

  // List of all HBCU questions
  static final List<EducationQuestion> hbcuQuestions = [
    EducationQuestion(
      question:
          'Which comedian, chief of law enforcement, and civil rights activist attended the HBCU, Morris Brown College?',
      options: [
        'Kym Whitley, Eddie Murphy, Andrew Young, and Kevin Hart',
        'Dave Chappell, Sheryl Underwood, Cassandra Jones, and Ralph David Abernathy',
        'Sommore, Melody Maddox, Beverly Harvard, and Hosea Williams',
        'Martin Lawrence, Katt Williams, Melody Maddox, and Jesse Jackson',
      ],
      correctAnswerIndex: 2,
      category: QuestionCategory.hbcu,
      imagePath: 'assets/rewards/edu_66.png',
    ),
    EducationQuestion(
      question:
          'Name four of the HBCU colleges in the Atlanta University Center.',
      options: [
        'Morris Brown College, Clark Atlanta University, Spelman College, and Morehouse College.',
        'Georgia Tech University, Morris Brown College, Morehouse College, and Georgia State University.',
        'Emory University, Morris Brown College, Spelman College, and Clark Atlanta University.',
        'Liberty University, Clark Atlanta University, Morris Brown College, and Spelman College.',
      ],
      correctAnswerIndex: 0,
      category: QuestionCategory.hbcu,
      imagePath: 'assets/rewards/edu_66.png',
    ),
    EducationQuestion(
      question:
          'Who is the author, creator, toy/game/app developer, song writer, and founder of Say It Now Self-Love Kids LLC, and what college and university did they attend or graduate from?',
      options: [
        'Gloria J. Warren, Morris Brown College and Liberty University Graduate',
        'Lillie J. Warren-Porch Thomas, Morris Brown College and Georgia State University',
        'Pamela A. Warren-Logan, Clark Atlanta University',
        'Glen T. Warren, Sr. Wilberforce University Graduate',
        'Johnny L. Warren, Morehouse College Graduate',
        'Janice L. Warren-Jackson, Pointe University and Liberty University Graduate',
        'Phillip Porch, Georgia State University Graduate',
        'Philicia Porch, West Georgia University Graduate',
        'Glen T. Warren Jr, George Washington University Graduate',
        'Clayton Warren, Georgia Southern University Graduate',
        'All of the above.',
        'None of the above.',
      ],
      correctAnswerIndex: 0,
      category: QuestionCategory.hbcu,
      imagePath: 'assets/rewards/edu_66.png',
    ),
  ];

  // List of all Bible questions
  static final List<EducationQuestion> bibleQuestions = [
    EducationQuestion(
      question:
          'What animal did Jesus ask his two disciples to gather that was tied to a tree which he later rode on in Jerusalem?',
      options: ['Horse', 'Donkey or Colt', 'Giraffe', 'Camel'],
      correctAnswerIndex: 1,
      category: QuestionCategory.bible,
      imagePath: 'assets/rewards/edu_67.png',
    ),
    EducationQuestion(
      question: 'Who were Jacob and Essau parents?',
      options: [
        'Mary and Joseph',
        'Moses and Rahab',
        'Esther and David',
        'Rebekah and Issac',
        'None of the above',
      ],
      correctAnswerIndex: 3,
      category: QuestionCategory.bible,
      imagePath: 'assets/rewards/edu_67.png',
    ),
    EducationQuestion(
      question: 'Which children did Rachel give birth to with Jacob?',
      options: [
        'Levite and Essau',
        'Joseph and Benjamin',
        'Judah and Dan',
        'Gad and Ashner',
      ],
      correctAnswerIndex: 1,
      category: QuestionCategory.bible,
      imagePath: 'assets/rewards/edu_67.png',
    ),
    EducationQuestion(
      question:
          'What is the scripture where Jesus was moved in spirit and wept for Mary and Martha when their brother, Lazarus died?',
      options: [
        'Proverbs 1:31',
        'John 11:33-35',
        'Jeremiah 29:11',
        'Matthew 6:34',
      ],
      correctAnswerIndex: 1,
      category: QuestionCategory.bible,
      imagePath: 'assets/rewards/edu_67.png',
    ),
    EducationQuestion(
      question:
          'What are the two scriptures that state "For I know the plans I have for you," declares the Lord, "plans to prosper you and not to harm you, plans to give you hope and a future. And Trust in the Lord with all your heart and lean not on your own understanding?"',
      options: [
        'Proverbs 3:5',
        'Proverbs 1:31',
        'Matthew 6:34',
        'Philippians 4:13',
        'Jeremiah 29:11',
        'Both A and E',
      ],
      correctAnswerIndex: 5,
      category: QuestionCategory.bible,
      imagePath: 'assets/rewards/edu_67.png',
    ),
  ];

  // Get a random history question
  static EducationQuestion getRandomHistoryQuestion() {
    return historyQuestions[_random.nextInt(historyQuestions.length)];
  }

  // Get a random science question
  static EducationQuestion getRandomScienceQuestion() {
    return scienceQuestions[_random.nextInt(scienceQuestions.length)];
  }

  // Get a random math question
  static EducationQuestion getRandomMathQuestion() {
    return mathQuestions[_random.nextInt(mathQuestions.length)];
  }

  // Get a random English question
  static EducationQuestion getRandomEnglishQuestion() {
    return englishQuestions[_random.nextInt(englishQuestions.length)];
  }

  // Get a random spelling question
  static EducationQuestion getRandomSpellingQuestion() {
    return spellingQuestions[_random.nextInt(spellingQuestions.length)];
  }

  // Get a random Geography question
  static EducationQuestion getRandomGeographyQuestion() {
    return geographyQuestions[_random.nextInt(geographyQuestions.length)];
  }

  // Get a random Sports question
  static EducationQuestion getRandomSportsQuestion() {
    return sportsQuestions[_random.nextInt(sportsQuestions.length)];
  }

  // Get a random TV Show question
  static EducationQuestion getRandomTvShowQuestion() {
    return tvShowQuestions[_random.nextInt(tvShowQuestions.length)];
  }

  // Get a random HBCU question
  static EducationQuestion getRandomHbcuQuestion() {
    return hbcuQuestions[_random.nextInt(hbcuQuestions.length)];
  }

  // Get a random Bible question
  static EducationQuestion getRandomBibleQuestion() {
    return bibleQuestions[_random.nextInt(bibleQuestions.length)];
  }

  // GLOBAL TRACKING: Track which questions have been shown across ALL players in the game
  static final Set<String> _shownQuestionIds = {};
  static List<EducationQuestion>? _allQuestionsCache;

  // BEHAVIOR TRACKING: Track shown behaviors to prevent duplicates
  static final Set<int> _shownBehaviorIndices = {};

  // CHORE TRACKING: Track shown chores to prevent duplicates
  static final Set<int> _shownChoreIndices = {};

  // Equal-weight educational categories for balanced question rotation.
  static final List<QuestionCategory> _balancedCategories = [
    QuestionCategory.english,
    QuestionCategory.math,
    QuestionCategory.science,
    QuestionCategory.geography,
    QuestionCategory.sports,
    QuestionCategory.tvShow,
    QuestionCategory.history,
    QuestionCategory.spelling,
    QuestionCategory.hbcu,
    QuestionCategory.bible,
  ];

  // Recent categories served to each player, used to spread categories evenly
  // across a player's turns (avoids clustering many Bible/HBCU/etc. in a row).
  static final Map<PlayerData, List<QuestionCategory>>
  _recentCategoriesByPlayer = {};

  // How many of a player's most-recent categories to avoid repeating.
  static const int _recentCategoryWindow = 3;

  // REWARD TRACKING: Track shown reward cards to prevent duplicates
  static final Set<int> _shownRewardPositions = {};
  static final Set<int> _shownRewardCardIndices = {};

  // Get all questions from all categories
  static List<EducationQuestion> getAllQuestions() {
    _allQuestionsCache ??= [
      ...historyQuestions,
      ...scienceQuestions,
      ...mathQuestions,
      ...englishQuestions,
      ...spellingQuestions,
      ...geographyQuestions,
      ...sportsQuestions,
      ...tvShowQuestions,
      ...hbcuQuestions,
      ...bibleQuestions,
    ];
    return _allQuestionsCache!;
  }

  // Reset the question tracking (call this when starting a new game)
  static void resetQuestionTracking() {
    _shownQuestionIds.clear();
    _shownBehaviorIndices.clear();
    _shownChoreIndices.clear();
    _shownRewardPositions.clear();
    _shownRewardCardIndices.clear();
    _recentCategoriesByPlayer.clear();
  }

  static List<EducationQuestion> _questionsForCategory(
    QuestionCategory category,
  ) {
    switch (category) {
      case QuestionCategory.history:
        return historyQuestions;
      case QuestionCategory.science:
        return scienceQuestions;
      case QuestionCategory.math:
        return mathQuestions;
      case QuestionCategory.english:
        return englishQuestions;
      case QuestionCategory.spelling:
        return spellingQuestions;
      case QuestionCategory.geography:
        return geographyQuestions;
      case QuestionCategory.sports:
        return sportsQuestions;
      case QuestionCategory.tvShow:
        return tvShowQuestions;
      case QuestionCategory.hbcu:
        return hbcuQuestions;
      case QuestionCategory.bible:
        return bibleQuestions;
    }
  }

  static String _questionId(EducationQuestion question) =>
      '${question.imagePath}|${question.category.name}|${question.question}|${question.correctAnswerIndex}';

  /// Returns the next unique question for this game session, or null when the
  /// full deck has already been shown (no repeats until the deck is reshuffled).
  ///
  /// Category selection keeps every subject (including Math) in rotation and,
  /// when [activePlayer] is provided, avoids serving that player a category they
  /// were given in their last few turns so subjects spread evenly.
  static EducationQuestion? pickNextUniqueQuestion(
    List<PlayerData> players, {
    PlayerData? activePlayer,
  }) {
    // Only consider categories that still have at least one unshown question.
    final categoriesWithQuestions =
        _balancedCategories.where((category) {
          return _questionsForCategory(category).any((question) {
            return !_shownQuestionIds.contains(_questionId(question));
          });
        }).toList();

    if (categoriesWithQuestions.isEmpty) {
      return null;
    }

    // Spread categories: prefer ones this player has NOT seen in their last few
    // turns. Fall back to all available categories if every one was recent.
    final recent =
        activePlayer == null
            ? const <QuestionCategory>[]
            : (_recentCategoriesByPlayer[activePlayer] ??
                const <QuestionCategory>[]);

    List<QuestionCategory> pickable =
        categoriesWithQuestions
            .where((category) => !recent.contains(category))
            .toList();
    if (pickable.isEmpty) {
      pickable = List<QuestionCategory>.from(categoriesWithQuestions);
    }

    pickable.shuffle(_random);
    final category = pickable.first;

    final available =
        _questionsForCategory(category).where((question) {
          return !_shownQuestionIds.contains(_questionId(question));
        }).toList();

    final selectedQuestion = available[_random.nextInt(available.length)];
    _shownQuestionIds.add(_questionId(selectedQuestion));

    // Record this category in the player's recent list (bounded window).
    if (activePlayer != null) {
      final history = _recentCategoriesByPlayer.putIfAbsent(
        activePlayer,
        () => <QuestionCategory>[],
      );
      history.add(category);
      while (history.length > _recentCategoryWindow) {
        history.removeAt(0);
      }
    }

    return selectedQuestion;
  }

  /// Picks a question by rotating through categories evenly so every subject
  /// is represented (English, Math, Science, Geography, Sports, TV Shows, etc.).
  static EducationQuestion? getBalancedRandomQuestion(
    List<PlayerData> players, {
    PlayerData? activePlayer,
  }) {
    return pickNextUniqueQuestion(players, activePlayer: activePlayer);
  }

  // PERFECT RANDOM SYSTEM: Get a random question that hasn't been shown yet.
  // Does not repeat until a new game is started.
  static EducationQuestion? getRandomQuestion(List<PlayerData> players) {
    final allQuestions = getAllQuestions();

    final availableQuestions =
        allQuestions.where((q) {
          return !_shownQuestionIds.contains(_questionId(q));
        }).toList();

    if (availableQuestions.isEmpty) {
      return null;
    }

    final selectedQuestion =
        availableQuestions[_random.nextInt(availableQuestions.length)];

    _shownQuestionIds.add(_questionId(selectedQuestion));

    print(
      '✅ Question ${_shownQuestionIds.length}/${allQuestions.length} | Category: ${selectedQuestion.category}',
    );

    return selectedQuestion;
  }

  // Get smart random question — globally unique across all players this game,
  // and balanced so a single player isn't clustered on one category.
  static EducationQuestion? getSmartRandomQuestion(
    List<PlayerData> players, {
    PlayerData? activePlayer,
  }) {
    return getBalancedRandomQuestion(players, activePlayer: activePlayer);
  }

  // Last event (Freeze/Jail/behavior) card drawn — used to block immediate repeats
  // even across a deck reshuffle so the same card can't appear back-to-back.
  static int _lastBehaviorIndex = -1;

  // BEHAVIOR TRACKING SYSTEM: Get a random behavior that hasn't been shown yet
  static BehaviorDefinition? getRandomBehavior() {
    // Find behaviors that haven't been shown yet
    List<int> availableIndices = [];
    for (int i = 0; i < kBehaviorCards.length; i++) {
      if (!_shownBehaviorIndices.contains(i)) {
        availableIndices.add(i);
      }
    }

    if (availableIndices.isEmpty) {
      print(
        'ℹ️ All ${kBehaviorCards.length} behavior cards shown this game (no repeats).',
      );
      return null;
    }

    // No immediate repeat: never draw the same card twice in a row (e.g. Freeze/Jail)
    // when another card is available.
    List<int> pickable =
        availableIndices.where((i) => i != _lastBehaviorIndex).toList();
    if (pickable.isEmpty) {
      pickable = availableIndices;
    }

    // Pick a random behavior from the pickable set
    final selectedIndex = pickable[_random.nextInt(pickable.length)];

    // Mark this behavior as shown and remember it as the last drawn card
    _shownBehaviorIndices.add(selectedIndex);
    _lastBehaviorIndex = selectedIndex;

    print(
      '✅ Behavior ${selectedIndex + 1}/${kBehaviorCards.length} shown. Remaining: ${kBehaviorCards.length - _shownBehaviorIndices.length}',
    );

    return kBehaviorCards[selectedIndex];
  }

  // CHORE TRACKING SYSTEM: Random chore from full catalog (no duplicates per game).
  static ChoreCard? getRandomChore() {
    final availableIndices = <int>[];
    for (int i = 0; i < kAllChoreCards.length; i++) {
      if (!_shownChoreIndices.contains(i)) {
        availableIndices.add(i);
      }
    }

    if (availableIndices.isEmpty) {
      print(
        'ℹ️ All ${kAllChoreCards.length} chore cards shown this game (no repeats).',
      );
      return null;
    }

    final selectedIndex =
        availableIndices[_random.nextInt(availableIndices.length)];
    _shownChoreIndices.add(selectedIndex);
    return kAllChoreCards[selectedIndex];
  }

  /// Picks the next reward card from the full deck without repeating this game.
  static RewardDefinition? getRandomRewardCard() {
    final availableIndices = <int>[];
    for (int i = 0; i < kRewardCards.length; i++) {
      if (!_shownRewardCardIndices.contains(i)) {
        availableIndices.add(i);
      }
    }

    if (availableIndices.isEmpty) {
      print(
        'ℹ️ All ${kRewardCards.length} reward cards shown this game (no repeats).',
      );
      return null;
    }

    final selectedIndex =
        availableIndices[_random.nextInt(availableIndices.length)];
    _shownRewardCardIndices.add(selectedIndex);

    print(
      '✅ Reward card ${selectedIndex + 1}/${kRewardCards.length} shown. Remaining: ${kRewardCards.length - _shownRewardCardIndices.length}',
    );

    return kRewardCards[selectedIndex];
  }

  // REWARD TRACKING SYSTEM: Get a reward ensuring no duplicates
  static RewardCard? getRewardForPosition(int position) {
    if (rewardSquarePositions.contains(position)) {
      _shownRewardPositions.add(position);
      final picked = getRandomRewardCard();
      if (picked == null) {
        return null;
      }

      RewardType rewardType = RewardType.collectFromBank;
      String targetType = 'Say it Now Self-Love Bank';

      if (picked.description.toLowerCase().contains('from each parent') ||
          picked.description.toLowerCase().contains('from both your parents')) {
        rewardType = RewardType.collectFromParents;
        targetType = 'parents';
      }

      return RewardCard(
        instruction: picked.description,
        imagePath: picked.imagePath,
        rewardType: rewardType,
        rewardAmount: picked.amount,
        targetType: targetType,
      );
    }

    return null;
  }

  // Get a random question by specific category
  static EducationQuestion getRandomQuestionByCategory(
    QuestionCategory category,
  ) {
    switch (category) {
      case QuestionCategory.history:
        return getRandomHistoryQuestion();
      case QuestionCategory.science:
        return getRandomScienceQuestion();
      case QuestionCategory.math:
        return getRandomMathQuestion();
      case QuestionCategory.english:
        return getRandomEnglishQuestion();
      case QuestionCategory.spelling:
        return getRandomSpellingQuestion();
      case QuestionCategory.geography:
        return getRandomGeographyQuestion();
      case QuestionCategory.sports:
        return getRandomSportsQuestion();
      case QuestionCategory.tvShow:
        return getRandomTvShowQuestion();
      case QuestionCategory.hbcu:
        return getRandomHbcuQuestion();
      case QuestionCategory.bible:
        return getRandomBibleQuestion();
    }
  }
}

// Education squares (~74% of card-action squares; former chore/reward tiles converted).
final Set<int> educationQuestionPositions = {
  2,
  4,
  6,
  8,
  9,
  12,
  14,
  16,
  17,
  18,
  22,
  24,
  26,
  27,
  28,
  29,
  30,
  32,
  34,
  35,
  36,
  38,
  39,
};

final Set<int> penaltySquarePositions = {}; // No penalty squares currently
final Set<int> skipTurnSquarePositions = {5, 25};

// Welcome Screen that shows for 2 seconds
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
              'assets/images/circle.png', // Use your game logo here
              width: 180, // Reduced size
              height: 180, // Reduced size
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 15), // Reduced spacing
            const Text(
              'SAY IT NOW SELF-LOVE KIDS APP',
              style: TextStyle(
                fontSize: 24, // Reduced font size to fit longer name
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
            const SizedBox(height: 8), // Reduced spacing
            const Text(
              'Get ready for an exciting journey!',
              style: TextStyle(
                fontSize: 16, // Reduced font size
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

// Now, let's create a new PenaltyPopup widget for displaying the penalty message
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
      widget.onPenaltyApplied();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(scale: _scaleAnimation.value, child: child);
        },
        child: Container(
          width: double.infinity,
          height: MediaQuery.of(context).size.height * 0.4,
          decoration: BoxDecoration(
            color: Color(0xFFFF6347), // Tomato red color
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.black, width: 3),
            boxShadow: [
              BoxShadow(color: Colors.black45, blurRadius: 10, spreadRadius: 2),
            ],
          ),
          child: Stack(
            children: [
              // Main content
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Warning icon
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 80,
                        color: Colors.white,
                      ),

                      SizedBox(height: 20),

                      // Title
                      Text(
                        "OOPS!",
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 2,
                        ),
                      ),

                      SizedBox(height: 20),

                      // Message
                      Text(
                        "You landed on a penalty square.\nYou lose \$10!",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Footer
              Positioned(
                bottom: 15,
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    "SAY IT NOW SELF-LOVE KIDS LLC GAME",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white70,
                    ),
                  ),
                ),
              ),

              // Close button
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
      ),
    );
  }
}

// Behavior Popup - similar flow to Reward: show 01 then random 02-12
class BehaviorPopup extends StatefulWidget {
  final BehaviorDefinition behavior;
  final void Function(BehaviorDefinition def) onResolved;
  final VoidCallback onClose;
  const BehaviorPopup({
    super.key,
    required this.behavior,
    required this.onResolved,
    required this.onClose,
  });

  @override
  State<BehaviorPopup> createState() => _BehaviorPopupState();
}

class _BehaviorPopupState extends State<BehaviorPopup> {
  late String currentImage;
  late BehaviorDefinition selected;

  @override
  void initState() {
    super.initState();
    selected = widget.behavior;
    currentImage = selected.imagePath;
  }

  @override
  void dispose() {
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
          // Green background to match behavior card theme
          color: const Color(0xFF1FA51F),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black, width: 4),
          boxShadow: const [
            BoxShadow(color: Colors.black45, blurRadius: 15, spreadRadius: 3),
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
                    const Text(
                      "BEHAVIOR",
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      selected.description,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.7,
                      height: MediaQuery.of(context).size.width * 0.7,
                      child: Image.asset(currentImage, fit: BoxFit.contain),
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
                icon: const Icon(Icons.close, color: Colors.black, size: 30),
                onPressed: () {
                  widget.onResolved(selected);
                  widget.onClose();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Character Selection Screen with auto-scrolling
class CharacterSelectionScreen extends StatefulWidget {
  final Function(List<PlayerData>) onGameStart;

  const CharacterSelectionScreen({super.key, required this.onGameStart});

  @override
  _CharacterSelectionScreenState createState() =>
      _CharacterSelectionScreenState();
}

class _CharacterSelectionScreenState extends State<CharacterSelectionScreen> {
  // List of available characters
  final List<Color> characterColors = [
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.pink,
    Colors.amber,
  ];

  final List<String> characterNames = [
    'Player 1',
    'Player 2',
    'Player 3',
    'Player 4',
    'Player 5',
    'Player 6',
    'Player 7',
    'Player 8',
  ];

  // Character image paths
  final List<String> characterImagePaths = [
    'assets/images/ch1.png',
    'assets/images/ch2.png',
    'assets/images/ch3.png',
    'assets/images/ch4.png',
    'assets/images/ch5.png',
    'assets/images/ch6.png',
    'assets/images/ch7.png',
    'assets/images/ch8.png',
  ];

  // Selected players
  List<PlayerData> selectedPlayers = [];

  // Controller for adding new players
  final TextEditingController nameController = TextEditingController();
  int selectedCharacterIndex = 0;

  // Add scroll controller for grid
  final ScrollController _gridScrollController = ScrollController();

  // Audio player for game sounds
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    // Add listener to the text controller to update UI when text changes
    nameController.addListener(() {
      setState(() {
        // This will rebuild the widget when text changes, enabling/disabling the button
      });
    });

    // Configure audio player for maximum volume
    _configureAudioPlayer();
  }

  // Configure audio player settings
  Future<void> _configureAudioPlayer() async {
    try {
      // Set volume to maximum
      await _audioPlayer.setVolume(1.0);
      // Set player mode to media (for better volume on mobile devices)
      await _audioPlayer.setPlayerMode(PlayerMode.mediaPlayer);
    } catch (e) {
      print('Error configuring audio player: $e');
    }
  }

  // Method to play start game sound
  Future<void> _playStartGameSound() async {
    try {
      // Stop any currently playing audio
      await _audioPlayer.stop();

      // Set volume to maximum (1.0) and configure for loud playback
      await _audioPlayer.setVolume(1.0);
      await _audioPlayer.setPlayerMode(PlayerMode.mediaPlayer);

      // Play the roll_set.mp3 sound
      await _audioPlayer.play(
        AssetSource('game_sound/roll_set.mp3'),
        volume: 1.0, // Explicitly set volume parameter
      );
    } catch (e) {
      print('Error playing start game sound: $e');
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    _gridScrollController.dispose(); // Dispose the scroll controller
    _audioPlayer.dispose(); // Dispose the audio player
    super.dispose();
  }

  // Check if the Add Player button should be enabled
  bool canAddPlayer() {
    return nameController.text.trim().isNotEmpty &&
        selectedPlayers.length < 8 &&
        !selectedPlayers.any(
          (player) => player.characterIndex == selectedCharacterIndex,
        );
  }

  // Method to scroll to the specified character index
  void _scrollToCharacter(int index) {
    // Calculate position in grid
    // For a grid with 3 items per row, we need to calculate the row
    int row = index ~/ 3; // Integer division to get the row

    // Estimate the scroll position (adjust these values based on your layout)
    double itemHeight = 100.0; // Approximate height of each grid row
    double targetPosition = row * itemHeight;

    // Animate to the position
    if (_gridScrollController.hasClients) {
      _gridScrollController.animateTo(
        targetPosition,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

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
      constraints: const BoxConstraints.expand(),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Select Your Characters',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        blurRadius: 5.0,
                        color: Colors.black45,
                        offset: Offset(1.0, 1.0),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                // Character selection
                Text(
                  'Choose a character:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),

                // Character grid - Now with auto-scrolling
                SizedBox(
                  height:
                      MediaQuery.of(context).size.width > 600
                          ? 140
                          : 190, // Smaller height for tablets
                  child: GridView.builder(
                    controller:
                        _gridScrollController, // Add the controller here
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount:
                          MediaQuery.of(context).size.width > 600
                              ? 4
                              : 3, // More columns on tablets
                      childAspectRatio:
                          MediaQuery.of(context).size.width > 600
                              ? 0.9
                              : 0.8, // Adjusted ratio for tablets
                      crossAxisSpacing:
                          MediaQuery.of(context).size.width > 600
                              ? 6
                              : 8, // Smaller spacing on tablets
                      mainAxisSpacing:
                          MediaQuery.of(context).size.width > 600
                              ? 6
                              : 8, // Smaller spacing on tablets
                    ),
                    itemCount: 8, // 8 characters
                    itemBuilder: (context, index) {
                      bool isSelected = selectedCharacterIndex == index;
                      bool isUsed = selectedPlayers.any(
                        (player) => player.characterIndex == index,
                      );

                      return GestureDetector(
                        onTap:
                            isUsed
                                ? null
                                : () {
                                  setState(() {
                                    selectedCharacterIndex = index;
                                  });
                                },
                        child: Container(
                          decoration: BoxDecoration(
                            color:
                                isUsed
                                    ? Colors.grey.withValues(alpha: 0.5)
                                    : isSelected
                                    ? Colors.white.withValues(alpha: 0.3)
                                    : Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                            border:
                                isSelected
                                    ? Border.all(color: Colors.white, width: 2)
                                    : null,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Character image - responsive sizing
                              Container(
                                width:
                                    MediaQuery.of(context).size.width > 600
                                        ? 40
                                        : 60, // Smaller on tablets
                                height:
                                    MediaQuery.of(context).size.width > 600
                                        ? 40
                                        : 60, // Smaller on tablets
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: characterColors[index],
                                    width: 2,
                                  ),
                                  color: Colors.white,
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.asset(
                                    characterImagePaths[index],
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.width > 600
                                        ? 4
                                        : 8,
                              ),
                              Text(
                                characterNames[index],
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize:
                                      MediaQuery.of(context).size.width > 600
                                          ? 11
                                          : 14,
                                ),
                              ),
                              if (isUsed)
                                Container(
                                  margin: EdgeInsets.only(top: 4),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'Used',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 12),

                // Name input
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: nameController,
                        decoration: InputDecoration(
                          labelText: 'Player Name',
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed:
                          canAddPlayer()
                              ? () {
                                setState(() {
                                  // Add the current player with selected character
                                  selectedPlayers.add(
                                    PlayerData(
                                      name: nameController.text.trim(),
                                      color:
                                          characterColors[selectedCharacterIndex],
                                      characterIndex: selectedCharacterIndex,
                                      imagePath:
                                          characterImagePaths[selectedCharacterIndex],
                                    ),
                                  );
                                  nameController.clear();

                                  // Find next available character
                                  int nextAvailableIndex = -1;
                                  for (int i = 0; i < 8; i++) {
                                    if (!selectedPlayers.any(
                                      (player) => player.characterIndex == i,
                                    )) {
                                      nextAvailableIndex = i;
                                      break;
                                    }
                                  }

                                  if (nextAvailableIndex != -1) {
                                    selectedCharacterIndex = nextAvailableIndex;

                                    // Auto-scroll to the next available character
                                    WidgetsBinding.instance
                                        .addPostFrameCallback((_) {
                                          _scrollToCharacter(
                                            nextAvailableIndex,
                                          );
                                        });
                                  }
                                });
                              }
                              : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Add Player',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Selected players list
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.28,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Selected Players (${selectedPlayers.length}/8):',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child:
                              selectedPlayers.isEmpty
                                  ? Center(
                                    child: Text(
                                      'Add at least 1 player to start',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  )
                                  : ListView.builder(
                                    itemCount: selectedPlayers.length,
                                    itemBuilder: (context, index) {
                                      final player = selectedPlayers[index];
                                      return Container(
                                        margin: const EdgeInsets.only(
                                          bottom: 8,
                                        ),
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.8),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color: player.color,
                                            width: 2,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            // Show character image
                                            Container(
                                              width: 36,
                                              height: 36,
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                border: Border.all(
                                                  color: player.color,
                                                  width: 2,
                                                ),
                                              ),
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                                child: Image.asset(
                                                  player.imagePath,
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                player.name,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            IconButton(
                                              icon: Icon(
                                                Icons.delete,
                                                size: 20,
                                              ),
                                              color: Colors.red,
                                              padding: EdgeInsets.all(4),
                                              constraints: BoxConstraints(),
                                              onPressed: () {
                                                setState(() {
                                                  selectedPlayers.removeAt(
                                                    index,
                                                  );
                                                });
                                              },
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                const SizedBox(height: 8),

                // Start game button
                ElevatedButton(
                  onPressed:
                      selectedPlayers.isEmpty
                          ? null
                          : () {
                            widget.onGameStart(selectedPlayers);
                            _playStartGameSound();
                          },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'Start Game (${selectedPlayers.length}/1-8 Players)',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Modified CirclePatternPage to accept player data
class CirclePatternPage extends StatelessWidget {
  final List<PlayerData> players;

  const CirclePatternPage({super.key, required this.players});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // Orange radial gradient background
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
        constraints: const BoxConstraints.expand(),
        child: SafeArea(child: Center(child: CirclePattern(players: players))),
      ),
    );
  }
}

// Modified CirclePattern to use player data and money system
class CirclePattern extends StatefulWidget {
  final List<PlayerData> players;

  const CirclePattern({super.key, required this.players});

  @override
  _CirclePatternState createState() => _CirclePatternState();
}

// Complete _CirclePatternState class with turn management fixes
class _CirclePatternState extends State<CirclePattern>
    with TickerProviderStateMixin {
  final Color darkNavyColor = const Color(0xFF0E1625);

  // Animation controller for dice rolling
  late AnimationController _animationController;

  // Audio player for game sounds
  final AudioPlayer _audioPlayer = AudioPlayer();

  // Current dice values
  List<int> diceValues = [1, 6];

  // Current active player index
  int activePlayerIndex = 0;

  // Random for dice rolls
  final Random _random = Random();

  // Add these new properties for board positions
  final int totalBoardSquares = 40; // 4 corners + 36 squares (9 per side)
  Map<int, List<PlayerData>> boardPositions = {};

  // For action messages
  String? actionMessage;
  Timer? messageTimer;

  // For animated movement
  bool isAnimatingMovement = false;
  int currentAnimationPosition = 0;
  int targetPosition = 0;
  Timer? animationTimer;

  // For smooth square scaling animations
  Map<int, AnimationController> squareAnimationControllers = {};
  Map<int, Animation<double>> squareScaleAnimations = {};

  // NEW PROPERTIES FOR TURN MANAGEMENT
  bool hasRolledThisTurn = false; // Track if current player has rolled
  bool hasActionThisTurn =
      false; // Track if current player has had an action this turn
  bool isTurnTransitioning = false; // Track if we're between turns

  // WIN CONDITION
  static const int WINNING_AMOUNT = 200; // Game ends when a player reaches $200
  bool _winHandled = false;

  @override
  void initState() {
    super.initState();

    // Initialize animation controller for dice
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );

    // Add status listener for when animation completes
    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _animationController.reset();

        // Calculate move after dice roll animation completes
        _movePlayer();
      }
    });

    // Configure audio player for maximum volume
    _configureAudioPlayer();

    // Initialize all players at the starting position (position 0)
    _initializePlayerPositions();
  }

  // Configure audio player settings
  Future<void> _configureAudioPlayer() async {
    try {
      // Set volume to maximum
      await _audioPlayer.setVolume(1.0);
      // Set player mode to media (for better volume on mobile devices)
      await _audioPlayer.setPlayerMode(PlayerMode.mediaPlayer);
    } catch (e) {
      print('Error configuring audio player: $e');
    }
  }

  // New method to initialize player positions
  void _initializePlayerPositions() {
    // Clear existing positions
    boardPositions.clear();

    // Place all players at position 0 (START - bottom-right corner)
    boardPositions[0] = [];
    for (var player in widget.players) {
      player.position = 0; // Set initial position to 0 (START)
      boardPositions[0]?.add(player);
    }
  }

  // Check if any player has won the game
  void _checkForWinner() {
    if (_winHandled) return;

    print("=== CHECKING FOR WINNER ===");
    print("Winning amount required: \$$WINNING_AMOUNT");

    for (var player in widget.players) {
      print("${player.name}: \$${player.totalMoney}");
      if (player.totalMoney >= WINNING_AMOUNT) {
        _winHandled = true;
        print("🏆 WINNER FOUND: ${player.name} with \$${player.totalMoney}!");
        print("Showing leaderboard...");
        _showLeaderboard();
        return;
      }
    }
    print("No winner yet. Game continues.");
    print("===========================");
  }

  // Show the leaderboard screen
  void _showLeaderboard() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder:
            (context) => GameLeaderboardScreen(
              players: widget.players,
              onPlayAgain: () {
                // Reset all players and restart the game
                for (var player in widget.players) {
                  player.totalMoney = 100;
                  player.ones = 5;
                  player.fives = 3;
                  player.tens = 1;
                  player.twenties = 1;
                  player.fifties = 1;
                  player.hundreds = 0;
                  player.position = 0;
                  player.turnsCompleted = 0;
                  player.lapsCompleted = 0;
                  player.questionHistory = [];
                  player.skipNextTurn = false;
                  player.debt = 0;
                  player.inJail = false;
                  player.jailFeeDue = 0;
                }
                // Reset question tracking for new game
                EducationQuestionBank.resetQuestionTracking();
                // Go back to character selection
                Navigator.of(context).pushReplacementNamed('/game');
              },
              onExit: () {
                // Exit to home screen
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
            ),
      ),
    );
  }

  /// Called when a card deck is exhausted. Reshuffles all decks and continues
  /// until a player reaches WINNING_AMOUNT (200). The game never ends early
  /// on deck exhaustion — only _checkForWinner() can end the game.
  void _endGameWithHighestScore() {
    if (_winHandled) return;
    EducationQuestionBank.resetQuestionTracking();
    print('🔄 Card deck exhausted — reshuffled. Game continues until a player reaches \$$WINNING_AMOUNT.');
    _scheduleNextPlayerTurn();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _audioPlayer.dispose();
    messageTimer?.cancel();
    animationTimer?.cancel();

    // Dispose all square animation controllers
    squareAnimationControllers.forEach((_, controller) {
      controller.dispose();
    });

    super.dispose();
  }

  // Method to play dice roll sound
  Future<void> _playDiceRollSound() async {
    try {
      // Stop any currently playing audio
      await _audioPlayer.stop();

      // Set volume to maximum (1.0) and configure for loud playback
      await _audioPlayer.setVolume(1.0);
      await _audioPlayer.setPlayerMode(PlayerMode.mediaPlayer);

      // Play the sound with maximum volume
      await _audioPlayer.play(
        AssetSource('game_sound/dise_roll.mp3'),
        volume: 1.0, // Explicitly set volume parameter
      );
    } catch (e) {
      print('Error playing dice roll sound: $e');
    }
  }

  // Method to play right answer sound
  Future<void> _playRightAnswerSound() async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.setVolume(1.0);
      await _audioPlayer.setPlayerMode(PlayerMode.mediaPlayer);
      await _audioPlayer.play(
        AssetSource('game_sound/right_answer.mp3'),
        volume: 1.0,
      );
    } catch (e) {
      print('Error playing right answer sound: $e');
    }
  }

  // Method to play wrong answer sound
  Future<void> _playWrongAnswerSound() async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.setVolume(1.0);
      await _audioPlayer.setPlayerMode(PlayerMode.mediaPlayer);
      await _audioPlayer.play(
        AssetSource('game_sound/wrong_answer.mp3'),
        volume: 1.0,
      );
    } catch (e) {
      print('Error playing wrong answer sound: $e');
    }
  }

  // Method to play start game sound (roll_set.mp3)
  Future<void> _playStartGameSound() async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.setVolume(1.0);
      await _audioPlayer.setPlayerMode(PlayerMode.mediaPlayer);
      await _audioPlayer.play(
        AssetSource('game_sound/roll_set.mp3'),
        volume: 1.0,
      );
    } catch (e) {
      print('Error playing start game sound: $e');
    }
  }

  // UPDATED: Modified dice roll method to include turn management
  void _rollDice() {
    // Don't allow rolling if animation is in progress
    if (isAnimatingMovement) return;

    // Don't allow rolling if player has already rolled this turn
    if (hasRolledThisTurn) return;

    // Don't allow rolling if we're transitioning between turns
    if (isTurnTransitioning) return;

    // Play dice roll sound
    _playDiceRollSound();

    setState(() {
      // Mark that this player has rolled for this turn
      hasRolledThisTurn = true;

      // Start the animation
      _animationController.forward();

      // Generate random dice values between 1 and 6
      diceValues = [_random.nextInt(6) + 1, _random.nextInt(6) + 1];

      // The actual movement happens after animation completes in the listener
    });
  }

  // Create a method to handle the square animation
  void _animateSquare(int position, bool scaleUp) {
    // Create animation controller for this position if it doesn't exist
    if (!squareAnimationControllers.containsKey(position)) {
      squareAnimationControllers[position] = AnimationController(
        vsync: this,
        duration: Duration(
          milliseconds: 250,
        ), // Faster for smoother transitions
      );

      // Create animation with curve for smoother scaling
      squareScaleAnimations[position] = Tween<double>(
        begin: 1.0,
        end: 1.5,
      ).animate(
        CurvedAnimation(
          parent: squareAnimationControllers[position]!,
          curve: Curves.easeOutBack, // Bounce slightly for nicer effect
        ),
      );

      // Add listener to update UI when animation changes
      squareAnimationControllers[position]!.addListener(() {
        setState(() {
          // The animation value will be automatically used in build
        });
      });
    }

    // Animate to the target state
    if (scaleUp) {
      squareAnimationControllers[position]!.forward();
    } else {
      squareAnimationControllers[position]!.reverse();
    }
  }

  // Enhanced move player method with animation
  void _movePlayer() {
    if (isAnimatingMovement) return;

    // Get the current active player
    PlayerData activePlayer = widget.players[activePlayerIndex];

    // Calculate dice total
    int diceTotal = diceValues[0] + diceValues[1];

    // Store starting position for step counting
    int startPosition = activePlayer.position;

    // Calculate target position
    targetPosition = (startPosition + diceTotal) % totalBoardSquares;

    // Initialize animation position to start position
    currentAnimationPosition = startPosition;

    // Start animation
    isAnimatingMovement = true;

    // Animate the current square up
    _animateSquare(currentAnimationPosition, true);

    // Start the animation process
    _animateNextStep(0, diceTotal);
  }

  void _animateNextStep(int stepsTaken, int totalSteps) {
    // Cancel any existing timer
    animationTimer?.cancel();

    animationTimer = Timer(Duration(milliseconds: 300), () {
      // Animate previous square down
      _animateSquare(currentAnimationPosition, false);

      // Check if we've taken all steps needed
      if (stepsTaken >= totalSteps) {
        // We've reached the destination, end animation
        _finalizeMovement();
        return;
      }

      // Store previous position for lap detection
      int previousPosition = currentAnimationPosition;

      // Move to next position
      currentAnimationPosition =
          (currentAnimationPosition + 1) % totalBoardSquares;

      // Check if player has crossed the start position (0)
      if (previousPosition == totalBoardSquares - 1 &&
          currentAnimationPosition == 0) {
        // Player completed a lap, increment lap counter
        PlayerData activePlayer = widget.players[activePlayerIndex];
        activePlayer.lapsCompleted++;

        // Show notification message
        _showActionMessage(
          "${activePlayer.name} completed lap ${activePlayer.lapsCompleted}!",
        );
      }

      // Update player position in the map
      _updatePlayerPositionInMap();

      // Animate new square up
      _animateSquare(currentAnimationPosition, true);

      // Continue animation for next step with incremented steps count
      _animateNextStep(stepsTaken + 1, totalSteps);
    });
  }

  void _updatePlayerPositionInMap() {
    PlayerData activePlayer = widget.players[activePlayerIndex];

    // Remove player from previous position
    if (boardPositions.containsKey(activePlayer.position)) {
      boardPositions[activePlayer.position]?.remove(activePlayer);

      // If list is empty, remove the key
      if (boardPositions[activePlayer.position]?.isEmpty ?? true) {
        boardPositions.remove(activePlayer.position);
      }
    }

    // Update player position
    activePlayer.position = currentAnimationPosition;

    // Add player to new position
    if (!boardPositions.containsKey(currentAnimationPosition)) {
      boardPositions[currentAnimationPosition] = [];
    }
    boardPositions[currentAnimationPosition]?.add(activePlayer);
  }

  void _finalizeMovement() {
    // Handle any special actions at the final position
    _handleLandingAction(targetPosition);

    // Reset animation state
    isAnimatingMovement = false;

    // Update UI
    setState(() {});
  }

  // UPDATED: Modified to handle landing actions and automatic turn progression
  // REPLACE YOUR EXISTING _handleLandingAction METHOD WITH THIS:

  void _handleLandingAction(int position) {
    PlayerData activePlayer = widget.players[activePlayerIndex];

    // Mark that this player has had an action this turn
    hasActionThisTurn = true;

    print("${activePlayer.name} landed on square $position!");

    // Jail and bonus logic
    if (position == 10) {
      // Landed in jail
      activePlayer.inJail = true;
      activePlayer.jailFeeDue = 25;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return JailPopup(
            onClose: () {
              Navigator.of(context).pop();
              _scheduleNextPlayerTurn();
            },
          );
        },
      );
      return;
    } else if (position == 20) {
      // Bonus on position 20
      activePlayer.addMoney(50);
      _showActionMessage("${activePlayer.name} received a \$50 bonus!");
      setState(() {});

      // CRITICAL FIX: Check winner after frame is rendered
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _checkForWinner();
        }
      });

      _scheduleNextPlayerTurn();
      return;
    }

    // PRIORITY: Behavior corner positions (1,11,21,31)
    if (position == 1 || position == 11 || position == 21 || position == 31) {
      final behavior = EducationQuestionBank.getRandomBehavior();
      if (behavior == null) {
        _endGameWithHighestScore();
        setState(() {});
        return;
      }

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return BehaviorPopup(
            behavior: behavior,
            onResolved: (BehaviorDefinition def) {
              _applyBehaviorEffects(activePlayer, def);
            },
            onClose: () {
              Navigator.of(context).pop();
              _scheduleNextPlayerTurn();
            },
          );
        },
      );
      setState(() {});
      return;
    }

    // Reward squares (7, 15, 19, 37) — each shows the next card from the reward deck
    if (rewardSquarePositions.contains(position)) {
      final rewardCard = EducationQuestionBank.getRewardForPosition(position);
      if (rewardCard == null) {
        _endGameWithHighestScore();
        setState(() {});
        return;
      }

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return RewardGamePopup(
            rewardCard: rewardCard,
            onRewardComplete: (RewardCard card) {
              _applyRewardBenefit(activePlayer, card);
            },
            onClose: () {
              Navigator.of(context).pop();
              _scheduleNextPlayerTurn(); // This will handle turn transition
            },
          );
        },
      );
    }
    // Check if the position has a chore card
    else if (choreSquarePositions.contains(position)) {
      final choreCard = EducationQuestionBank.getRandomChore();
      if (choreCard == null) {
        _endGameWithHighestScore();
        setState(() {});
        return;
      }

      _playStartGameSound(); // Play sound when landing on Chores
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return ChoreGamePopup(
            choreCard: choreCard,
            onChoreComplete: (ChoreCard card) {
              _applyChoreReward(activePlayer, card);
            },
            onClose: () {
              Navigator.of(context).pop();
              _scheduleNextPlayerTurn(); // This will handle turn transition
            },
          );
        },
      );
    }
    // Check if the position has an education question
    else if (educationQuestionPositions.contains(position)) {
      _handleEducationQuestion(position);
    }
    // Check if it's a skip turn square (position 4)
    else if (skipTurnSquarePositions.contains(position)) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return SkipTurnPopup(
            onPenaltyApplied: () {
              // Set the flag to skip next turn
              activePlayer.skipNextTurn = true;
              setState(() {}); // Update UI to reflect the change
            },
            onClose: () {
              Navigator.of(context).pop();
              _scheduleNextPlayerTurn(); // This will handle turn transition
            },
          );
        },
      );
    }
    // Check if it's a penalty square (now only position 34)
    else if (penaltySquarePositions.contains(position)) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return PenaltyPopup(
            onPenaltyApplied: () {
              // Deduct $10 from the player - use payWithLoan to allow debt
              activePlayer.payWithLoan(10);
              setState(() {}); // Update UI to reflect the change
            },
            onClose: () {
              Navigator.of(context).pop();
              _scheduleNextPlayerTurn(); // This will handle turn transition
            },
          );
        },
      );
    }
    // No special action - automatically move to next player
    else {
      _scheduleNextPlayerTurn(); // This will handle turn transition
    }

    // Update the UI
    setState(() {});
  }

  // UPDATED: Modified to include turn management flags
  void _scheduleNextPlayerTurn() {
    // Mark that we're transitioning between turns
    isTurnTransitioning = true;

    // Force end current player's turn by setting both flags
    hasRolledThisTurn = true;
    hasActionThisTurn = true;

    // Add a small delay before moving to next player for better UX
    Timer(Duration(seconds: 2), () {
      if (mounted) {
        _nextPlayerTurn();
      }
    });
  }

  // Add this method to apply chore rewards
  void _applyChoreReward(PlayerData activePlayer, ChoreCard choreCard) {
    int totalCollected = 0;

    print("=== CHORE REWARD DEBUG ===");
    print(
      "Active player: ${activePlayer.name} at position ${activePlayer.position}",
    );
    print("Chore type: ${choreCard.rewardType}");
    print("Reward amount: ${choreCard.rewardAmount}");

    switch (choreCard.rewardType) {
      case ChoreRewardType.collectFromBank:
        // Player earns money from the bank
        print("Collecting ${choreCard.rewardAmount} from bank");
        activePlayer.addMoney(choreCard.rewardAmount);
        totalCollected = choreCard.rewardAmount;
        break;

      case ChoreRewardType.collectFromPlayers:
        // Collect from all other players (forced payment even if they go into debt)
        print("Collecting from all players");
        for (var player in widget.players) {
          if (player != activePlayer) {
            print("  Taking ${choreCard.rewardAmount} from ${player.name}");
            player.payWithLoan(choreCard.rewardAmount);
            activePlayer.addMoney(choreCard.rewardAmount);
            totalCollected += choreCard.rewardAmount;
          }
        }
        break;

      case ChoreRewardType.collectFromPlayerAhead:
        // Collect from players ahead of the active player (forced payment even if they go into debt)
        print("Collecting from players ahead");
        for (var player in widget.players) {
          print("  Checking ${player.name} at position ${player.position}");
          if (player != activePlayer && _isPlayerAhead(activePlayer, player)) {
            print(
              "    ${player.name} IS ahead - taking ${choreCard.rewardAmount}",
            );
            player.payWithLoan(choreCard.rewardAmount);
            activePlayer.addMoney(choreCard.rewardAmount);
            totalCollected += choreCard.rewardAmount;
          } else {
            print("    ${player.name} is NOT ahead");
          }
        }
        break;

      case ChoreRewardType.collectFromParents:
        // Simplified: Just add money as if from parents
        print("Collecting from parents: ${choreCard.rewardAmount * 2}");
        activePlayer.addMoney(choreCard.rewardAmount * 2); // Assuming 2 parents
        totalCollected = choreCard.rewardAmount * 2;
        break;
    }

    print("Total collected: $totalCollected");
    print("Active player new total: ${activePlayer.totalMoney}");
    print("=========================");

    // Update UI to reflect money changes
    setState(() {});

    // CRITICAL FIX: Check winner after frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _checkForWinner();
      }
    });
  }

  // Method to apply reward benefits
  void _applyRewardBenefit(PlayerData activePlayer, RewardCard rewardCard) {
    int totalEarned = 0;

    print("=== REWARD BENEFIT DEBUG ===");
    print("Player: ${activePlayer.name}");
    print("Reward type: ${rewardCard.rewardType}");
    print("Reward amount: ${rewardCard.rewardAmount}");
    print("Player money before: ${activePlayer.totalMoney}");

    switch (rewardCard.rewardType) {
      case RewardType.collectFromBank:
      case RewardType.giftCard:
        // Player earns money from the bank
        activePlayer.addMoney(rewardCard.rewardAmount);
        totalEarned = rewardCard.rewardAmount;
        print("Added ${rewardCard.rewardAmount} from bank/gift card");
        break;

      case RewardType.collectFromParents:
        // Simplified: Just add money as if from parents (assuming 2 parents)
        activePlayer.addMoney(rewardCard.rewardAmount * 2);
        totalEarned = rewardCard.rewardAmount * 2;
        print(
          "Added ${rewardCard.rewardAmount * 2} from parents (${rewardCard.rewardAmount} x 2)",
        );
        break;
    }

    print("Player money after: ${activePlayer.totalMoney}");
    print("Total earned this reward: $totalEarned");
    print("============================");

    // Show success message
    _showActionMessage(
      "${activePlayer.name} earned \$$totalEarned from ${rewardCard.targetType}!",
    );

    // Update UI to reflect money changes
    setState(() {});

    // CRITICAL FIX: Check winner after frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _checkForWinner();
      }
    });
  }

  // Helper method to check if one player is ahead of another on the board
  bool _isPlayerAhead(PlayerData referencePlayer, PlayerData otherPlayer) {
    // FIRST: Compare laps completed - this is the primary metric
    if (otherPlayer.lapsCompleted > referencePlayer.lapsCompleted) {
      // Other player has completed more laps, they are ahead
      return true;
    } else if (otherPlayer.lapsCompleted < referencePlayer.lapsCompleted) {
      // Other player has completed fewer laps, they are NOT ahead
      return false;
    }

    // If laps are equal, compare positions on the current lap
    // For a circular board we need to handle the wrap-around case
    if (otherPlayer.position > referencePlayer.position) {
      // Simple case: other player is at a higher position number
      return true;
    } else if (referencePlayer.position >
            totalBoardSquares - totalBoardSquares / 4 &&
        otherPlayer.position < totalBoardSquares / 4) {
      // Handle wrap-around: reference player near the end, other player near the start
      return true;
    }
    return false;
  }

  // Helper method to show an action message (DISABLED - no more black messages)
  void _showActionMessage(String message) {
    // DO NOTHING - Remove black background messages
    print('Action: $message'); // Optional: keep for debugging
  }

  // Widget to display action messages (DISABLED)
  Widget _buildActionMessage() {
    return SizedBox.shrink(); // Always return empty widget
  }

  // NEW: Compact leaderboard showing player rankings
  Widget _buildCompactLeaderboard() {
    // Keep players in original order (no sorting by money)
    List<PlayerData> displayPlayers = widget.players;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 8),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange, width: 2),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children:
            displayPlayers.asMap().entries.map((entry) {
              int position = entry.key;
              PlayerData player = entry.value;

              // Determine position display (1st, 2nd, 3rd, 4th positions without sorting)
              String positionText = "";
              Color positionColor = Colors.grey;

              switch (position) {
                case 0:
                  positionText = "🥇";
                  positionColor = Colors.amber;
                  break;
                case 1:
                  positionText = "🥈";
                  positionColor = Colors.grey[400]!;
                  break;
                case 2:
                  positionText = "🥉";
                  positionColor = Colors.orange[700]!;
                  break;
                default:
                  positionText = "${position + 1}";
                  positionColor = Colors.grey[600]!;
              }

              return Expanded(
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 2),
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  decoration: BoxDecoration(
                    color: player.color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border:
                        activePlayerIndex == widget.players.indexOf(player)
                            ? Border.all(color: player.color, width: 2)
                            : null,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            positionText,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              player.name,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '\$${player.totalMoney}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }

  // Helper method to force-move a player to a specific position
  void _movePlayerToPosition(PlayerData player, int newPosition) {
    print("_movePlayerToPosition called:");
    print("  Player: ${player.name}");
    print("  From position: ${player.position}");
    print("  To position: $newPosition");

    // Remove from current position
    if (boardPositions.containsKey(player.position)) {
      boardPositions[player.position]?.remove(player);
      if (boardPositions[player.position]?.isEmpty ?? true) {
        boardPositions.remove(player.position);
      }
      print("  Removed from old position ${player.position}");
    }

    // Update player position
    player.position = newPosition;
    print("  Updated player.position to $newPosition");

    // Add to new position
    if (!boardPositions.containsKey(newPosition)) {
      boardPositions[newPosition] = [];
    }
    boardPositions[newPosition]?.add(player);
    print("  Added to new position $newPosition");
    print(
      "  boardPositions[$newPosition] now has ${boardPositions[newPosition]?.length ?? 0} players",
    );
  }

  // UPDATED: Modified to reset turn flags and handle skip turns
  void _nextPlayerTurn() {
    // Don't allow changing players if animation is in progress
    if (isAnimatingMovement) return;

    // Increment turns completed for the current player
    PlayerData currentPlayer = widget.players[activePlayerIndex];
    currentPlayer.completeTurn();

    // Move to next player
    setState(() {
      activePlayerIndex = (activePlayerIndex + 1) % widget.players.length;

      // RESET TURN FLAGS for the new player
      hasRolledThisTurn = false;
      hasActionThisTurn = false;
      isTurnTransitioning = false;
    });

    // Check if the new active player should skip their turn
    _checkAndHandleSkipTurn();
  }

  // NEW: Method to check and handle skip turns
  void _checkAndHandleSkipTurn() {
    PlayerData activePlayer = widget.players[activePlayerIndex];

    // Handle jail release at the start of the turn
    if (activePlayer.inJail && activePlayer.jailFeeDue > 0) {
      int fee = activePlayer.jailFeeDue;
      activePlayer.payWithLoan(fee);
      activePlayer.jailFeeDue = 0;
      activePlayer.inJail = false;
      setState(() {});

      // Show clear dialog about payment
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: Color(0xFFFFD700),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: Colors.black, width: 3),
            ),
            title: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 30),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Released from Jail!',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            content: Text(
              '${activePlayer.name} paid \$$fee and is now free to play!\n\nRemaining money: \$${activePlayer.totalMoney}',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text(
                  'Continue',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          );
        },
      );
    }

    // Check if this player should skip their turn
    if (activePlayer.skipNextTurn) {
      // Play wrong answer sound for skipped turn
      _playWrongAnswerSound();

      // Show skip turn message
      _showActionMessage("${activePlayer.name}'s turn is skipped!");

      // Reset the flag
      activePlayer.skipNextTurn = false;

      // Mark that we're transitioning turns
      isTurnTransitioning = true;

      // Automatically move to next player after a delay
      Timer(Duration(seconds: 2), () {
        if (mounted) {
          _nextPlayerTurn();
        }
      });
    }
  }

  // New method to render player tokens on the board
  Widget _buildPlayerTokens() {
    return Stack(
      children: [
        for (var posEntry in boardPositions.entries)
          _positionPlayersOnBoard(posEntry.key, posEntry.value),
      ],
    );
  }

  // Updated method to calculate player token positions with larger tokens
  Widget _positionPlayersOnBoard(int position, List<PlayerData> players) {
    // Get available board size - MUST MATCH the board layout exactly
    final size = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;
    final availableHeight = size.height - padding.top - padding.bottom - 280;
    final availableWidth = size.width - padding.left - padding.right - 20;
    final boardSize = min(
      availableWidth,
      availableHeight,
    ).clamp(300.0, double.infinity);

    // MUST MATCH the board layout sizes exactly
    final regularSquareSize = boardSize / 14;
    final cornerSquareSize = boardSize / 8;
    final gap = 2.0; // Gap between squares in the board layout

    // Calculate the available space for the middle sections (9 squares)
    // This matches the Expanded section in the board layout
    final middleSectionWidth = boardSize - (2 * cornerSquareSize) - (2 * gap);
    final middleSectionHeight = boardSize - (2 * cornerSquareSize) - (2 * gap);

    // Each expanded square gets equal space (including its margin)
    final expandedSquareWidth = middleSectionWidth / 9;
    final expandedSquareHeight = middleSectionHeight / 9;

    // Calculate x and y coordinates based on position
    double x = 0;
    double y = 0;

    if (position == 0) {
      // Bottom right corner - center of corner square
      x = boardSize - (cornerSquareSize / 2);
      y = boardSize - (cornerSquareSize / 2);
    } else if (position < 10) {
      // Bottom row (moving left) - positions 1-9
      // Note: in the layout, position 9 is index 0, position 1 is index 8
      int squareIndex = 9 - position; // Reverse mapping

      // Start of middle section + offset for this square + half square width
      x =
          cornerSquareSize +
          gap +
          (squareIndex * expandedSquareWidth) +
          (expandedSquareWidth / 2);

      // Y is in the bottom row, centered in regularSquareSize height
      y = boardSize - (regularSquareSize / 2);
    } else if (position == 10) {
      // Bottom left corner - center of corner square
      x = cornerSquareSize / 2;
      y = boardSize - (cornerSquareSize / 2);
    } else if (position < 20) {
      // Left column (moving up) - positions 11-19
      int squareIndex = position - 10 - 1; // 0-8 index

      // X is in the left column, centered in regularSquareSize width
      x = regularSquareSize / 2;

      // Start of middle section + offset for this square + half square height
      y =
          boardSize -
          cornerSquareSize -
          gap -
          (squareIndex * expandedSquareHeight) -
          (expandedSquareHeight / 2);
    } else if (position == 20) {
      // Top left corner - center of corner square
      x = cornerSquareSize / 2;
      y = cornerSquareSize / 2;
    } else if (position < 30) {
      // Top row (moving right) - positions 21-29
      int squareIndex = position - 20 - 1; // 0-8 index

      // Start of middle section + offset for this square + half square width
      x =
          cornerSquareSize +
          gap +
          (squareIndex * expandedSquareWidth) +
          (expandedSquareWidth / 2);

      // Y is in the top row, centered in regularSquareSize height
      y = regularSquareSize / 2;
    } else if (position == 30) {
      // Top right corner - center of corner square
      x = boardSize - (cornerSquareSize / 2);
      y = cornerSquareSize / 2;
    } else {
      // Right column (moving down) - positions 31-39
      int squareIndex = position - 30 - 1; // 0-8 index

      // X is in the right column, centered in regularSquareSize width
      x = boardSize - (regularSquareSize / 2);

      // Start of middle section + offset for this square + half square height
      y =
          cornerSquareSize +
          gap +
          (squareIndex * expandedSquareHeight) +
          (expandedSquareHeight / 2);
    }

    // Token size configuration
    final tokenSize = 32.0;
    final innerImageSize = 24.0;
    final stackOffset = 8.0; // Offset for stacked tokens

    // Calculate center position for tokens
    final centerX = x - (tokenSize / 2);
    final centerY = y - (tokenSize / 2);

    // Sort players - put active player on top (last in stack)
    final sortedPlayers = List<PlayerData>.from(players);
    sortedPlayers.sort((a, b) {
      // Active player should be rendered last (on top)
      if (a == widget.players[activePlayerIndex]) return 1;
      if (b == widget.players[activePlayerIndex]) return -1;
      return 0;
    });

    // Render player tokens stacked with active player on top
    return Stack(
      children:
          sortedPlayers.asMap().entries.map((entry) {
            final player = entry.value;
            final playerIndex = entry.key;
            final isActivePlayer = player == widget.players[activePlayerIndex];

            // Calculate offset for stacking effect
            final offsetX = centerX + (playerIndex * stackOffset);
            final offsetY = centerY - (playerIndex * stackOffset);

            return Positioned(
              left: offsetX,
              top: offsetY,
              child: Container(
                width: tokenSize,
                height: tokenSize,
                decoration: BoxDecoration(
                  color: player.color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isActivePlayer ? Colors.yellow : Colors.white,
                    width: isActivePlayer ? 3 : 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isActivePlayer ? Colors.black45 : Colors.black26,
                      blurRadius: isActivePlayer ? 6 : 3,
                      offset: Offset(2, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Container(
                    width: innerImageSize,
                    height: innerImageSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      image: DecorationImage(
                        image: AssetImage(player.imagePath),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
    );
  }

  // Updated helper method to create a border square with an image and smooth scaling effect
  Widget _buildBorderSquare(
    String imagePath,
    double size, [
    bool isCorner = false,
    int? position,
  ]) {
    // Get scale factor from animation if available
    double scale = 1.0;

    if (position != null && squareScaleAnimations.containsKey(position)) {
      scale = squareScaleAnimations[position]!.value;
    }

    // Calculate highlight based on animation value
    bool isHighlighted =
        position != null &&
        squareScaleAnimations.containsKey(position) &&
        squareScaleAnimations[position]!.value > 1.1;

    return Transform.scale(
      scale: scale,
      alignment: Alignment.center,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          border: Border.all(
            color:
                isHighlighted
                    ? Colors
                        .yellow // Highlight scaled squares
                    : Colors.cyan,
            width:
                isHighlighted
                    ? 2.5 // Thicker border for highlight
                    : 1.5, // Normal border
          ),
          borderRadius: BorderRadius.circular(4),
          image: DecorationImage(
            image: AssetImage(imagePath),
            fit: BoxFit.cover,
          ),
          boxShadow:
              isCorner || isHighlighted
                  ? [
                    BoxShadow(
                      color:
                          isHighlighted
                              ? Colors.yellow.withValues(
                                alpha: 0.6,
                              ) // Glow effect for highlighted squares
                              : Colors.black.withValues(alpha: 0.2),
                      spreadRadius: isHighlighted ? 2 : 1,
                      blurRadius: isHighlighted ? 6 : 2,
                      offset: Offset(0, 1),
                    ),
                  ]
                  : null,
        ),
      ),
    );
  }

  // Helper method to create active player display with character and dice
  Widget _buildActivePlayerDisplay(PlayerData player) {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: player.color, width: 3),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Player character image
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: player.color, width: 2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.asset(player.imagePath, fit: BoxFit.cover),
            ),
          ),
          SizedBox(width: 10),
          // Player name
          Text(
            player.name,
            style: TextStyle(
              color: player.color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to create a money display for a player
  Widget _buildMoneyDisplay(PlayerData player) {
    return Container(
      padding: EdgeInsets.all(8),
      margin: EdgeInsets.symmetric(horizontal: 8),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Color(0xFFFFA07A), // Light salmon color
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Total money display
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Bank: \$${player.totalMoney}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          SizedBox(height: 6),
          // Money denominations
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                if (player.ones > 0) _buildMoneyItem(player.ones, 1),
                SizedBox(width: 6),
                if (player.fives > 0) _buildMoneyItem(player.fives, 5),
                SizedBox(width: 6),
                if (player.tens > 0) _buildMoneyItem(player.tens, 10),
                SizedBox(width: 6),
                if (player.twenties > 0) _buildMoneyItem(player.twenties, 20),
                SizedBox(width: 6),
                if (player.fifties > 0) _buildMoneyItem(player.fifties, 50),
                SizedBox(width: 6),
                if (player.hundreds > 0) _buildMoneyItem(player.hundreds, 100),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to display money denomination with image
  Widget _buildMoneyItem(int count, int value) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.topRight,
          children: [
            // Money image
            Container(
              width: 40,
              height: 24,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black26),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Image.asset('assets/money/$value.png', fit: BoxFit.cover),
            ),
            // Count badge
            Container(
              padding: EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        Text(
          '\$$value × $count',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  // Helper method to create clickable dice
  Widget _buildDice(int value, bool isAnimating) {
    // Check if dice should be disabled
    bool isDisabled =
        hasRolledThisTurn ||
        hasActionThisTurn ||
        isTurnTransitioning ||
        isAnimatingMovement;

    return GestureDetector(
      onTap: isDisabled ? null : () => _rollDice(),
      child: Container(
        width: 44, // Larger size
        height: 44, // Larger size
        decoration: BoxDecoration(
          color: isDisabled ? Colors.grey : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDisabled ? Colors.grey : Colors.black,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isDisabled ? Colors.grey : Colors.black26,
              blurRadius: 4,
              offset: Offset(2, 2),
            ),
          ],
        ),
        child: Center(child: _buildDiceDots(value)),
      ),
    );
  }

  // Helper method to draw dice dots based on value
  Widget _buildDiceDots(int value) {
    switch (value) {
      case 1:
        return Container(
          width: 9, // Larger dot
          height: 9, // Larger dot
          decoration: BoxDecoration(
            color: Colors.black,
            shape: BoxShape.circle,
          ),
        );
      case 2:
        return Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Padding(padding: EdgeInsets.only(right: 8), child: _buildDot()),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Padding(padding: EdgeInsets.only(left: 8), child: _buildDot()),
              ],
            ),
          ],
        );
      case 3:
        return Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Padding(padding: EdgeInsets.only(right: 8), child: _buildDot()),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [_buildDot()],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Padding(padding: EdgeInsets.only(left: 8), child: _buildDot()),
              ],
            ),
          ],
        );
      case 4:
        return Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [_buildDot(), _buildDot()],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [_buildDot(), _buildDot()],
            ),
          ],
        );
      case 5:
        return Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [_buildDot(), _buildDot()],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [_buildDot()],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [_buildDot(), _buildDot()],
            ),
          ],
        );
      case 6:
        return Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [_buildDot(), _buildDot()],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [_buildDot(), _buildDot()],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [_buildDot(), _buildDot()],
            ),
          ],
        );
      default:
        return Container();
    }
  }

  // Helper method to create a single dot
  Widget _buildDot() {
    return Container(
      width: 6, // Larger dot
      height: 6, // Larger dot
      decoration: BoxDecoration(color: Colors.black, shape: BoxShape.circle),
    );
  }

  // UPDATED: Modified dice container to show turn status
  Widget _buildDiceContainer(PlayerData activePlayer) {
    final bool isDisabled =
        hasRolledThisTurn ||
        hasActionThisTurn ||
        isTurnTransitioning ||
        isAnimatingMovement;
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 8),
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "${activePlayer.name}'s Turn",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: activePlayer.color,
            ),
          ),
          SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: isDisabled ? null : _rollDice,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.max,
                children: [
                  Text(
                    'GO',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded, size: 22),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Removed unused _getTurnStatusMessage method

  // Removed test reward popup helper

  // Helper method to create inner square boxes with images
  Widget _buildInnerSquare({required String imagePath}) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.red.withValues(alpha: 0.8), width: 1.5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Padding(
        padding: EdgeInsets.all(4),
        child: Image.asset(imagePath, fit: BoxFit.contain),
      ),
    );
  }

  // UPDATED: Education question handler with proper turn management
  void _handleEducationQuestion(int position) {
    if (educationQuestionPositions.contains(position)) {
      // Get the current active player
      PlayerData activePlayer = widget.players[activePlayerIndex];

      // Mark that this player has had an action this turn BEFORE showing the question
      hasActionThisTurn = true;

      // Get the next unique deck question for this game (no repeats across players),
      // balanced so this player isn't clustered on one category.
      EducationQuestion? question = EducationQuestionBank.getSmartRandomQuestion(
        widget.players,
        activePlayer: activePlayer,
      );

      if (question == null) {
        _endGameWithHighestScore();
        return;
      }

      // Show the education review popup
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return EducationReviewPopup(
            question: question,
            onAnswerSubmitted: (bool isCorrect, int selectedIndex) {
              // Play appropriate sound based on answer
              if (isCorrect) {
                _playRightAnswerSound();
              } else {
                _playWrongAnswerSound();
              }

              // Update player's money and position based on answer
              if (isCorrect) {
                // CORRECT ANSWER: Active player earns $5 only
                activePlayer.addMoney(5);
                _movePlayerSteps(activePlayer, 1); // Move forward 1 step
                _showActionMessage(
                  "${activePlayer.name} answered correctly! +\$5",
                );
              } else {
                // INCORRECT ANSWER: No score changes for any player
                _movePlayerSteps(activePlayer, -2); // Move backward 2 steps
                _showActionMessage(
                  "${activePlayer.name} answered incorrectly! No points change.",
                );
              }

              // Track this question in player's history
              activePlayer.addQuestionToHistory(
                question,
                selectedIndex,
                isCorrect,
              );

              // Update the UI and check for winner
              setState(() {});

              // CRITICAL FIX: Check winner after frame is rendered
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  _checkForWinner();
                }
              });
            },
            onClose: () {
              Navigator.of(context).pop();
              // Automatically move to next player after education popup closes
              _scheduleNextPlayerTurn(); // This ensures proper turn transition
            },
          );
        },
      );
    }
  }

  // Helper method to move player by a specific number of steps (can be negative)
  void _movePlayerSteps(PlayerData player, int steps) {
    // Store old position for lap detection
    int oldPosition = player.position;

    // Remove player from current position
    if (boardPositions.containsKey(player.position)) {
      boardPositions[player.position]?.remove(player);
      if (boardPositions[player.position]?.isEmpty ?? true) {
        boardPositions.remove(player.position);
      }
    }

    // Calculate new position (handle negative steps and wrap around)
    int newPosition = (player.position + steps) % totalBoardSquares;

    // Handle negative positions (wrap around to end of board)
    if (newPosition < 0) {
      newPosition = totalBoardSquares + newPosition;
    }

    // Update player position
    player.position = newPosition;

    // Add player to new position
    if (!boardPositions.containsKey(newPosition)) {
      boardPositions[newPosition] = [];
    }
    boardPositions[newPosition]?.add(player);

    // Handle lap tracking based on movement direction
    if (steps > 0) {
      // Moving forward: check if we crossed position 0
      if (oldPosition + steps >= totalBoardSquares) {
        player.lapsCompleted++;
        _showActionMessage(
          "${player.name} completed lap ${player.lapsCompleted}!",
        );
      }
    } else if (steps < 0 && player.lapsCompleted > 0) {
      // Moving backward: check if we crossed position 0 backwards
      if (oldPosition + steps < 0) {
        player.lapsCompleted--;
        _showActionMessage("${player.name} moved back across the start line!");
      }
    }

    // After moving, only handle landing action if no action has been taken yet this turn
    if (!hasActionThisTurn) {
      _handleLandingAction(newPosition);
    }
    // REMOVED: Don't call _scheduleNextPlayerTurn() here when called from education questions
    // The education question popup will handle turn transition when it closes
  }

  @override
  Widget build(BuildContext context) {
    // Get active player
    final activePlayer = widget.players[activePlayerIndex];

    // For responsive sizing based on screen size
    final size = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;

    // Calculate available space more accurately
    final availableHeight =
        size.height -
        padding.top -
        padding.bottom -
        280; // More space for UI elements
    final availableWidth =
        size.width -
        padding.left -
        padding.right -
        20; // Account for horizontal padding

    // Use the smaller dimension to ensure board is square and fits properly
    final boardSize = min(availableWidth, availableHeight);

    // Ensure minimum board size for very small screens
    final finalBoardSize = max(boardSize, 300.0);

    // Calculate sizes for the grid layout
    final regularSquareSize =
        finalBoardSize / 14; // Smaller size for regular squares
    final cornerSquareSize =
        finalBoardSize / 8; // Larger size for corner squares
    final circleSize =
        finalBoardSize * 0.2; // Smaller center image (reduced from 0.3)
    final gap = 2.0;
    final horizontalPadding = 1.0;

    // Define the image paths
    final List<String> cornerImages = [
      'assets/images/corner1.png',
      'assets/images/corner2.png',
      'assets/images/corner3.png',
      'assets/images/corner4.png',
    ];

    // Define images for all sides
    final List<String> topRowImages = List.generate(
      9,
      (index) => 'assets/images/top_${index + 1}.png',
    );

    final List<String> leftColImages = List.generate(
      9,
      (index) => 'assets/images/left_${index + 1}.png',
    );

    final List<String> rightColImages = List.generate(
      9,
      (index) => 'assets/images/right_${index + 1}.png',
    );

    final List<String> bottomRowImages = List.generate(
      9,
      (index) => 'assets/images/bottom_${index + 1}.png',
    );

    final String circleImage = 'assets/images/circle.png';

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: 8,
        ),
        child: Column(
          children: [
            // Top section with leaderboard and player info
            Container(
              child: Column(
                children: [
                  // Compact leaderboard at the very top
                  _buildCompactLeaderboard(),
                  // Active player display removed to free up space for the board
                  SizedBox.shrink(),
                ],
              ),
            ),

            SizedBox(height: 8),

            // Game board container - centered and responsive
            Expanded(
              child: Center(
                child: Container(
                  width: finalBoardSize,
                  height: finalBoardSize,
                  color: Colors.transparent,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // TOP ROW
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        height: cornerSquareSize,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Top-left corner (single larger square with image)
                            _buildBorderSquare(
                              cornerImages[0],
                              cornerSquareSize,
                              true,
                              20, // Position 20
                            ),
                            SizedBox(width: gap),

                            // Top middle (9 squares with images)
                            Expanded(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: List.generate(
                                  9,
                                  (index) => Expanded(
                                    child: Container(
                                      height: regularSquareSize,
                                      margin: EdgeInsets.only(
                                        right: index < 8 ? gap : 0,
                                      ),
                                      child: Padding(
                                        padding: EdgeInsets.all(
                                          0.2,
                                        ), // Added 0.2 padding
                                        child: _buildBorderSquare(
                                          topRowImages[index],
                                          regularSquareSize,
                                          false,
                                          21 + index, // Positions 21-29
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            SizedBox(width: gap),
                            // Top-right corner (single larger square with image)
                            _buildBorderSquare(
                              cornerImages[1],
                              cornerSquareSize,
                              true,
                              30, // Position 30
                            ),
                          ],
                        ),
                      ),

                      // MIDDLE SECTION
                      Positioned(
                        top: cornerSquareSize + gap,
                        left: 0,
                        right: 0,
                        bottom: cornerSquareSize + gap,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Left column (9 squares with images)
                            SizedBox(
                              width: regularSquareSize,
                              child: Column(
                                children: List.generate(
                                  9,
                                  (index) => Expanded(
                                    child: Container(
                                      margin: EdgeInsets.only(
                                        bottom: index < 8 ? gap : 0,
                                      ),
                                      child: Padding(
                                        padding: EdgeInsets.all(
                                          0.2,
                                        ), // Added 0.2 padding
                                        child: _buildBorderSquare(
                                          leftColImages[index],
                                          regularSquareSize,
                                          false,
                                          19 -
                                              index, // Positions 19-11 (in reverse)
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            // Center space (for circle)
                            Expanded(
                              child: Container(
                                color: Colors.transparent,
                                child: Stack(
                                  children: [
                                    // Four square boxes inside the board with images
                                    Positioned(
                                      top: regularSquareSize,
                                      left: regularSquareSize * 2,
                                      child: _buildInnerSquare(
                                        imagePath:
                                            'assets/images/box_image1.png',
                                      ),
                                    ),
                                    Positioned(
                                      top: regularSquareSize,
                                      right: regularSquareSize * 2,
                                      child: _buildInnerSquare(
                                        imagePath:
                                            'assets/images/box_image2.png',
                                      ),
                                    ),
                                    Positioned(
                                      bottom: regularSquareSize,
                                      left: regularSquareSize * 2,
                                      child: _buildInnerSquare(
                                        imagePath:
                                            'assets/images/box_image3.png',
                                      ),
                                    ),
                                    Positioned(
                                      bottom: regularSquareSize,
                                      right: regularSquareSize * 2,
                                      child: _buildInnerSquare(
                                        imagePath:
                                            'assets/images/box_image4.png',
                                      ),
                                    ),

                                    // Center circle with image (smaller)
                                    Center(
                                      child: Container(
                                        width: circleSize,
                                        height: circleSize,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          image: DecorationImage(
                                            image: AssetImage(circleImage),
                                            fit: BoxFit.cover,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(
                                                alpha: 0.2,
                                              ),
                                              spreadRadius: 1,
                                              blurRadius: 4,
                                              offset: Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Right column (9 squares with images)
                            SizedBox(
                              width: regularSquareSize,
                              child: Column(
                                children: List.generate(
                                  9,
                                  (index) => Expanded(
                                    child: Container(
                                      margin: EdgeInsets.only(
                                        bottom: index < 8 ? gap : 0,
                                      ),
                                      child: Padding(
                                        padding: EdgeInsets.all(
                                          0.2,
                                        ), // Added 0.2 padding
                                        child: _buildBorderSquare(
                                          rightColImages[index],
                                          regularSquareSize,
                                          false,
                                          31 + index, // Positions 31-39
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // BOTTOM ROW
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        height: cornerSquareSize,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // Bottom-left corner (single larger square with image)
                            _buildBorderSquare(
                              cornerImages[2],
                              cornerSquareSize,
                              true,
                              10, // Position 10
                            ),
                            SizedBox(width: gap),

                            // Bottom middle (9 squares with images)
                            Expanded(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: List.generate(
                                  9,
                                  (index) => Expanded(
                                    child: Container(
                                      height: regularSquareSize,
                                      margin: EdgeInsets.only(
                                        right: index < 8 ? gap : 0,
                                      ),
                                      child: Padding(
                                        padding: EdgeInsets.all(
                                          0.2,
                                        ), // Added 0.2 padding
                                        child: _buildBorderSquare(
                                          bottomRowImages[index],
                                          regularSquareSize,
                                          false,
                                          9 - index, // Positions 9-1 (in reverse)
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            SizedBox(width: gap),
                            // Bottom-right corner (single larger square with image)
                            _buildBorderSquare(
                              cornerImages[3],
                              cornerSquareSize,
                              true,
                              0, // Position 0
                            ),
                          ],
                        ),
                      ),

                      // Player tokens overlay
                      _buildPlayerTokens(),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom section with money and dice
            Container(
              child: Column(
                children: [
                  // Action message
                  _buildActionMessage(),

                  SizedBox(height: 8),

                  // Money display at the bottom
                  _buildMoneyDisplay(activePlayer),

                  SizedBox(height: 10),

                  // Game controls - dice container with updated turn management
                  _buildDiceContainer(activePlayer),

                  SizedBox(height: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
      setState(() {
        opacity1 = 1.0;
      });
    });

    // Show the second image after 2 seconds
    Future.delayed(Duration(seconds: 2), () {
      setState(() {
        opacity2 = 1.0;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent, // Transparent background for Dialog
      child: AnimatedContainer(
        duration: Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        width: double.infinity, // Full width
        height:
            MediaQuery.of(context).size.height *
            0.5, // 50% of the screen height
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.7), // Semi-transparent background
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
  bool hasAppliedEffect = false; // Flag to prevent double application

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
        if (mounted && !hasAppliedEffect) {
          print("ChoreGamePopup: Auto-applying chore effect");
          hasAppliedEffect = true;
          widget.onChoreComplete(widget.choreCard);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        width: double.infinity,
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: Color(0xFFFF7F24), // Orange background
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black, width: 3),
        ),
        child: Stack(
          children: [
            // First animation: Cleaning supplies image
            if (!showChoreDetails)
              AnimatedOpacity(
                opacity: opacity1,
                duration: Duration(milliseconds: 500),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Title
                      Padding(
                        padding: const EdgeInsets.only(bottom: 40.0),
                        child: Text(
                          "CHORES",
                          style: TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                            letterSpacing: 2,
                          ),
                        ),
                      ),

                      // Chore image
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.9,
                        height: MediaQuery.of(context).size.width * 0.9,
                        child: Image.asset(
                          widget.choreCard.firstImagePath,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Second animation: Chore card with instruction
            if (showChoreDetails)
              AnimatedOpacity(
                opacity: opacity2,
                duration: Duration(milliseconds: 500),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Title
                        Text(
                          "CHORES",
                          style: TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                            letterSpacing: 2,
                          ),
                        ),

                        SizedBox(height: 40),

                        // Instruction
                        Text(
                          widget.choreCard.instruction,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),

                        SizedBox(height: 30),

                        // Chore Image
                        SizedBox(
                          width: MediaQuery.of(context).size.width * 0.9,
                          height: MediaQuery.of(context).size.width * 0.9,
                          child: Image.asset(
                            widget.choreCard.firstImagePath,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Footer
            Positioned(
              bottom: 15,
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

            // Close button
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                icon: Icon(Icons.close, color: Colors.black, size: 30),
                onPressed: () {
                  // Apply chore effects BEFORE closing (only if not already applied)
                  if (!hasAppliedEffect) {
                    print(
                      "ChoreGamePopup: Manually closing, applying chore effect",
                    );
                    hasAppliedEffect = true;
                    widget.onChoreComplete(widget.choreCard);
                  } else {
                    print(
                      "ChoreGamePopup: Manually closing, effect already applied",
                    );
                  }
                  widget.onClose();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EducationReviewPopup extends StatefulWidget {
  final EducationQuestion question;
  final Function(bool isCorrect, int selectedIndex)
  onAnswerSubmitted; // Updated to include selectedIndex
  final VoidCallback onClose;

  const EducationReviewPopup({
    super.key,
    required this.question,
    required this.onAnswerSubmitted,
    required this.onClose,
  });

  @override
  _EducationReviewPopupState createState() => _EducationReviewPopupState();
}

class _EducationReviewPopupState extends State<EducationReviewPopup>
    with SingleTickerProviderStateMixin {
  int? selectedAnswerIndex;
  bool _cardImageLoaded = false;
  bool _cardImageFailed = false;
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );

    // Random entrance direction
    final random = Random();
    final directions = [
      Offset(-1, 0), // From left
      Offset(1, 0), // From right
      Offset(0, -1), // From top
      Offset(0, 1), // From bottom
    ];

    final randomDirection = directions[random.nextInt(directions.length)];

    _slideAnimation = Tween<Offset>(
      begin: randomDirection,
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Only Sports uses slide card images. Every other subject (including History)
  /// uses the EDUCATION REVIEW header + question text + MCQ options only.
  bool get _isSportsSlideCard =>
      widget.question.category == QuestionCategory.sports;

  Widget _buildEducationReviewHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: const BoxDecoration(
        color: Color(0xFF00CED1),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(10),
          topRight: Radius.circular(10),
        ),
      ),
      child: Column(
        children: [
          const Text(
            'EDUCATION REVIEW',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _getCategoryDisplayName(widget.question.category),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionText() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Text(
        widget.question.question,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildMcqOptions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: List.generate(
          widget.question.options.length,
          (index) => _buildOptionItem(index),
        ),
      ),
    );
  }

  String _getCategoryDisplayName(QuestionCategory category) {
    switch (category) {
      case QuestionCategory.history:
        return 'History';
      case QuestionCategory.science:
        return 'Science';
      case QuestionCategory.math:
        return 'Math';
      case QuestionCategory.english:
        return 'English Questions';
      case QuestionCategory.spelling:
        return 'Spelling';
      case QuestionCategory.geography:
        return 'Geography';
      case QuestionCategory.sports:
        return 'Sports';
      case QuestionCategory.tvShow:
        return 'TV Show Trivia';
      case QuestionCategory.hbcu:
        return 'Historical Black College Trivia (HBCU)';
      case QuestionCategory.bible:
        return 'Bible Scripture & Knowledge Trivia';
    }
  }

  Widget _buildQuestionCardImage() {
    if (widget.question.imagePath.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Image.asset(
        widget.question.imagePath,
        fit: BoxFit.contain,
        width: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          if (!_cardImageFailed) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _cardImageFailed = true);
            });
          }
          return const SizedBox.shrink();
        },
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          final loaded = wasSynchronouslyLoaded || frame != null;
          if (loaded && !_cardImageLoaded) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _cardImageLoaded = true);
            });
          }
          if (!loaded) {
            return SizedBox(
              height: MediaQuery.of(context).size.height * 0.2,
              child: const Center(child: CircularProgressIndicator()),
            );
          }
          return child;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // History and all non-Sports subjects: header + question + MCQs only (never slide card).
    if (!_isSportsSlideCard) {
      return Dialog(
        backgroundColor: Colors.transparent,
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: SlideTransition(position: _slideAnimation, child: child),
            );
          },
          child: Container(
            width: double.infinity,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            decoration: BoxDecoration(
              color: Color(0xFF00CED1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black, width: 3),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildEducationReviewHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildQuestionText(),
                        _buildMcqOptions(),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
                _buildSubmitFooter(),
              ],
            ),
          ),
        ),
      );
    }

    // Sports only: slide card image when loaded, MCQ options below.
    final showSportsHeader = !_cardImageLoaded || _cardImageFailed;
    final showSportsQuestionText = !_cardImageLoaded || _cardImageFailed;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: SlideTransition(position: _slideAnimation, child: child),
          );
        },
        child: Container(
          width: double.infinity,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          decoration: BoxDecoration(
            color: Color(0xFF00CED1), // Turquoise color matching the images
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.black, width: 3),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showSportsHeader) _buildEducationReviewHeader(),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildQuestionCardImage(),
                      if (showSportsQuestionText) _buildQuestionText(),
                      _buildMcqOptions(),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),

              _buildSubmitFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitFooter() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Color(0xFF00CED1),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(10),
          bottomRight: Radius.circular(10),
        ),
        border: Border(
          top: BorderSide(
            color: Colors.black.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    selectedAnswerIndex != null ? _submitAnswer : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      selectedAnswerIndex != null ? Colors.red : Colors.grey,
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: selectedAnswerIndex != null ? 5 : 1,
                ),
                child: Text(
                  selectedAnswerIndex != null
                      ? 'Submit Answer'
                      : 'Select an answer first',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(bottom: 12, top: 4),
            alignment: Alignment.center,
            child: Text(
              'SAY IT NOW SELF-LOVE KIDS LLC GAME',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.black.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to build option items
  Widget _buildOptionItem(int index) {
    final isSelected = selectedAnswerIndex == index;

    return Container(
      margin: EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () {
          setState(() {
            selectedAnswerIndex = index;
          });
        },
        child: Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color:
                isSelected
                    ? Colors.white.withValues(alpha: 0.7)
                    : Colors.white.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? Colors.blue : Colors.black,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? Colors.blue : Colors.white,
                  border: Border.all(color: Colors.black),
                ),
                child: Center(
                  child: Text(
                    String.fromCharCode(65 + index), // 'A', 'B', 'C', etc.
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : Colors.black,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.question.options[index],
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Submit answer and check if correct
  void _submitAnswer() {
    if (selectedAnswerIndex != null) {
      bool isCorrect =
          selectedAnswerIndex == widget.question.correctAnswerIndex;

      // Notify parent about result with the selected index
      widget.onAnswerSubmitted(isCorrect, selectedAnswerIndex!);

      // Automatically close the dialog and continue the game
      widget.onClose();
    }
  }
}

class QuestionSummaryPopup extends StatelessWidget {
  final PlayerData player;
  final VoidCallback onClose;

  const QuestionSummaryPopup({
    super.key,
    required this.player,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF00CED1), Color(0xFF008B8B)],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(color: Colors.black38, blurRadius: 10, spreadRadius: 1),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: Colors.indigo.withValues(alpha: 0.7),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(10),
                  topRight: Radius.circular(10),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: player.color, width: 2),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.asset(player.imagePath, fit: BoxFit.cover),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    '${player.name}\'s Learning Report',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            // Content - Questions History
            Expanded(
              child:
                  player.questionHistory.isEmpty
                      ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Text(
                            'No questions answered yet!',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                      : ListView.builder(
                        padding: EdgeInsets.all(16),
                        itemCount: player.questionHistory.length,
                        itemBuilder: (context, index) {
                          final item = player.questionHistory[index];
                          return _buildQuestionHistoryItem(item, index);
                        },
                      ),
            ),

            // Performance summary
            _buildPerformanceSummary(),

            // Close button
            Padding(
              padding: EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: onClose,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Continue Game',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build individual question history item
  Widget _buildQuestionHistoryItem(QuestionHistoryItem item, int itemIndex) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: item.wasCorrect ? Colors.green : Colors.red,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question number and result
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: item.wasCorrect ? Colors.green : Colors.red,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  'Question ${itemIndex + 1}',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Spacer(),
              Icon(
                item.wasCorrect ? Icons.check_circle : Icons.cancel,
                color: item.wasCorrect ? Colors.green : Colors.red,
                size: 24,
              ),
              SizedBox(width: 4),
              Text(
                item.wasCorrect ? 'Correct' : 'Incorrect',
                style: TextStyle(
                  color: item.wasCorrect ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          SizedBox(height: 12),

          // Question text
          Text(
            item.question.question,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),

          SizedBox(height: 12),

          // Your answer
          _buildAnswerItem(
            'Your answer:',
            item.question.options[item.answeredIndex],
            item.wasCorrect,
          ),

          // If incorrect, show correct answer
          if (!item.wasCorrect)
            _buildAnswerItem(
              'Correct answer:',
              item.question.options[item.question.correctAnswerIndex],
              true,
            ),
        ],
      ),
    );
  }

  // Build answer display
  Widget _buildAnswerItem(String label, String answer, bool isCorrect) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              answer,
              style: TextStyle(
                color: isCorrect ? Colors.green.shade800 : Colors.red.shade800,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Build performance summary
  Widget _buildPerformanceSummary() {
    // Calculate statistics
    int totalQuestions = player.questionHistory.length;
    int correctAnswers =
        player.questionHistory.where((item) => item.wasCorrect).length;
    double percentage =
        totalQuestions > 0 ? (correctAnswers / totalQuestions) * 100 : 0;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.indigo.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            'Performance Summary',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Total', totalQuestions.toString()),
              _buildStatItem('Correct', correctAnswers.toString()),
              _buildStatItem('Score', '${percentage.toStringAsFixed(0)}%'),
            ],
          ),
        ],
      ),
    );
  }

  // Build stat display
  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 14, color: Colors.white70)),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

class SkipTurnPopup extends StatefulWidget {
  final VoidCallback onClose;
  final Function() onPenaltyApplied;

  const SkipTurnPopup({
    super.key,
    required this.onClose,
    required this.onPenaltyApplied,
  });

  @override
  _SkipTurnPopupState createState() => _SkipTurnPopupState();
}

// ADD THIS WIDGET AFTER SkipTurnPopup

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
  // Simplified: behave like Chores (no shuffle/intro animation)
  String currentRewardImage = "";
  int? selectedPayout;
  late RewardCard actualRewardToApply; // Store the actual reward to apply

  @override
  void initState() {
    super.initState();

    final picked = widget.rewardCard;
    currentRewardImage = picked.imagePath;
    selectedPayout = picked.rewardAmount;
    _finalInstruction = picked.instruction;
    actualRewardToApply = picked;
  }

  String _finalInstruction = "";
  String _buildFinalInstruction() => _finalInstruction;

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        width: double.infinity,
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          // Solid yellow background to match reward card theme
          color: Color(0xFFFFD700),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black, width: 4),
          boxShadow: [
            BoxShadow(color: Colors.black45, blurRadius: 15, spreadRadius: 3),
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
                      "REWARDS",
                      style: TextStyle(
                        fontSize: MediaQuery.of(context).size.width * 0.08,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        letterSpacing: 3,
                      ),
                    ),
                    SizedBox(height: 20),
                    // Instruction first (like Chores)
                    Text(
                      _buildFinalInstruction(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: MediaQuery.of(context).size.width * 0.05,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        height: 1.3,
                      ),
                    ),
                    SizedBox(height: 24),
                    // Image (no bg/border)
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.7,
                      height: MediaQuery.of(context).size.width * 0.7,
                      child: Image.asset(
                        currentRewardImage,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Footer
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  "SAY IT NOW SELF-LOVE KIDS LLC GAME",
                  style: TextStyle(
                    fontSize: MediaQuery.of(context).size.width * 0.03,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ),

            // Close button
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                icon: Icon(Icons.close, color: Colors.black, size: 30),
                onPressed: () {
                  // Apply reward effects BEFORE closing
                  print("RewardGamePopup: Closing, applying reward");
                  print("  Selected payout displayed: $selectedPayout");
                  print(
                    "  Applying actualRewardToApply.rewardAmount: ${actualRewardToApply.rewardAmount}",
                  );
                  widget.onRewardComplete(actualRewardToApply);
                  widget.onClose();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// NEW: Go To Detention Center Popup
class GoToDetentionPopup extends StatefulWidget {
  final VoidCallback onClose;
  final Function() onMoveToDetention;

  const GoToDetentionPopup({
    super.key,
    required this.onClose,
    required this.onMoveToDetention,
  });

  @override
  _GoToDetentionPopupState createState() => _GoToDetentionPopupState();
}

class _GoToDetentionPopupState extends State<GoToDetentionPopup>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1000),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _rotationAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.forward();

    // Auto move to detention center after showing the card
    Future.delayed(Duration(seconds: 3), () {
      widget.onMoveToDetention();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(scale: _scaleAnimation.value, child: child);
        },
        child: Container(
          width: double.infinity,
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: BoxDecoration(
            color: Color(0xFFFFD700), // Perfect yellow background
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.black, width: 3),
            boxShadow: [
              BoxShadow(color: Colors.black45, blurRadius: 10, spreadRadius: 2),
            ],
          ),
          child: Stack(
            children: [
              // Main content layout
              Padding(
                padding: const EdgeInsets.all(
                  8.0,
                ), // Reduced from 16.0 to 8.0 (50% margin)
                child: Column(
                  children: [
                    // Top section - GO TO text
                    Expanded(
                      flex: 2,
                      child: Container(
                        alignment: Alignment.center,
                        child: Text(
                          "GO TO",
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                            letterSpacing: 4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),

                    // Middle section - Children image (90% width) with rotation
                    Expanded(
                      flex: 6,
                      child: Container(
                        alignment: Alignment.center,
                        child: Transform.rotate(
                          angle: 3.14159, // 180 degrees rotation (pi radians)
                          child: Container(
                            width:
                                MediaQuery.of(context).size.width *
                                0.9 *
                                0.9, // 90% of 90% of screen width
                            height:
                                MediaQuery.of(context).size.width *
                                0.9 *
                                0.9, // Square aspect ratio
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: AssetImage('assets/images/corner2.png'),
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Bottom section - DETENTION CENTER text (70% smaller)
                    Expanded(
                      flex: 2,
                      child: Container(
                        alignment: Alignment.center,
                        child: Text(
                          "DETENTION CENTER",
                          style: TextStyle(
                            fontSize: 22, // Reduced from 32 (70% smaller)
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                            letterSpacing: 3,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Publisher info
              Positioned(
                bottom: 8,
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    "SAY IT NOW SELF-LOVE KIDS LLC GAME",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.black.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ),

              // Close button
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
      ),
    );
  }
}

// NEW: Wrong Parameter Popup
class WrongParameterPopup extends StatefulWidget {
  final VoidCallback onClose;
  final Function() onPenaltyApplied;

  const WrongParameterPopup({
    super.key,
    required this.onClose,
    required this.onPenaltyApplied,
  });

  @override
  _WrongParameterPopupState createState() => _WrongParameterPopupState();
}

class _WrongParameterPopupState extends State<WrongParameterPopup>
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
    Future.delayed(Duration(seconds: 3), () {
      widget.onPenaltyApplied();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(scale: _scaleAnimation.value, child: child);
        },
        child: Container(
          width: double.infinity,
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: BoxDecoration(
            color: Color(0xFFFF6B6B), // Red background for wrong parameter
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.black, width: 3),
            boxShadow: [
              BoxShadow(color: Colors.black45, blurRadius: 10, spreadRadius: 2),
            ],
          ),
          child: Stack(
            children: [
              // Main content layout
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    // Top section - WRONG PARAMETER text
                    Expanded(
                      flex: 2,
                      child: Container(
                        alignment: Alignment.center,
                        child: Text(
                          "WRONG PARAMETER",
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),

                    // Middle section - Warning icon
                    Expanded(
                      flex: 6,
                      child: Container(
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.warning_amber_rounded,
                          size: 120,
                          color: Colors.white,
                        ),
                      ),
                    ),

                    // Bottom section - Penalty text
                    Expanded(
                      flex: 2,
                      child: Container(
                        alignment: Alignment.center,
                        child: Text(
                          "LOSE \$5",
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Footer - Publisher info
              Positioned(
                bottom: 8,
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    "SAY IT NOW SELF-LOVE KIDS LLC GAME",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ),
              ),

              // Close button
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
      ),
    );
  }
}

// NEW: Bonus Popup
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
    Future.delayed(Duration(seconds: 3), () {
      widget.onBonusApplied();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(scale: _scaleAnimation.value, child: child);
        },
        child: Container(
          width: double.infinity,
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: BoxDecoration(
            color: Color(0xFF4CAF50), // Green background for bonus
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.black, width: 3),
            boxShadow: [
              BoxShadow(color: Colors.black45, blurRadius: 10, spreadRadius: 2),
            ],
          ),
          child: Stack(
            children: [
              // Main content layout
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    // Top section - BONUS text
                    Expanded(
                      flex: 2,
                      child: Container(
                        alignment: Alignment.center,
                        child: Text(
                          "BONUS",
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),

                    // Middle section - Gift icon
                    Expanded(
                      flex: 6,
                      child: Container(
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.card_giftcard,
                          size: 120,
                          color: Colors.white,
                        ),
                      ),
                    ),

                    // Bottom section - Reward text
                    Expanded(
                      flex: 2,
                      child: Container(
                        alignment: Alignment.center,
                        child: Text(
                          "GET \$10",
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Footer - Publisher info
              Positioned(
                bottom: 8,
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    "SAY IT NOW SELF-LOVE KIDS LLC GAME",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ),
              ),

              // Close button
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
      ),
    );
  }
}

// NEW: Bank Popup
class BankPopup extends StatefulWidget {
  final VoidCallback onClose;
  final Function() onCollectMoney;

  const BankPopup({
    super.key,
    required this.onClose,
    required this.onCollectMoney,
  });

  @override
  _BankPopupState createState() => _BankPopupState();
}

class _BankPopupState extends State<BankPopup>
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

    // Collect money automatically after a short delay
    Future.delayed(Duration(seconds: 3), () {
      widget.onCollectMoney();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(scale: _scaleAnimation.value, child: child);
        },
        child: Container(
          width: double.infinity,
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: BoxDecoration(
            color: Color(0xFFFFD700), // Perfect yellow background
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.black, width: 3),
            boxShadow: [
              BoxShadow(color: Colors.black45, blurRadius: 10, spreadRadius: 2),
            ],
          ),
          child: Stack(
            children: [
              // Main content layout
              Padding(
                padding: const EdgeInsets.all(
                  8.0,
                ), // Reduced from 16.0 to 8.0 (50% margin)
                child: Column(
                  children: [
                    // Top section - SAY IT NOW SELF-LOVE BANK text
                    Expanded(
                      flex: 2,
                      child: Container(
                        alignment: Alignment.center,
                        child: Text(
                          "SAY IT NOW SELF-LOVE BANK",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                            letterSpacing: 2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),

                    // Middle section - Bank image (90% width)
                    Expanded(
                      flex: 6,
                      child: Container(
                        alignment: Alignment.center,
                        child: Transform.rotate(
                          angle: 3.14159, // 180 degrees rotation (pi radians)
                          child: Container(
                            width:
                                MediaQuery.of(context).size.width *
                                0.9 *
                                0.9, // 90% of 90% of screen width
                            height:
                                MediaQuery.of(context).size.width *
                                0.9 *
                                0.9, // Square aspect ratio
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: AssetImage('assets/images/corner1.png'),
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Bottom section - COLLECT $50 text (70% smaller)
                    Expanded(
                      flex: 2,
                      child: Container(
                        alignment: Alignment.center,
                        child: Text(
                          "COLLECT \$50",
                          style: TextStyle(
                            fontSize: 22, // Reduced from 32 (70% smaller)
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                            letterSpacing: 3,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Footer - Publisher info
              Positioned(
                bottom: 8,
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    "SAY IT NOW SELF-LOVE KIDS LLC GAME",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.black.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ),

              // Close button
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
      ),
    );
  }
}

// NEW: Detention Center Popup
class DetentionCenterPopup extends StatefulWidget {
  final VoidCallback onClose;
  final Function() onPenaltyApplied;

  const DetentionCenterPopup({
    super.key,
    required this.onClose,
    required this.onPenaltyApplied,
  });

  @override
  _DetentionCenterPopupState createState() => _DetentionCenterPopupState();
}

class _DetentionCenterPopupState extends State<DetentionCenterPopup>
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
    Future.delayed(Duration(seconds: 3), () {
      widget.onPenaltyApplied();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(scale: _scaleAnimation.value, child: child);
        },
        child: Container(
          width: double.infinity,
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: BoxDecoration(
            color: Color(
              0xFFFFD700,
            ), // Perfect yellow background matching the image
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.black, width: 3),
            boxShadow: [
              BoxShadow(color: Colors.black45, blurRadius: 10, spreadRadius: 2),
            ],
          ),
          child: Stack(
            children: [
              // Main content layout
              Padding(
                padding: const EdgeInsets.all(
                  8.0,
                ), // Reduced from 16.0 to 8.0 (50% margin)
                child: Column(
                  children: [
                    // Top section - BEHAVIOR text
                    Expanded(
                      flex: 2,
                      child: Container(
                        alignment: Alignment.center,
                        child: Text(
                          "BEHAVIOR",
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                            letterSpacing: 4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),

                    // Middle section - School building image (90% width)
                    Expanded(
                      flex: 6,
                      child: Container(
                        alignment: Alignment.center,
                        child: Container(
                          width:
                              MediaQuery.of(context).size.width *
                              0.9 *
                              0.9, // 90% of 90% of screen width
                          height:
                              MediaQuery.of(context).size.width *
                              0.9 *
                              0.9, // Square aspect ratio
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: AssetImage('assets/images/corner3.png'),
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Bottom section - Penalty text and DETENTION CENTER (70% smaller text)
                    Expanded(
                      flex: 2,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Penalty text (70% smaller)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 5,
                            ), // Reduced vertical padding
                            child: Text(
                              "Pay \$50 and lose a turn",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 18, // Reduced from 26 (70% smaller)
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                                letterSpacing: 1,
                              ),
                            ),
                          ),

                          SizedBox(height: 8), // Reduced from 15
                          // DETENTION CENTER text (70% smaller)
                          Text(
                            "DETENTION CENTER",
                            style: TextStyle(
                              fontSize: 22, // Reduced from 32 (70% smaller)
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                              letterSpacing: 3,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Footer - Publisher info
              Positioned(
                bottom: 8,
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    "SAY IT NOW SELF-LOVE KIDS LLC GAME",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.black.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ),

              // Close button
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
      ),
    );
  }
}

// NEW: Jail Popup for Position 10
class JailPopup extends StatefulWidget {
  final VoidCallback onClose;

  const JailPopup({super.key, required this.onClose});

  @override
  _JailPopupState createState() => _JailPopupState();
}

class _JailPopupState extends State<JailPopup>
    with SingleTickerProviderStateMixin {
  double opacity1 = 0.0;
  double opacity2 = 0.0;
  bool showDetails = false;

  @override
  void initState() {
    super.initState();

    // Show the first image (jail icon)
    Future.delayed(Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          opacity1 = 1.0;
        });
      }
    });

    // Show the details after a delay
    Future.delayed(Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          opacity1 = 0.0;
          showDetails = true;
        });
      }

      // Fade in details
      Future.delayed(Duration(milliseconds: 300), () {
        if (mounted) {
          setState(() {
            opacity2 = 1.0;
          });
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        width: double.infinity,
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: Color(0xFFFFD700), // Yellow background like corner2
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black, width: 3),
        ),
        child: Stack(
          children: [
            // First animation: Jail image
            if (!showDetails)
              AnimatedOpacity(
                opacity: opacity1,
                duration: Duration(milliseconds: 500),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Title
                      Padding(
                        padding: const EdgeInsets.only(bottom: 40.0),
                        child: Text(
                          "DETENTION CENTER",
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                            letterSpacing: 2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                      // Jail image (corner2.png) - Rotated 90 degrees
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.7,
                        height: MediaQuery.of(context).size.width * 0.7,
                        child: Transform.rotate(
                          angle: 90 * 3.14159 / 180, // 90 degrees in radians
                          child: Image.asset(
                            'assets/images/corner2.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Second animation: Details with fee
            if (showDetails)
              AnimatedOpacity(
                opacity: opacity2,
                duration: Duration(milliseconds: 500),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Title
                        Text(
                          "YOU'RE IN JAIL!",
                          style: TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                            letterSpacing: 2,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        SizedBox(height: 40),

                        // Instruction
                        Container(
                          padding: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.black, width: 2),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.lock, size: 60, color: Colors.red),
                              SizedBox(height: 20),
                              Text(
                                "Pay \$25 at the start of your next turn to be released.",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 30),

                        // Jail Image - Rotated 90 degrees
                        SizedBox(
                          width: MediaQuery.of(context).size.width * 0.6,
                          height: MediaQuery.of(context).size.width * 0.6,
                          child: Transform.rotate(
                            angle: 90 * 3.14159 / 180, // 90 degrees in radians
                            child: Image.asset(
                              'assets/images/corner2.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Footer
            Positioned(
              bottom: 15,
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

            // Close button
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

class _SkipTurnPopupState extends State<SkipTurnPopup>
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
      widget.onPenaltyApplied();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(scale: _scaleAnimation.value, child: child);
        },
        child: Container(
          width: double.infinity,
          height: MediaQuery.of(context).size.height * 0.55,
          decoration: BoxDecoration(
            color: Color(0xFFFF4500), // Orange red color
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.black, width: 3),
            boxShadow: [
              BoxShadow(color: Colors.black45, blurRadius: 10, spreadRadius: 2),
            ],
          ),
          child: Stack(
            children: [
              // Main content
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Stop icon
                      Icon(Icons.stop_circle, size: 80, color: Colors.white),

                      SizedBox(height: 20),

                      // Title
                      Text(
                        "FREEZE!",
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 2,
                        ),
                      ),

                      SizedBox(height: 20),

                      // Message
                      Text(
                        "You landed on the freeze square!\nYou must skip your next turn!",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Footer
              Positioned(
                bottom: 15,
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    "SAY IT NOW SELF-LOVE KIDS LLC GAME",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white70,
                    ),
                  ),
                ),
              ),

              // Close button
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
      ),
    );
  }
}

// These methods should be added to _CirclePatternState class as needed

class FinalGameSummaryPopup extends StatefulWidget {
  final List<PlayerData> players;
  const FinalGameSummaryPopup({super.key, required this.players});

  @override
  State<FinalGameSummaryPopup> createState() => _FinalGameSummaryPopupState();
}

class _FinalGameSummaryPopupState extends State<FinalGameSummaryPopup> {
  int currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    // Sort players by money (descending)
    final sortedPlayers = [...widget.players]
      ..sort((a, b) => b.totalMoney.compareTo(a.totalMoney));
    final currentPlayer = sortedPlayers[currentIndex];

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black, width: 3),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Game Over! Player Rankings',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              // Rankings bar/list
              SizedBox(
                height: 120,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: sortedPlayers.length,
                  itemBuilder: (context, i) {
                    final p = sortedPlayers[i];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: AssetImage(p.imagePath),
                      ),
                      title: Text('${i + 1}. ${p.name}'),
                      trailing: Text(
                        '24${p.totalMoney}',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      tileColor:
                          i == currentIndex
                              ? Colors.amber.withValues(alpha: 0.2)
                              : null,
                    );
                  },
                ),
              ),
              Divider(height: 32),
              // Per-player stats
              Text(
                '${currentIndex + 1}st: ${currentPlayer.name} Stats',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              _buildPlayerStats(currentPlayer),
              SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (currentIndex > 0)
                    ElevatedButton(
                      onPressed: () => setState(() => currentIndex--),
                      child: Text('Previous'),
                    ),
                  ElevatedButton(
                    onPressed: () {
                      if (currentIndex < sortedPlayers.length - 1) {
                        setState(() => currentIndex++);
                      } else {
                        Navigator.of(context).pop();
                      }
                    },
                    child: Text(
                      currentIndex < sortedPlayers.length - 1
                          ? 'Next'
                          : 'Close',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerStats(PlayerData player) {
    int totalQuestions = player.questionHistory.length;
    int correctAnswers =
        player.questionHistory.where((item) => item.wasCorrect).length;
    int wrongAnswers = totalQuestions - correctAnswers;
    return Column(
      children: [
        Text('Total Questions: $totalQuestions'),
        Text('Correct Answers: $correctAnswers'),
        Text('Wrong Answers: $wrongAnswers'),
      ],
    );
  }
}
