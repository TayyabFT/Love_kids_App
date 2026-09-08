import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'quiz_screen.dart';

class PdfViewerPage extends StatefulWidget {
  final String pdfPath;
  final String? bookTitle;
  final String? bookId; // Add bookId for quiz functionality

  const PdfViewerPage({
    super.key, 
    required this.pdfPath,
    this.bookTitle,
    this.bookId,
  });

  @override
  State<PdfViewerPage> createState() => _PdfViewerPageState();
}

class _PdfViewerPageState extends State<PdfViewerPage> {
  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();
  late PdfViewerController _pdfViewerController;
  
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  
  // Reading features
  bool _isNightMode = false;
  bool _showControls = true;
  double _zoomLevel = 1.0;
  int _currentPage = 1;
  int _totalPages = 0;
  
  // Reading progress tracking
  final Set<int> _visitedPages = {};
  double _readingProgress = 0.0;
  bool _hasTriggeredQuizPrompt = false;
  
  // Search functionality
  bool _isSearchVisible = false;
  final TextEditingController _searchController = TextEditingController();
  PdfTextSearchResult? _searchResult;

  @override
  void initState() {
    super.initState();
    _pdfViewerController = PdfViewerController();
    _checkPdfFile();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _pdfViewerController.dispose();
    super.dispose();
  }

  Future<void> _checkPdfFile() async {
    try {
      // Check if the PDF file exists
      await rootBundle.load(widget.pdfPath);
      setState(() {
        _isLoading = false;
        _hasError = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Failed to load PDF: ${e.toString()}';
      });
    }
  }

