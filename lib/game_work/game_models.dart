// ==================== CHORE MODELS ====================

enum ChoreRewardType {
  collectFromBank,
  collectFromPlayers,
  collectFromParents,
  collectFromPlayerAhead,
}

class ChoreCard {
  final String title = "CHORES";
  final String instruction;
  final String firstImagePath;
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

// Map of positions to chore cards
final Map<int, ChoreCard> choreCards = {
  2: ChoreCard(
    instruction: "Do the laundry and earn \$7 from each player ahead of you.",
    firstImagePath: "assets/rewards/chores_02.png",
    rewardType: ChoreRewardType.collectFromPlayerAhead,
    rewardAmount: 7,
    targetType: "each player ahead of you",
  ),
  6: ChoreCard(
    instruction: "Take the trash out home and earn \$3 from each player.",
    firstImagePath: "assets/rewards/chores_03.png",
    rewardType: ChoreRewardType.collectFromPlayers,
    rewardAmount: 3,
    targetType: "each player",
  ),
  12: ChoreCard(
    instruction: "Mop and sweep the floor and earn \$12 from the bank.",
    firstImagePath: "assets/rewards/chores_04.png",
    rewardType: ChoreRewardType.collectFromBank,
    rewardAmount: 12,
    targetType: "the bank",
  ),
  16: ChoreCard(
    instruction: "You washed the car, you earn \$10 from each player.",
    firstImagePath: "assets/rewards/chores_05.png",
    rewardType: ChoreRewardType.collectFromPlayers,
    rewardAmount: 10,
    targetType: "each player",
  ),
  22: ChoreCard(
    instruction: "Clean your refrigerator and earn \$5 from the bank.",
    firstImagePath: "assets/rewards/chores_06.png",
    rewardType: ChoreRewardType.collectFromBank,
    rewardAmount: 5,
    targetType: "the bank",
  ),
  26: ChoreCard(
    instruction: "Vacuum your bedroom and earn \$1 from each parent.",
    firstImagePath: "assets/rewards/chores_07.png",
    rewardType: ChoreRewardType.collectFromParents,
    rewardAmount: 1,
    targetType: "each parent",
  ),
  32: ChoreCard(
    instruction: "Clean bathroom and earn \$4 from the bank.",
    firstImagePath: "assets/rewards/chores_08.png",
    rewardType: ChoreRewardType.collectFromBank,
    rewardAmount: 4,
    targetType: "the bank",
  ),
  36: ChoreCard(
    instruction: "Clean kitchen and earn \$2 from parents.",
    firstImagePath: "assets/rewards/chores_09.png",
    rewardType: ChoreRewardType.collectFromParents,
    rewardAmount: 2,
    targetType: "parents",
  ),
};

// ==================== REWARD MODELS ====================

enum RewardType {
  collectFromBank,
  collectFromParents,
  giftCard,
}

class RewardCard {
  final String title = "REWARDS";
  final String instruction;
  final String imagePath;
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

class GameRewardDefinition {
  final String imagePath;
  final List<int> possiblePayouts;
  final String title;

