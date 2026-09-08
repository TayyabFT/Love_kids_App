import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

class VideoPlayerPage extends StatefulWidget {
  final String videoUrl;
  final String videoTitle;
  final String bookTitle;

  const VideoPlayerPage({
    super.key,
    required this.videoUrl,
    required this.videoTitle,
    required this.bookTitle,
  });

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  late YoutubePlayerController _controller;
  bool _isFullScreen = false;
  bool _wasPlaying = false;
  
  Widget get _videoPlayer => YoutubePlayer(
    controller: _controller,
    showVideoProgressIndicator: true,
    progressIndicatorColor: Colors.red,
    onReady: () {
      print('🎵 YouTube Player Ready - Audio enabled');
    },
    onEnded: (data) {
      print('🎵 Video ended');
    },
  );

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  void _initializePlayer() {
    final videoId = YoutubePlayer.convertUrlToId(widget.videoUrl);
    if (videoId != null) {
      _controller = YoutubePlayerController(
        initialVideoId: videoId,
        flags: const YoutubePlayerFlags(
          mute: false,
          autoPlay: false,
          disableDragSeek: false,
          loop: false,
          isLive: false,
          forceHD: false,
          enableCaption: true,
          hideControls: false,
          controlsVisibleAtStart: true,
          useHybridComposition: true,
        ),
      );
      
      // Add listener to track state changes
      _controller.addListener(() {
        if (mounted) {
          setState(() {});
        }
      });
    }
  }

  @override
  void dispose() {
    // Restore system UI and orientation when leaving
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: SystemUiOverlay.values);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    
    // Properly dispose the controller
    try {
      _controller.pause();
      _controller.dispose();
    } catch (e) {
      print('Error disposing controller: $e');
    }
    
    super.dispose();
  }

  void _toggleFullScreen() {
    // Save current playing state
    _wasPlaying = _controller.value.isPlaying;
    
    setState(() {
      _isFullScreen = !_isFullScreen;
    });

    if (_isFullScreen) {
      // Enter fullscreen - hide all system UI
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      // Exit fullscreen - restore system UI
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
          overlays: SystemUiOverlay.values);
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
    }

    // Restore playing state after a brief delay
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_wasPlaying && mounted) {
        _controller.play();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isFullScreen) {
      return _buildFullScreenPlayer();
    }
    
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          widget.videoTitle,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.fullscreen),
            onPressed: _toggleFullScreen,
          ),
        ],
      ),
      body: SafeArea(
        child: _buildNormalPlayer(),
      ),
    );
  }

    Widget _buildFullScreenPlayer() {
    return PopScope(
      canPop: !_isFullScreen,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _isFullScreen) {
          _toggleFullScreen();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: Stack(
            children: [
              // Video player taking full screen space
              Center(
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: _videoPlayer,
                ),
              ),
              // Control overlay
              Positioned.fill(
                child: GestureDetector(
                  onTap: () {
                    // Toggle controls visibility
                  },
                  child: Container(
                    color: Colors.transparent,
                  ),
                ),
              ),
              // Top control bar
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.7),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Back button
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
                          onPressed: () {
                            _toggleFullScreen();
                          },
                        ),
                      ),
                      // Exit fullscreen button
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.fullscreen_exit, color: Colors.white, size: 24),
                          onPressed: _toggleFullScreen,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Bottom control bar
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.7),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildFullScreenControlButton(
                        icon: Icons.replay_10,
                        onPressed: () {
                          final currentPosition = _controller.value.position.inSeconds;
                          _controller.seekTo(Duration(seconds: currentPosition - 10));
                        },
                      ),
                                             _buildFullScreenControlButton(
                         icon: _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                         onPressed: () {
                           try {
                             if (_controller.value.isPlaying) {
                               _controller.pause();
                               print('🎵 Video paused');
                             } else {
                               _controller.play();
                               print('🎵 Video playing with audio');
                             }
                             if (mounted) {
                               setState(() {});
                             }
                           } catch (e) {
                             print('Error controlling playback: $e');
                           }
                         },
                       ),
                      _buildFullScreenControlButton(
                        icon: Icons.forward_10,
                        onPressed: () {
                          final currentPosition = _controller.value.position.inSeconds;
                          _controller.seekTo(Duration(seconds: currentPosition + 10));
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNormalPlayer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
                // Video Player
        SizedBox(
          width: double.infinity,
          height: 220,
          child: _videoPlayer,
        ),
        
        // Video Controls
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.grey[900],
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildControlButton(
                icon: Icons.replay_10,
                label: 'Replay 10s',
                onPressed: () {
                  final currentPosition = _controller.value.position.inSeconds;
                  _controller.seekTo(Duration(seconds: currentPosition - 10));
                },
              ),
              _buildControlButton(
                icon: _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                label: _controller.value.isPlaying ? 'Pause' : 'Play',
                onPressed: () {
                  if (_controller.value.isPlaying) {
                    _controller.pause();
                  } else {
                    _controller.play();
                  }
                  setState(() {});
                },
              ),
              _buildControlButton(
                icon: Icons.forward_10,
                label: 'Forward 10s',
                onPressed: () {
                  final currentPosition = _controller.value.position.inSeconds;
                  _controller.seekTo(Duration(seconds: currentPosition + 10));
                },
              ),
              _buildControlButton(
                icon: Icons.fullscreen,
                label: 'Fullscreen',
                onPressed: _toggleFullScreen,
              ),
            ],
          ),
        ),
        
        // Video Info
        Expanded(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.videoTitle,
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'From: ${widget.bookTitle}',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue[600]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'This video is related to the book "${widget.bookTitle}". Watch and learn more about the story!',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.blue[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _buildFeaturesList(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(icon, color: Colors.white, size: 28),
          onPressed: onPressed,
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildFullScreenControlButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(25),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 32),
        onPressed: onPressed,
        iconSize: 32,
        padding: const EdgeInsets.all(12),
      ),
    );
  }

  Widget _buildFeaturesList() {
    final features = [
      {'icon': Icons.play_circle_outline, 'text': 'High quality video playback'},
      {'icon': Icons.fullscreen, 'text': 'Full screen mode available'},
      {'icon': Icons.replay_10, 'text': 'Skip forward/backward 10 seconds'},
      {'icon': Icons.closed_caption, 'text': 'Captions available when provided'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Video Features:',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
                 ...features.map((feature) => Padding(
           padding: const EdgeInsets.symmetric(vertical: 4),
           child: Row(
             children: [
               Icon(
                 feature['icon'] as IconData,
                 size: 20,
                 color: Colors.green[600],
               ),
               const SizedBox(width: 12),
               Text(
                 feature['text'] as String,
                 style: GoogleFonts.poppins(
                   fontSize: 14,
                   color: Colors.grey[700],
                 ),
               ),
             ],
           ),
         )),
      ],
    );
  }
} 