  void _updateReadingProgress() {
    if (_totalPages > 0) {
      _visitedPages.add(_currentPage);
      final progress = (_visitedPages.length / _totalPages) * 100;
      
      // Debug logging
      print('📖 Reading Progress Update:');
      print('   Current Page: $_currentPage');
      print('   Total Pages: $_totalPages');
      print('   Visited Pages: ${_visitedPages.length}');
      print('   Progress: ${progress.toStringAsFixed(1)}%');
      print('   BookId: ${widget.bookId}');
      print('   Quiz Triggered: $_hasTriggeredQuizPrompt');
      
      setState(() {
        _readingProgress = progress;
      });
      
      // Show quiz prompt immediately when user reaches 80% and hasn't been prompted yet
      if (progress >= 80.0 && !_hasTriggeredQuizPrompt && widget.bookId != null) {
        print('🎯 80% REACHED! Showing quiz prompt...');
        _hasTriggeredQuizPrompt = true;
        // Show the quiz prompt immediately
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _showQuizPromptImmediate();
          }
        });
      }
    }
  }

  Future<bool> _onWillPop() async {
    // Use the same logic as the app bar back button
    if (_readingProgress >= 80.0 && widget.bookId != null && !_hasTriggeredQuizPrompt) {
      _hasTriggeredQuizPrompt = true;
      return await _showQuizPrompt();
    }
    
    return true; // Allow normal back navigation
  }

  Future<bool> _showQuizPrompt() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Icons.quiz, color: Color(0xFF8B4513), size: 28),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Great Reading!',
                  style: GoogleFonts.roboto(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3748),
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFF9A826).withValues(alpha: 0.1), Color(0xFFFF8C00).withValues(alpha: 0.1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Icon(Icons.auto_stories, size: 48, color: Color(0xFF8B4513)),
                    SizedBox(height: 12),
                    Text(
                      'Congratulations! 🎉',
                      style: GoogleFonts.roboto(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'You\'ve read ${_readingProgress.toInt()}% of this book!',
                      style: GoogleFonts.roboto(
                        fontSize: 16,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Would you like to test your understanding with a fun quiz? It\'s a great way to remember what you\'ve learned!',
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(true), // Exit without quiz
              child: Text(
                'Maybe Later',
                style: GoogleFonts.roboto(color: Colors.grey[600]),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop(false); // Don't exit, go to quiz
                _navigateToQuiz();
              },
              icon: Icon(Icons.quiz, size: 18),
              label: Text('Take Quiz!', style: GoogleFonts.roboto()),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF8B4513),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        );
      },
    );
    
    return result ?? true; // If dialog is dismissed, allow exit
  }

  // Show quiz prompt immediately when 80% is reached
  Future<void> _showQuizPromptImmediate() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Icons.quiz, color: Color(0xFF8B4513), size: 28),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Great Reading!',
                  style: GoogleFonts.roboto(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3748),
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFF9A826).withValues(alpha: 0.1), Color(0xFFFF8C00).withValues(alpha: 0.1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Icon(Icons.auto_stories, size: 48, color: Color(0xFF8B4513)),
                    SizedBox(height: 12),
                    Text(
                      'Congratulations! 🎉',
                      style: GoogleFonts.roboto(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'You\'ve read ${_readingProgress.toInt()}% of this book!',
                      style: GoogleFonts.roboto(
                        fontSize: 16,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Would you like to test your understanding with a fun quiz? It\'s a great way to remember what you\'ve learned!',
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Just close dialog, continue reading
              },
              child: Text(
                'Continue Reading',
                style: GoogleFonts.roboto(color: Colors.grey[600]),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                _navigateToQuiz(); // Go to quiz
              },
              icon: Icon(Icons.quiz, size: 18),
              label: Text('Take Quiz Now!', style: GoogleFonts.roboto()),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF8B4513),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _navigateToQuiz() {
    if (widget.bookId != null && widget.bookTitle != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => QuizScreen(
            bookId: widget.bookId!,
            bookTitle: widget.bookTitle!,
          ),
        ),
      );
    }
  }

  void _toggleNightMode() {
    setState(() {
      _isNightMode = !_isNightMode;
    });
  }

  void _toggleControlsVisibility() {
    setState(() {
      _showControls = !_showControls;
    });
  }

  void _zoomIn() {
    _pdfViewerController.zoomLevel = (_zoomLevel * 1.25).clamp(0.5, 3.0);
  }

  void _zoomOut() {
    _pdfViewerController.zoomLevel = (_zoomLevel * 0.8).clamp(0.5, 3.0);
  }

  void _resetZoom() {
    _pdfViewerController.zoomLevel = 1.0;
  }

  void _goToPage(int page) {
    if (page >= 1 && page <= _totalPages) {
      _pdfViewerController.jumpToPage(page);
    }
  }

  void _nextPage() {
    if (_currentPage < _totalPages) {
      _pdfViewerController.nextPage();
    }
  }

  void _previousPage() {
    if (_currentPage > 1) {
      _pdfViewerController.previousPage();
    }
  }

  void _showPageNavigator() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        int targetPage = _currentPage;
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Go to Page', style: GoogleFonts.roboto(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Current: $_currentPage / $_totalPages', style: GoogleFonts.roboto()),
              const SizedBox(height: 16),
              TextField(
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Page Number',
                  labelStyle: GoogleFonts.roboto(),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  hintText: 'Enter page number (1-$_totalPages)',
                  hintStyle: GoogleFonts.roboto(),
                ),
                onChanged: (value) {
                  targetPage = int.tryParse(value) ?? _currentPage;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: GoogleFonts.roboto()),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _goToPage(targetPage);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF8B4513),
                foregroundColor: Colors.white,
              ),
              child: Text('Go', style: GoogleFonts.roboto()),
            ),
          ],
        );
      },
    );
  }

  void _toggleSearch() {
    setState(() {
      _isSearchVisible = !_isSearchVisible;
      if (!_isSearchVisible) {
        _searchController.clear();
        _searchResult?.clear();
      }
    });
  }

  void _searchText(String query) {
    if (query.isNotEmpty) {
      _searchResult = _pdfViewerController.searchText(query);
      if (_searchResult != null) {
        setState(() {});
      }
    }
  }

  void _searchNext() {
    _searchResult?.nextInstance();
  }

  void _searchPrevious() {
    _searchResult?.previousInstance();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: _isNightMode ? Colors.black : Color(0xFFF8E8D0),
        appBar: _showControls ? _buildAppBar() : null,
        body: Stack(
          children: [
            // Main PDF Viewer
            if (_isLoading)
              _buildLoadingState()
            else if (_hasError)
              _buildErrorState()
            else
              _buildPdfViewer(),

            // Reading Progress Indicator
            if (_totalPages > 0 && _showControls) _buildProgressIndicator(),

            // Search Bar
            if (_isSearchVisible) _buildSearchBar(),

            // Floating Action Buttons
            if (_showControls && !_isLoading && !_hasError) _buildFloatingControls(),

            // Page Navigation Controls
            if (_showControls && !_isLoading && !_hasError) _buildPageControls(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _isNightMode ? Colors.grey[900] : Color(0xFFF9A826),
      foregroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back),
        onPressed: _handleBackPress, // Use custom back handler
      ),
      title: Text(
        widget.bookTitle ?? 'Read Book',
        style: GoogleFonts.roboto(
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: [
        if (widget.bookId != null)
          IconButton(
            icon: Icon(Icons.quiz),
            onPressed: _navigateToQuiz,
            tooltip: 'Take Quiz',
          ),
        IconButton(
          icon: Icon(_isNightMode ? Icons.light_mode : Icons.dark_mode),
          onPressed: _toggleNightMode,
        ),
        IconButton(
          icon: Icon(Icons.search),
          onPressed: _toggleSearch,
        ),
        PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'zoom_in':
                _zoomIn();
                break;
              case 'zoom_out':
                _zoomOut();
                break;
              case 'reset_zoom':
                _resetZoom();
                break;
              case 'goto_page':
                _showPageNavigator();
                break;
              case 'toggle_controls':
                _toggleControlsVisibility();
                break;
              case 'take_quiz':
                _navigateToQuiz();
                break;
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'zoom_in',
              child: Row(
                children: [
                  Icon(Icons.zoom_in),
                  SizedBox(width: 8),
                  Text('Zoom In', style: GoogleFonts.roboto()),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'zoom_out',
              child: Row(
                children: [
                  Icon(Icons.zoom_out),
                  SizedBox(width: 8),
                  Text('Zoom Out', style: GoogleFonts.roboto()),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'reset_zoom',
              child: Row(
                children: [
                  Icon(Icons.center_focus_strong),
                  SizedBox(width: 8),
                  Text('Reset Zoom', style: GoogleFonts.roboto()),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'goto_page',
              child: Row(
                children: [
                  Icon(Icons.navigate_next),
                  SizedBox(width: 8),
                  Text('Go to Page', style: GoogleFonts.roboto()),
                ],
              ),
            ),
            if (widget.bookId != null)
              PopupMenuItem(
                value: 'take_quiz',
                child: Row(
                  children: [
                    Icon(Icons.quiz),
                    SizedBox(width: 8),
                    Text('Take Quiz', style: GoogleFonts.roboto()),
                  ],
                ),
              ),
            PopupMenuItem(
              value: 'toggle_controls',
              child: Row(
                children: [
                  Icon(Icons.visibility_off),
                  SizedBox(width: 8),
                  Text('Hide Controls', style: GoogleFonts.roboto()),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProgressIndicator() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SizedBox(
        height: 4,
        child: LinearProgressIndicator(
          value: _readingProgress / 100,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(
            _readingProgress >= 80 ? Colors.green : Color(0xFF8B4513),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: Color(0xFF8B4513),
            strokeWidth: 3,
          ),
          const SizedBox(height: 24),
          Text(
            'Loading your book...',
            style: GoogleFonts.roboto(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: _isNightMode ? Colors.white : Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please wait while we prepare your reading experience',
            style: GoogleFonts.roboto(
              fontSize: 14,
              color: _isNightMode ? Colors.grey[300] : Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[400],
            ),
            const SizedBox(height: 24),
            Text(
              'Oops! Something went wrong',
              style: GoogleFonts.roboto(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _isNightMode ? Colors.white : Color(0xFF2D3748),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage,
              style: GoogleFonts.roboto(
                fontSize: 14,
                color: _isNightMode ? Colors.grey[300] : Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _isLoading = true;
                      _hasError = false;
                    });
                    _checkPdfFile();
                  },
                  icon: Icon(Icons.refresh),
                  label: Text('Retry', style: GoogleFonts.roboto()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF8B4513),
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.arrow_back),
                  label: Text('Go Back', style: GoogleFonts.roboto()),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Color(0xFF8B4513),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPdfViewer() {
    return GestureDetector(
      onTap: _toggleControlsVisibility,
      child: Container(
        color: _isNightMode ? Colors.black : Colors.white,
        child: SfPdfViewer.asset(
          widget.pdfPath,
          key: _pdfViewerKey,
          controller: _pdfViewerController,
          enableDoubleTapZooming: true,
          enableTextSelection: true,
          canShowScrollHead: true,
          canShowScrollStatus: true,
          canShowPaginationDialog: true,
          interactionMode: PdfInteractionMode.selection,
          onDocumentLoaded: (PdfDocumentLoadedDetails details) {
            setState(() {
              _totalPages = details.document.pages.count;
            });
          },
          onPageChanged: (PdfPageChangedDetails details) {
            setState(() {
              _currentPage = details.newPageNumber;
            });
            _updateReadingProgress();
          },
          onZoomLevelChanged: (PdfZoomDetails details) {
            setState(() {
              _zoomLevel = details.newZoomLevel;
            });
          },
          onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
            setState(() {
              _hasError = true;
              _errorMessage = 'Failed to load PDF: ${details.error}';
            });
          },
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        color: (_isNightMode ? Colors.grey[900] : Colors.white)?.withValues(alpha: 0.95),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search in book...',
                  hintStyle: GoogleFonts.roboto(),
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                onSubmitted: _searchText,
                onChanged: (value) {
                  if (value.isEmpty) {
                    _searchResult?.clear();
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () => _searchText(_searchController.text),
              icon: Icon(Icons.search),
            ),
            if (_searchResult != null && _searchResult!.totalInstanceCount > 0) ...[
              IconButton(
                onPressed: _searchPrevious,
                icon: Icon(Icons.keyboard_arrow_up),
              ),
              IconButton(
                onPressed: _searchNext,
                icon: Icon(Icons.keyboard_arrow_down),
              ),
            ],
            IconButton(
              onPressed: _toggleSearch,
              icon: Icon(Icons.close),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingControls() {
    return Positioned(
      right: 16,
      top: MediaQuery.of(context).size.height * 0.3,
      child: Column(
        children: [
          FloatingActionButton.small(
            heroTag: "zoom_in",
            onPressed: _zoomIn,
            backgroundColor: _isNightMode ? Colors.grey[800] : Color(0xFF8B4513),
            child: Icon(Icons.zoom_in, color: Colors.white),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.small(
            heroTag: "zoom_out",
            onPressed: _zoomOut,
            backgroundColor: _isNightMode ? Colors.grey[800] : Color(0xFF8B4513),
            child: Icon(Icons.zoom_out, color: Colors.white),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.small(
            heroTag: "reset_zoom",
            onPressed: _resetZoom,
            backgroundColor: _isNightMode ? Colors.grey[800] : Color(0xFF8B4513),
            child: Icon(Icons.center_focus_strong, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildPageControls() {
    return Positioned(
      bottom: 16,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: (_isNightMode ? Colors.grey[900] : Colors.white)?.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: _isNightMode ? Colors.grey[700]! : Colors.grey[300]!,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: _currentPage > 1 ? _previousPage : null,
              icon: Icon(
                Icons.chevron_left,
                color: _currentPage > 1 
                    ? (_isNightMode ? Colors.white : Color(0xFF8B4513))
                    : Colors.grey,
              ),
            ),
            GestureDetector(
              onTap: _showPageNavigator,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _isNightMode ? Colors.grey[800] : Color(0xFF8B4513).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$_currentPage / $_totalPages',
                      style: GoogleFonts.roboto(
                        fontWeight: FontWeight.w600,
                        color: _isNightMode ? Colors.white : Color(0xFF8B4513),
                      ),
                    ),
                    if (_readingProgress > 0)
                      Text(
                        '${_readingProgress.toInt()}% read',
                        style: GoogleFonts.roboto(
                          fontSize: 10,
                          color: _readingProgress >= 80 
                              ? Colors.green 
                              : (_isNightMode ? Colors.grey[400] : Colors.grey[600]),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            IconButton(
              onPressed: _currentPage < _totalPages ? _nextPage : null,
              icon: Icon(
                Icons.chevron_right,
                color: _currentPage < _totalPages 
                    ? (_isNightMode ? Colors.white : Color(0xFF8B4513))
                    : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Handle back button press (both app bar and device back button)
  Future<void> _handleBackPress() async {
    // If user has read 80% of the book and we have a bookId, show quiz prompt
    if (_readingProgress >= 80.0 && widget.bookId != null && !_hasTriggeredQuizPrompt) {
      _hasTriggeredQuizPrompt = true;
      final shouldExit = await _showQuizPrompt();
      if (shouldExit) {
        Navigator.pop(context);
      }
    } else {
      // Normal back navigation
      Navigator.pop(context);
    }
  }
}
