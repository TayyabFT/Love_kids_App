# Game Frontend Components - Extracted & Modularized

This folder contains all the frontend UI components extracted from `game_screen_bk.dart` and organized into modular files.

## 📁 File Structure

```
game_work/
├── README.md                    # This file
├── player_adding.dart           # ✅ Player selection & character setup
├── welcome_screen.dart          # ✅ Welcome/splash screen
├── game_models.dart             # ✅ All data models (chores, rewards, behaviors, etc.)
└── game_popups.dart             # ✅ All game popup dialogs
```

## ✅ Completed Modules

### 1. **player_adding.dart**
**Purpose**: Player selection and character setup interface

**Components**:
- `PlayerData` class - Stores player information (name, color, character, image)
- `CharacterSelectionScreen` widget - Full player selection UI
  - 8 character avatars with images (ch1.png - ch8.png)
  - Name input field with validation
  - Add/Remove players functionality
  - Auto-scrolling to next available character
  - Audio support for game sounds
  - Start game button (2-8 players required)

**Usage**:
```dart
CharacterSelectionScreen(
  onGameStart: (List<PlayerData> players) {
    // Handle game start with selected players
  }
)
```

---

### 2. **welcome_screen.dart**
**Purpose**: Welcome/splash screen shown for 2 seconds before character selection

**Components**:
- `WelcomeScreen` widget - Animated welcome screen
  - App logo display
  - App title with shadow effects
  - Gradient background (orange theme)
  - Auto-dismisses after timer

**Usage**:
```dart
WelcomeScreen()
```

---

### 3. **game_models.dart**
**Purpose**: All game data models and definitions

**Components**:

#### Chore Models:
- `ChoreRewardType` enum - Types of chore rewards
- `ChoreCard` class - Chore card data structure
- `choreCards` Map - Positions 2, 6, 12, 16, 22, 26, 32, 36

#### Reward Models:
- `RewardType` enum - Types of rewards
- `RewardCard` class - Reward card structure
- `GameRewardDefinition` class - Game reward definitions
- `kGameRewards` List - 11 different game rewards (rewards_02.png to rewards_12.png)
- `RewardDefinition` class - Detailed reward definitions
- `kRewardCards` List - Specific reward cards with descriptions

#### Behavior Models:
- `BehaviorKind` enum - Positive/Negative behaviors
- `BehaviorEffectType` enum - 9 different effect types
- `BehaviorDefinition` class - Behavior card structure
- `BehaviorEffect` class - Individual effects
- `kBehaviorCards` List - 11 behavior cards (behavior_02.png to behavior_12.png)

#### Education/Quiz Models:
- `EducationQuestion` class - Quiz question structure
- `kEducationQuestions` List - Sample quiz questions

#### Board Position Maps:
- `rewardSquarePositions` - Positions: 1, 7, 13, 19, 25, 31, 37
- `choreSquarePositions` - Positions: 2, 6, 12, 16, 22, 26, 32, 36
- `behaviorSquarePositions` - Positions: 3, 9, 15, 21, 27, 33, 39
- `educationSquarePositions` - Positions: 5, 11, 17, 23, 29, 35
- `penaltySquarePositions` - Positions: 8, 18, 28, 38
- `skipTurnSquarePositions` - Position: 4
- `bonusSquarePositions` - Positions: 14, 24, 34
- `wrongParameterSquarePositions` - Position: 20
- `goToDetentionSquarePositions` - Position: 30
- `bankSquarePositions` - Position: 0
- `detentionCenterSquarePositions` - Position: 10

**Total Board Squares**: 40 (0-39)

---

### 4. **game_popups.dart**
**Purpose**: All popup dialog widgets for game interactions

**Components**:

#### Generic Popups:
- `GamePopup` - Two-image transition popup (generic)

#### Chore System:
- `ChoreGamePopup` - Chore card display and reward application
  - Shows cleaning supplies image first
  - Transitions to chore details
  - Auto-applies reward after 3 seconds

#### Reward System:
- `RewardGamePopup` - Reward card display
  - Gold-themed design
  - Shows reward image and description
  - Auto-applies reward

#### Behavior System:
- `BehaviorPopup` - Behavior card display
  - Green-themed for behavior
  - Shows intro image first (behavior_01.png)
  - Randomly selects behavior card
  - Displays effects and description

#### Special Square Popups:
- `PenaltyPopup` - Penalty square notification
  - Red theme with warning icon
  - Charges $10 to bank
  - Auto-closes after 2 seconds

- `BonusPopup` - Bonus square notification
  - Green theme with star icon
  - Awards $15 from bank
  - Auto-closes after 2 seconds