  const GameRewardDefinition({
    required this.imagePath,
    required this.possiblePayouts,
    required this.title,
  });
}

final List<GameRewardDefinition> kGameRewards = [
  GameRewardDefinition(
    imagePath: "assets/game_reward/rewards_02.png",
    possiblePayouts: [3, 5, 7, 10],
    title: "Treat Time",
  ),
  GameRewardDefinition(
    imagePath: "assets/game_reward/rewards_03.png",
    possiblePayouts: [3, 5, 7, 12],
    title: "Star Player",
  ),
  GameRewardDefinition(
    imagePath: "assets/game_reward/rewards_04.png",
    possiblePayouts: [5, 7, 10, 15],
    title: "Great Job",
  ),
  GameRewardDefinition(
    imagePath: "assets/game_reward/rewards_05.png",
    possiblePayouts: [3, 4, 6, 8, 10],
    title: "Surprise Gift",
  ),
  GameRewardDefinition(
    imagePath: "assets/game_reward/rewards_06.png",
    possiblePayouts: [5, 7, 9, 11, 13],
    title: "Bonus Bucks",
  ),
  GameRewardDefinition(
    imagePath: "assets/game_reward/rewards_07.png",
    possiblePayouts: [3, 5, 8, 12],
    title: "Lucky Day",
  ),
  GameRewardDefinition(
    imagePath: "assets/game_reward/rewards_08.png",
    possiblePayouts: [4, 6, 9, 14],
    title: "Level Up",
  ),
  GameRewardDefinition(
    imagePath: "assets/game_reward/rewards_09.png",
    possiblePayouts: [3, 5, 7, 10, 15],
    title: "Win Win",
  ),
  GameRewardDefinition(
    imagePath: "assets/game_reward/rewards_10.png",
    possiblePayouts: [6, 8, 10, 12],
    title: "Power Up",
  ),
  GameRewardDefinition(
    imagePath: "assets/game_reward/rewards_11.png",
    possiblePayouts: [3, 5, 7, 9, 11],
    title: "Big Smile",
  ),
  GameRewardDefinition(
    imagePath: "assets/game_reward/rewards_12.png",
    possiblePayouts: [5, 10, 15, 20],
    title: "Jackpot Jr.",
  ),
];

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

final List<RewardDefinition> kRewardCards = [
  RewardDefinition(
    imagePath: 'assets/game_reward/rewards_02.png',
    description: "You stayed with your exercise and diet routine plan. Earn \$25.00 Gift Card from Say it Now Self-Love Bank",
    amount: 25,
  ),
  RewardDefinition(
    imagePath: 'assets/game_reward/rewards_03.png',
    description: "You got straight A's on your report card. You earn \$10.00 from each parent.",
    amount: 10,
  ),
  RewardDefinition(
    imagePath: 'assets/game_reward/rewards_04.png',
    description: "You helped your sibling with homework. Each parent gives you \$5.00.",
    amount: 5,
  ),
];

// ==================== BEHAVIOR MODELS ====================

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
  final int amount;

