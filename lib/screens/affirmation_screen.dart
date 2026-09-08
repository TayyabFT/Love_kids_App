import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';

class AffirmationScreen extends StatefulWidget {
  const AffirmationScreen({super.key});

  @override
  State<AffirmationScreen> createState() => _AffirmationScreenState();
}

class _AffirmationScreenState extends State<AffirmationScreen>
    with TickerProviderStateMixin {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final PageController _pageController = PageController();
  final TextEditingController _nameController = TextEditingController();
  
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late AnimationController _progressController;
  late AnimationController _heartController;
  
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _progressAnimation;
  late Animation<double> _heartAnimation;
  
  String userName = '';
  String userGender = '';
  int currentStep = 0;
  int currentImageIndex = 1;
  
  List<String> get currentImagePaths {
    if (userGender == 'boy') {
      return [
        'assets/affteremation/boy/1.webp',
        'assets/affteremation/boy/2.webp',
        'assets/affteremation/boy/3.webp',
        'assets/affteremation/boy/4.webp',
        'assets/affteremation/boy/5.webp',
        'assets/affteremation/boy/6.webp',
        'assets/affteremation/boy/7.webp',
        'assets/affteremation/boy/8.webp',
        'assets/affteremation/boy/9.webp',
        'assets/affteremation/boy/10.webp',
        'assets/affteremation/boy/11.webp',
        'assets/affteremation/boy/12.webp',
      ];
    } else {
      return [
        'assets/affteremation/girl/1.webp',
        'assets/affteremation/girl/2.webp',
        'assets/affteremation/girl/3.webp',
        'assets/affteremation/girl/4.webp',
        'assets/affteremation/girl/5.webp',
        'assets/affteremation/girl/6.webp',
        'assets/affteremation/girl/7.webp',
        'assets/affteremation/girl/8.webp',
        'assets/affteremation/girl/9.webp',
        'assets/affteremation/girl/10.webp',
        'assets/affteremation/girl/11.webp',
        'assets/affteremation/girl/12.webp',
      ];
    }
  }

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controllers
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );
    
    _scaleController = AnimationController(
      duration: Duration(milliseconds: 400),
      vsync: this,
    );
    
    _progressController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _heartController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );
    
    // Initialize animations
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.elasticOut,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.bounceOut,
    ));
    
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    ));
    
    _heartAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _heartController,
      curve: Curves.elasticInOut,
    ));
    
    // Start initial animations
    _fadeController.forward();
    _scaleController.forward();
    _heartController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    _progressController.dispose();
    _heartController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playAffirmationSound() async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.setVolume(1.0);
      await _audioPlayer.setPlayerMode(PlayerMode.mediaPlayer);
      await _audioPlayer.play(AssetSource('game_sound/afsound.mp3'), volume: 1.0);
    } catch (e) {
      print('Error playing affirmation sound: $e');
    }
  }

  Future<void> _playBoyAffirmationSoundForIndex(int imageIndex) async {
    // Mapping: image 2 -> 1.m4a, ..., image 12 -> 11.m4a
    if (userGender != 'boy') return;
    final soundIndex = imageIndex - 1; // 2->1, 12->11
    if (soundIndex < 1 || soundIndex > 11) return;
    final path = 'affteremation/boy/sounds/$soundIndex.m4a';
    try {
      await _audioPlayer.stop();
      await _audioPlayer.setVolume(1.0);
      await _audioPlayer.setPlayerMode(PlayerMode.mediaPlayer);
      await _audioPlayer.play(AssetSource(path), volume: 1.0);
    } catch (e) {
      print('Error playing boy affirmation sound for index $imageIndex: $e');
    }
  }

  Future<void> _playGirlAffirmationSoundForIndex(int imageIndex) async {
    // Mapping: image 2 -> 1.m4a, ..., image 12 -> 11.m4a
    if (userGender != 'girl') return;
    final soundIndex = imageIndex - 1;
    if (soundIndex < 1 || soundIndex > 11) return;
    final path = 'affteremation/girl/sounds/$soundIndex.m4a';
    try {
      await _audioPlayer.stop();
      await _audioPlayer.setVolume(1.0);
      await _audioPlayer.setPlayerMode(PlayerMode.mediaPlayer);
      await _audioPlayer.play(AssetSource(path), volume: 1.0);
    } catch (e) {
      print('Error playing girl affirmation sound for index $imageIndex: $e');
    }
  }

  void _nextStep() {
    _fadeController.reset();
    _scaleController.reset();
    setState(() {
      currentStep++;
    });
    _fadeController.forward();
    _scaleController.forward();
  }

  void _previousStep() {
    _fadeController.reset();
    setState(() {
      if (currentStep > 0) currentStep--;
    });
    _fadeController.forward();
  }

  void _nextImage() {
    if (currentImageIndex < currentImagePaths.length) {
      _slideController.reset();
      _progressController.reset();
      setState(() {
        currentImageIndex++;
      });
      if (userGender == 'boy') {
        _playBoyAffirmationSoundForIndex(currentImageIndex);
      } else if (userGender == 'girl') {
        _playGirlAffirmationSoundForIndex(currentImageIndex);
      } else {
        _playAffirmationSound();
      }
      _slideController.forward();
      _progressController.forward();
    } else {
      Navigator.pop(context);
    }
  }

  void _previousImage() {
    if (currentImageIndex > 1) {
      _slideController.reset();
      _progressController.reset();
      setState(() {
        currentImageIndex--;
      });
      if (userGender == 'boy') {
        _playBoyAffirmationSoundForIndex(currentImageIndex);
      } else if (userGender == 'girl') {
        _playGirlAffirmationSoundForIndex(currentImageIndex);
      } else {
        _playAffirmationSound();
      }
      _slideController.forward();
      _progressController.forward();
    }
  }

  void _startAffirmations() {
    _slideController.reset();
    _progressController.reset();
    setState(() {
      currentImageIndex = 2;
    });
    if (userGender == 'boy') {
      _playBoyAffirmationSoundForIndex(currentImageIndex);
    } else if (userGender == 'girl') {
      _playGirlAffirmationSoundForIndex(currentImageIndex);
    } else {
      _playAffirmationSound();
    }
    _slideController.forward();
    _progressController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF8E8D0),
              Color(0xFFFFE0B2),
            ],
          ),
        ),
        child: SafeArea(
          child: AnimatedSwitcher(
            duration: Duration(milliseconds: 600),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: Offset(1.0, 0.0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeInOutCubic,
                )),
                child: FadeTransition(
                  opacity: animation,
                  child: child,
                ),
              );
            },
            child: currentStep == 0 
                ? _buildNameInputStep()
                : currentStep == 1 
                    ? _buildGenderSelectionStep()
                    : _buildAffirmationStep(),
          ),
        ),
      ),
    );
  }

  Widget _buildNameInputStep() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Header with slide animation
              SlideTransition(
                position: Tween<Offset>(
                  begin: Offset(0.0, -1.0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: _fadeController,
                  curve: Curves.bounceOut,
                )),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: Color(0xFF8B4513)),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Text(
                        'Self-Love Affirmations',
                        style: GoogleFonts.roboto(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF8B4513),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(width: 48),
                  ],
                ),
              ),
              
              SizedBox(height: 60),
              
              // Animated heart icon
              AnimatedBuilder(
                animation: _heartAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _heartAnimation.value,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFFFF6B6B).withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.favorite,
                        size: 60,
                        color: Color(0xFFFF6B6B),
                      ),
                    ),
                  );
                },
              ),
              
              SizedBox(height: 40),
              
              // Animated welcome text
              SlideTransition(
                position: Tween<Offset>(
                  begin: Offset(0.0, 1.0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: _fadeController,
                  curve: Curves.elasticOut,
                )),
                child: Column(
                  children: [
                    Text(
                      'Welcome to Your Daily Affirmations!',
                      style: GoogleFonts.roboto(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3748),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    SizedBox(height: 16),
                    
                    Text(
                      'Let\'s start by getting to know you better.\nWhat\'s your name?',
                      style: GoogleFonts.roboto(
                        fontSize: 16,
                        color: Color(0xFF4A5568),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 40),
              
              // Animated name input
              SlideTransition(
                position: Tween<Offset>(
                  begin: Offset(-1.0, 0.0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: _fadeController,
                  curve: Curves.elasticOut,
                )),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _nameController,
                    style: GoogleFonts.roboto(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      hintText: 'Enter your name',
                      hintStyle: GoogleFonts.roboto(
                        color: Colors.grey.shade500,
                        fontSize: 18,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                    ),
                    onChanged: (value) {
                      setState(() {
                        userName = value.trim();
                      });
                    },
                  ),
                ),
              ),
              
              SizedBox(height: 40),
              
              // Animated continue button
              AnimatedContainer(
                duration: Duration(milliseconds: 300),
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: userName.isNotEmpty ? () {
                    _nextStep();
                  } : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: userName.isNotEmpty ? Color(0xFFFF6B6B) : Colors.grey.shade300,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: userName.isNotEmpty ? 8 : 0,
                    shadowColor: Color(0xFFFF6B6B).withValues(alpha: 0.3),
                  ),
                  child: AnimatedSwitcher(
                    duration: Duration(milliseconds: 200),
                    child: Text(
                      'Continue',
                      key: ValueKey(userName.isNotEmpty),
                      style: GoogleFonts.roboto(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGenderSelectionStep() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Header
            SlideTransition(
              position: Tween<Offset>(
                begin: Offset(0.0, -1.0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: _fadeController,
                curve: Curves.bounceOut,
              )),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: Color(0xFF8B4513)),
                    onPressed: _previousStep,
                  ),
                  Expanded(
                    child: Text(
                      'Almost There!',
                      style: GoogleFonts.roboto(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF8B4513),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(width: 48),
                ],
              ),
            ),
            
            SizedBox(height: 60),
            
            // Animated greeting
            ScaleTransition(
              scale: _scaleAnimation,
              child: Column(
                children: [
                  Text(
                    'Hi $userName! 👋',
                    style: GoogleFonts.roboto(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3748),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  SizedBox(height: 24),
                  
                  Text(
                    'Are you a boy or a girl?\nThis helps us customize your affirmations!',
                    style: GoogleFonts.roboto(
                      fontSize: 16,
                      color: Color(0xFF4A5568),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 60),
            
            // Animated gender selection buttons
            Row(
              children: [
                Expanded(
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: Offset(-1.0, 0.0),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: _fadeController,
                      curve: Curves.elasticOut,
                    )),
                    child: AnimatedScale(
                      scale: userGender == 'boy' ? 1.05 : 1.0,
                      duration: Duration(milliseconds: 200),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            userGender = 'boy';
                          });
                          Future.delayed(Duration(milliseconds: 300), () {
                            _nextStep();
                          });
                        },
                        child: AnimatedContainer(
                          duration: Duration(milliseconds: 300),
                          height: 120,
                          decoration: BoxDecoration(
                            color: userGender == 'boy' ? Color(0xFF4299E1) : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: userGender == 'boy' ? Color(0xFF4299E1) : Colors.grey.shade300,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: userGender == 'boy' 
                                    ? Color(0xFF4299E1).withValues(alpha: 0.3)
                                    : Colors.black.withValues(alpha: 0.1),
                                blurRadius: userGender == 'boy' ? 15 : 10,
                                offset: Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AnimatedSwitcher(
                                duration: Duration(milliseconds: 200),
                                child: Icon(
                                  Icons.boy,
                                  key: ValueKey(userGender == 'boy'),
                                  size: 48,
                                  color: userGender == 'boy' ? Colors.white : Color(0xFF4299E1),
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Boy',
                                style: GoogleFonts.roboto(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: userGender == 'boy' ? Colors.white : Color(0xFF4299E1),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                
                SizedBox(width: 20),
                
                Expanded(
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: Offset(1.0, 0.0),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: _fadeController,
                      curve: Curves.elasticOut,
                    )),
                    child: AnimatedScale(
                      scale: userGender == 'girl' ? 1.05 : 1.0,
                      duration: Duration(milliseconds: 200),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            userGender = 'girl';
                          });
                          Future.delayed(Duration(milliseconds: 300), () {
                            _nextStep();
                          });
                        },
                        child: AnimatedContainer(
                          duration: Duration(milliseconds: 300),
                          height: 120,
                          decoration: BoxDecoration(
                            color: userGender == 'girl' ? Color(0xFFED64A6) : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: userGender == 'girl' ? Color(0xFFED64A6) : Colors.grey.shade300,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: userGender == 'girl' 
                                    ? Color(0xFFED64A6).withValues(alpha: 0.3)
                                    : Colors.black.withValues(alpha: 0.1),
                                blurRadius: userGender == 'girl' ? 15 : 10,
                                offset: Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AnimatedSwitcher(
                                duration: Duration(milliseconds: 200),
                                child: Icon(
                                  Icons.girl,
                                  key: ValueKey(userGender == 'girl'),
                                  size: 48,
                                  color: userGender == 'girl' ? Colors.white : Color(0xFFED64A6),
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Girl',
                                style: GoogleFonts.roboto(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: userGender == 'girl' ? Colors.white : Color(0xFFED64A6),
                                ),
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
          ],
        ),
      ),
    );
  }

  Widget _buildAffirmationStep() {
    if (currentImageIndex == 1) {
      return _buildStartScreen();
    }
    
    return Column(
      children: [
        // Animated header
        SlideTransition(
          position: Tween<Offset>(
            begin: Offset(0.0, -1.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: _slideController,
            curve: Curves.elasticOut,
          )),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back, color: Color(0xFF8B4513)),
                  onPressed: currentImageIndex > 1 ? _previousImage : _previousStep,
                ),
                Expanded(
                  child: Text(
                    'Affirmations for $userName',
                    style: GoogleFonts.roboto(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF8B4513),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Text(
                  '$currentImageIndex/${currentImagePaths.length}',
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    color: Color(0xFF8B4513),
                  ),
                ),
                SizedBox(width: 16),
              ],
            ),
          ),
        ),
        
        // Animated progress indicator
        Container(
          margin: EdgeInsets.symmetric(horizontal: 24),
          child: AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, child) {
              return LinearProgressIndicator(
                value: (currentImageIndex / currentImagePaths.length) * _progressAnimation.value,
                backgroundColor: Colors.grey.shade300,
                valueColor: AlwaysStoppedAnimation<Color>(
                  userGender == 'boy' ? Color(0xFF4299E1) : Color(0xFFED64A6),
                ),
              );
            },
          ),
        ),
        
        // Animated image display
        Expanded(
          child: Container(
            padding: EdgeInsets.all(20),
            child: SlideTransition(
              position: _slideAnimation,
              child: FadeTransition(
                opacity: _progressAnimation,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                    CurvedAnimation(
                      parent: _progressAnimation,
                      curve: Curves.elasticOut,
                    ),
                  ),
                  child: _buildImageCard(),
                ),
              ),
            ),
          ),
        ),
        
        // Animated navigation buttons
        SlideTransition(
          position: Tween<Offset>(
            begin: Offset(0.0, 1.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: _progressAnimation,
            curve: Curves.elasticOut,
          )),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              children: [
                // Animated Previous Button
                Expanded(
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 300),
                    height: 56,
                    child: ElevatedButton(
                      onPressed: currentImageIndex > 2 ? _previousImage : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: currentImageIndex > 2 
                            ? Colors.grey.shade600 
                            : Colors.grey.shade300,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: currentImageIndex > 2 ? 8 : 0,
                        shadowColor: Colors.grey.withValues(alpha: 0.3),
                      ),
                      child: AnimatedSwitcher(
                        duration: Duration(milliseconds: 200),
                        child: Row(
                          key: ValueKey(currentImageIndex > 2),
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.arrow_back, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Previous',
                              style: GoogleFonts.roboto(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                
                SizedBox(width: 16),
                
                // Animated Next Button
                Expanded(
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 300),
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _nextImage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: userGender == 'boy' ? Color(0xFF4299E1) : Color(0xFFED64A6),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 8,
                        shadowColor: (userGender == 'boy' ? Color(0xFF4299E1) : Color(0xFFED64A6)).withValues(alpha: 0.3),
                      ),
                      child: AnimatedSwitcher(
                        duration: Duration(milliseconds: 300),
                        transitionBuilder: (Widget child, Animation<double> animation) {
                          return ScaleTransition(
                            scale: animation,
                            child: child,
                          );
                        },
                        child: Row(
                          key: ValueKey(currentImageIndex < currentImagePaths.length),
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              currentImageIndex < currentImagePaths.length ? 'Next' : 'Finish',
                              style: GoogleFonts.roboto(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(
                              currentImageIndex < currentImagePaths.length 
                                  ? Icons.arrow_forward 
                                  : Icons.check,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStartScreen() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Animated header
            SlideTransition(
              position: Tween<Offset>(
                begin: Offset(0.0, -1.0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: _fadeController,
                curve: Curves.bounceOut,
              )),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: Color(0xFF8B4513)),
                    onPressed: _previousStep,
                  ),
                  Expanded(
                    child: Text(
                      'Ready to Start?',
                      style: GoogleFonts.roboto(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF8B4513),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(width: 48),
                ],
              ),
            ),
            
            SizedBox(height: 40),
            
            // Animated image container
            Expanded(
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: (userGender == 'boy' ? Color(0xFF4299E1) : Color(0xFFED64A6)).withValues(alpha: 0.3),
                        blurRadius: 15,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.asset(
                      currentImagePaths[0],
                      fit: BoxFit.contain,
                      width: double.infinity,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey.shade200,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                                SizedBox(height: 10),
                                Text('Image not found', style: TextStyle(color: Colors.grey)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
            
            SizedBox(height: 40),
            
            // Animated start button
            SlideTransition(
              position: Tween<Offset>(
                begin: Offset(0.0, 1.0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: _fadeController,
                curve: Curves.elasticOut,
              )),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _startAffirmations,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: userGender == 'boy' ? Color(0xFF4299E1) : Color(0xFFED64A6),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 8,
                    shadowColor: (userGender == 'boy' ? Color(0xFF4299E1) : Color(0xFFED64A6)).withValues(alpha: 0.3),
                  ),
                  child: AnimatedSwitcher(
                    duration: Duration(milliseconds: 300),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.play_arrow, size: 24),
                        SizedBox(width: 8),
                        Text(
                          'Start Affirmations',
                          style: GoogleFonts.roboto(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageCard() {
    return Hero(
      tag: 'affirmation_image_$currentImageIndex',
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: (userGender == 'boy' ? Color(0xFF4299E1) : Color(0xFFED64A6)).withValues(alpha: 0.2),
              blurRadius: 15,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.asset(
            currentImagePaths[currentImageIndex - 1],
            fit: BoxFit.contain,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey.shade200,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                      SizedBox(height: 10),
                      Text('Image not found', style: TextStyle(color: Colors.grey)),
                      Text('Path: ${currentImagePaths[currentImageIndex - 1]}', 
                           style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}