**All popups include**:
- Animated transitions (fade in/out, scale)
- Close button (X icon)
- Footer text: "SAY IT NOW SELF-LOVE KIDS LLC GAME"
- Theme-specific colors and styling

---

## 🎨 Design System

### Colors Used:
- **Orange Gradient**: `#FFC080` → `#FCB366` → `#FD8D3C` (Background)
- **Chore Theme**: `#8B4513` (Brown)
- **Reward Theme**: `#FFD700` (Gold)
- **Behavior Theme**: `#1FA51F` (Green)
- **Penalty**: Red
- **Bonus**: Green with yellow star

### Character Colors:
1. Red
2. Blue
3. Green
4. Orange
5. Purple
6. Teal
7. Pink
8. Amber

---

## 🎮 Game Flow Implementation

### Current Flow (Implemented):
```
1. WelcomeScreen (2 seconds)
   ↓
2. CharacterSelectionScreen
   - Add 2-8 players
   - Select characters & names
   ↓
3. GameBoard (Placeholder)
   - Ready for full board implementation
```

### Future Flow (To Be Implemented):
```
GameBoard with:
- 40-square circular board
- Dice rolling mechanism
- Player movement animations
- Turn management
- Money system
- Popup triggers based on square positions
- Win conditions
- Game summary
```

---

## 📦 Assets Required

### Character Images:
- `assets/images/ch1.png` through `assets/images/ch8.png` ✅

### Reward Images:
- `assets/game_reward/rewards_02.png` through `rewards_12.png`

### Chore Images:
- `assets/rewards/chores_02.png` through `chores_09.png`

### Behavior Images:
- `assets/behavior/behavior_01.png` (intro)
- `assets/behavior/behavior_02.png` through `behavior_12.png`

### Game Sounds:
- `assets/game_sound/roll_set.mp3` ✅

### Board Elements:
- `assets/images/circle.png` (game logo) ✅
- Dice images: `dise_1.png` through `dise_6.png`
- Corner images: `corner1.png` through `corner4.png`
- Side square images: `top_1.png`, `right_1.png`, `bottom_1.png`, `left_1.png`, etc.

---

## 🚀 How to Use

### In game_screen.dart:
```dart
import '../game_work/player_adding.dart';
import '../game_work/welcome_screen.dart';
import '../game_work/game_models.dart';
import '../game_work/game_popups.dart';

// Show welcome screen for 2 seconds
WelcomeScreen()

// Then show character selection
CharacterSelectionScreen(
  onGameStart: (players) {
    // Start game with selected players
  }
)

// Show popups during gameplay
showDialog(
  context: context,
  builder: (context) => ChoreGamePopup(
    choreCard: choreCards[2]!,
    onChoreComplete: (card) { /* Apply reward */ },
    onClose: () => Navigator.pop(context),
  ),
)
```

---

## 📝 Next Steps

### To Complete the Game:

1. **Create `game_board.dart`**:
   - `CirclePattern` widget - Main board display
   - 40 square positions in circular layout
   - Player tokens/avatars on board
   - Board square UI with images

2. **Create `dice_widget.dart`**:
   - Dice rolling animation
   - Two dice display
   - Roll button
   - Sound effects

3. **Create `player_info_widget.dart`**:
   - Current player display
   - Money counter
   - Turn indicator
   - Player stats

4. **Create `game_logic.dart`**:
   - Turn management
   - Player movement
   - Square action triggers
   - Money transactions
   - Win condition checking

5. **Integrate Full Game Board**:
   - Replace `GameBoard` placeholder in `game_screen.dart`
   - Connect all popups to board squares
   - Implement animation system
   - Add sound effects

---

## ✨ Features Implemented

- ✅ Modular architecture
- ✅ Clean code separation
- ✅ Reusable components
- ✅ Type-safe data models
- ✅ Animated UI transitions
- ✅ Audio support
- ✅ Responsive layouts
- ✅ Material Design compliance
- ✅ Consistent theming

---

## 🎯 Testing Checklist

- [ ] Welcome screen displays for 2 seconds
- [ ] Character selection allows 2-8 players
- [ ] Can't select same character twice
- [ ] Name validation works
- [ ] Auto-scroll to next character works
- [ ] Start game sound plays
- [ ] All popups display correctly
- [ ] Animations are smooth
- [ ] Close buttons work
- [ ] All assets load properly

---

## 📚 Documentation

Each file contains inline comments explaining:
- Purpose of classes/widgets
- Parameter descriptions
- Usage examples
- Important notes

**All frontend components are now ready for full game board integration!** 🎮