  const BehaviorEffect({required this.type, this.amount = 0});
}

final List<BehaviorDefinition> kBehaviorCards = [
  BehaviorDefinition(
    imagePath: 'assets/behavior/behavior_02.png',
    kind: BehaviorKind.positive,
    description: "You helped change the baby diaper. Earn \$2 from both parents.",
    effects: [
      BehaviorEffect(type: BehaviorEffectType.collectFromParents, amount: 2),
    ],
  ),
  BehaviorDefinition(
    imagePath: 'assets/behavior/behavior_03.png',
    kind: BehaviorKind.positive,
    description: "You wrote your name correctly. Each player gives you a hug and \$1.",
    effects: [
      BehaviorEffect(type: BehaviorEffectType.collectFromEachPlayer, amount: 1),
    ],
  ),
  BehaviorDefinition(
    imagePath: 'assets/behavior/behavior_04.png',
    kind: BehaviorKind.positive,
    description: "You helped a friend with schoolwork. You earn \$2 from each player.",
    effects: [
      BehaviorEffect(type: BehaviorEffectType.collectFromEachPlayer, amount: 2),
    ],
  ),
  BehaviorDefinition(
    imagePath: 'assets/behavior/behavior_05.png',
    kind: BehaviorKind.negative,
    description: "You were untruthful about doing your homework. Pay parents \$5 each and lose a turn.",
    effects: [
      BehaviorEffect(type: BehaviorEffectType.payParents, amount: 5),
      BehaviorEffect(type: BehaviorEffectType.loseTurn),
    ],
  ),
  BehaviorDefinition(
    imagePath: 'assets/behavior/behavior_06.png',
    kind: BehaviorKind.negative,
    description: "You used profanity 'a Bad word' pay each player \$3.",
    effects: [
      BehaviorEffect(type: BehaviorEffectType.payEachPlayer, amount: 3),
    ],
  ),
  BehaviorDefinition(
    imagePath: 'assets/behavior/behavior_07.png',
    kind: BehaviorKind.negative,
    description: "You did not complete your chore. Pay bank \$10.",
    effects: [
      BehaviorEffect(type: BehaviorEffectType.payBank, amount: 10),
    ],
  ),
  BehaviorDefinition(
    imagePath: 'assets/behavior/behavior_08.png',
    kind: BehaviorKind.negative,
    description: "You skipped class. Pay each player \$5.",
    effects: [
      BehaviorEffect(type: BehaviorEffectType.payEachPlayer, amount: 5),
    ],
  ),
  BehaviorDefinition(
    imagePath: 'assets/behavior/behavior_09.png',
    kind: BehaviorKind.negative,
    description: "You acted out in class and did not follow instructions. Pay each parent \$10 and lose a turn.",
    effects: [
      BehaviorEffect(type: BehaviorEffectType.payParents, amount: 10),
      BehaviorEffect(type: BehaviorEffectType.loseTurn),
    ],
  ),
  BehaviorDefinition(
    imagePath: 'assets/behavior/behavior_10.png',
    kind: BehaviorKind.negative,
    description: "You got caught stealing. Go to Behavior Detention Center space and lose 2 turns. Pay bank \$20.",
    effects: [
      BehaviorEffect(type: BehaviorEffectType.goToDetention),
      BehaviorEffect(type: BehaviorEffectType.loseTurn),
      BehaviorEffect(type: BehaviorEffectType.payBank, amount: 20),
    ],
  ),
  BehaviorDefinition(
    imagePath: 'assets/behavior/behavior_11.png',
    kind: BehaviorKind.positive,
    description: "You helped an elderly person with crossing the street. Move ahead 1 space. Earn \$5 from the bank.",
    effects: [
      BehaviorEffect(type: BehaviorEffectType.moveAhead, amount: 1),
      BehaviorEffect(type: BehaviorEffectType.collectFromBank, amount: 5),
    ],
  ),
  BehaviorDefinition(
    imagePath: 'assets/behavior/behavior_12.png',
    kind: BehaviorKind.negative,
    description: "You were fighting in school. Apologize to your teacher and parents. Pay each player \$1.",
    effects: [
      BehaviorEffect(type: BehaviorEffectType.payEachPlayer, amount: 1),
    ],
  ),
];

// ==================== EDUCATION/QUIZ MODELS ====================

class EducationQuestion {
  final String question;
  final List<String> options;
  final int correctIndex;
  final String category;

  const EducationQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.category,
  });
}

// Sample education questions
final List<EducationQuestion> kEducationQuestions = [
  EducationQuestion(
    question: "What is 2 + 2?",
    options: ["3", "4", "5", "6"],
    correctIndex: 1,
    category: "Math",
  ),
  EducationQuestion(
    question: "What color is the sky?",
    options: ["Red", "Blue", "Green", "Yellow"],
    correctIndex: 1,
    category: "Science",
  ),
  EducationQuestion(
    question: "How many days are in a week?",
    options: ["5", "6", "7", "8"],
    correctIndex: 2,
    category: "General",
  ),
];

// ==================== BOARD POSITION TYPES ====================

// Special square positions on the board
final Set<int> rewardSquarePositions = {1, 7, 13, 19, 25, 31, 37};
final Set<int> choreSquarePositions = {2, 6, 12, 16, 22, 26, 32, 36};
final Set<int> behaviorSquarePositions = {3, 9, 15, 21, 27, 33, 39};
final Set<int> educationSquarePositions = {5, 11, 17, 23, 29, 35};
final Set<int> penaltySquarePositions = {8, 18, 28, 38};
final Set<int> skipTurnSquarePositions = {4};
final Set<int> bonusSquarePositions = {14, 24, 34};
final Set<int> wrongParameterSquarePositions = {20};
final Set<int> goToDetentionSquarePositions = {30};
final Set<int> bankSquarePositions = {0};
final Set<int> detentionCenterSquarePositions = {10};
