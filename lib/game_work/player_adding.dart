import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'player_data.dart'; // Import the complete PlayerData class

// Character Selection Screen with player adding functionality
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
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
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
                height: MediaQuery.of(context).size.width > 600
                    ? 140
                    : 190, // Smaller height for tablets
                child: GridView.builder(
                  controller: _gridScrollController, // Add the controller here
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: MediaQuery.of(context).size.width > 600
                        ? 4
                        : 3, // More columns on tablets
                    childAspectRatio: MediaQuery.of(context).size.width > 600
                        ? 0.9
                        : 0.8, // Adjusted ratio for tablets
                    crossAxisSpacing: MediaQuery.of(context).size.width > 600
                        ? 6
                        : 8, // Smaller spacing on tablets
                    mainAxisSpacing: MediaQuery.of(context).size.width > 600
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
                      onTap: isUsed
                          ? null
                          : () {
                              setState(() {
                                selectedCharacterIndex = index;
                              });
                            },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isUsed
                              ? Colors.grey.withValues(alpha: 0.5)
                              : isSelected
                                  ? Colors.white.withValues(alpha: 0.3)
                                  : Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: isSelected
                              ? Border.all(color: Colors.white, width: 2)
                              : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Character image - responsive sizing
                            Container(
                              width: MediaQuery.of(context).size.width > 600
                                  ? 40
                                  : 60, // Smaller on tablets
                              height: MediaQuery.of(context).size.width > 600
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
                                height: MediaQuery.of(context).size.width > 600
                                    ? 4
                                    : 8),
                            Text(
                              characterNames[index],
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: MediaQuery.of(context).size.width > 600
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
                    onPressed: canAddPlayer()
                        ? () {
                            setState(() {
                              // Add the current player with selected character
                              selectedPlayers.add(
                                PlayerData(
                                  name: nameController.text.trim(),
                                  color: characterColors[selectedCharacterIndex],
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
                                WidgetsBinding.instance.addPostFrameCallback((
                                  _,
                                ) {
                                  _scrollToCharacter(nextAvailableIndex);
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
              Expanded(
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
                        child: selectedPlayers.isEmpty
                            ? Center(
                                child: Text(
                                  'Add at least 2 players to start',
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
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.8),
                                      borderRadius: BorderRadius.circular(8),
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
                                          icon: Icon(Icons.delete, size: 20),
                                          color: Colors.red,
                                          padding: EdgeInsets.all(4),
                                          constraints: BoxConstraints(),
                                          onPressed: () {
                                            setState(() {
                                              selectedPlayers.removeAt(index);
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

              // Start game button
              ElevatedButton(
                onPressed: selectedPlayers.length < 2
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
                  'Start Game (${selectedPlayers.length}/2-8 Players)',
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
    );
  }
}
