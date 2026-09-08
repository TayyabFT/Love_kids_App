import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sayitnowwithselflovekids/screens/pdf_viewer_page.dart';
import 'package:sayitnowwithselflovekids/screens/video_player_page.dart';
import '../services/auth_service.dart';

class ReadBooks extends StatefulWidget {
  const ReadBooks({super.key});

  @override
  State<ReadBooks> createState() => _ReadBooksState();
}

class _ReadBooksState extends State<ReadBooks> {
  bool _isSearchVisible = false;
  final TextEditingController _searchController = TextEditingController();
  final AuthService _authService = AuthService();
  List<Map<String, dynamic>> _recentlyReadBooks = [];
  bool _isLoadingHistory = true;
  
  // Age category filtering
  bool _isFilterVisible = false;
  String? _selectedAgeCategory;
  
  // Available age categories
  final List<String> _ageCategories = [
    'Ages 3-5',
    'Ages 6-8', 
    'Ages 6-9',
    'Ages 10-12',
    'Adults',
  ];

  // Static book data - you can move this to a service later
  final List<Map<String, dynamic>> _allBooks = [
    {
      'bookId': 'book1',
      'title': 'The Redduck Family Tales: A New Life',
      'fullTitle': 'The Redduck Family Tales: A New Life',
      'imageUrl': 'assets/images/book1.jpeg',
      'pdfName': 'book1',
      'tags': ['Ages 6-8', 'Sibling Love Bonding'],
      'pages': 36,
      'description': '"The Redduck Family Tales: A New Life" is a pioneering children\'s book offering tools and strategies to assist children in overcoming anxiety, abandonment, neglect, and anger stemming from shifts in family dynamics. Additionally, it serves as a resource for parents and caregivers to overcome communication barriers that frequently emerge when new children join the household.',
      'videoUrl': 'https://www.youtube.com/watch?v=vPtYwP651PE', // Added video for duck book
    },
    {
      'bookId': 'book2', 
      'title': 'Life with Autism: Hunter\'s Story of Hope, New Friends and Fun',
      'fullTitle': 'Life with Autism: Hunter\'s Story of Hope, New Friends and Fun',
      'imageUrl': 'assets/images/book2.jpg',
      'pdfName': 'book2',
      'tags': ['Ages 6-9', 'Basic Social Skills'],
      'pages': 64,
      'description': '"Life with Autism: Hunter\'s Journey" – a compelling book revealing the remarkable experiences of a young boy named Hunter. This narrative highlights hope, friendship, and joy amidst autism challenges. Perfect for those seeking inspiration and insight.',
      'videoUrl': 'https://www.youtube.com/watch?v=0ccm1u2rVvU',
    },
    {
      'bookId': 'book3',
      'title': 'Kylie & Kyle: Siblings Living in Foster Care',
      'fullTitle': 'Kylie & Kyle: Siblings Living in Foster Care',
      'imageUrl': 'assets/images/book3.jpg',
      'pdfName': 'book3',
      'tags': ['Ages 6-9', 'Fostering Love'],
      'pages': 64,
      'description': 'The "Kylie & Kyle: Siblings Living in Foster Care" book follows the journey of two siblings navigating the challenges of foster care with strength and resilience.',
      'videoUrl': 'https://www.youtube.com/watch?v=pYf3GsZN6zc',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadReadingHistory();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadReadingHistory() async {
    setState(() {
      _isLoadingHistory = true;
    });

    try {
      final history = await _authService.getReadingHistory(limit: 5);
      setState(() {
        _recentlyReadBooks = history;
        _isLoadingHistory = false;
      });
    } catch (e) {
      print('Error loading reading history: $e');
      setState(() {
        _isLoadingHistory = false;
      });
    }
  }

  Future<void> _launchYouTubeVideo(String videoUrl, String bookTitle) async {
    try {
      // Navigate to our custom video player instead of external app
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VideoPlayerPage(
            videoUrl: videoUrl,
            videoTitle: 'Book Video: $bookTitle',
            bookTitle: bookTitle,
          ),
        ),
      );
    } catch (e) {
      print('Error opening video player: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error opening video player. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _onBookRead({
    required String bookId,
    required String title,
    required String imageUrl,
    required String pdfName,
    required List<String> tags,
  }) async {
    // Find the full title from _allBooks
    final bookDetails = _allBooks.firstWhere(
      (book) => book['bookId'] == bookId,
      orElse: () => {'fullTitle': title},
    );
    final fullTitle = bookDetails['fullTitle'] ?? title;

    // Add to reading history
    await _authService.addToReadingHistory(
      bookId: bookId,
      title: title,
      imageUrl: imageUrl,
      pdfName: pdfName,
      tags: tags,
    );

    // Navigate to PDF viewer with full title
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PdfViewerPage(
            pdfPath: "assets/books/$pdfName.pdf",
            bookTitle: fullTitle,
            bookId: bookId,
          ),
        ),
      ).then((_) {
        // Refresh reading history when returning from PDF viewer
        _loadReadingHistory();
      });
    }
  }

  void _toggleSearch() {
    setState(() {
      _isSearchVisible = !_isSearchVisible;
    });
  }

  void _toggleFilter() {
    setState(() {
      _isFilterVisible = !_isFilterVisible;
    });
  }

  void _selectAgeCategory(String? category) {
    setState(() {
      _selectedAgeCategory = category;
      _isFilterVisible = false; // Hide filter after selection
    });
  }

  List<Map<String, dynamic>> _getFilteredBooks() {
    if (_selectedAgeCategory == null) {
      return _allBooks; // Return all books if no filter selected
    }
    
    return _allBooks.where((book) {
      final tags = List<String>.from(book['tags'] ?? []);
      return tags.any((tag) => tag.contains(_selectedAgeCategory!));
    }).toList();
  }

  void _showBookDetailsBottomSheet(
    BuildContext context,
    String bookId,
    String imageUrl,
    String title,
    List<String> tags,
    String pdfName,
    String description,
    int pages,
    String? videoUrl,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.8,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          builder: (BuildContext context, ScrollController scrollController) {
            return Container(
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
                  // Bottom sheet handle bar
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 10),
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),

                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(20),
                      children: [
                        // Book Image
                        Center(
                          child: Container(
                            height: 200,
                            width: 160,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  spreadRadius: 1,
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.asset(
                                imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey.shade300,
                                    child: const Icon(
                                      Icons.image_not_supported,
                                      color: Colors.grey,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Book Title
                        Center(
                          child: Text(
                            title,
                            style: GoogleFonts.roboto(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2D3748),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Tags
                        Center(
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 8,
                            runSpacing: 8,
                            children: tags.map((tag) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Text(
                                      tag,
                                  style: GoogleFonts.roboto(
                                        fontSize: 12,
                                        color: Colors.grey.shade800,
                                      ),
                                    ),
                                  );
                                }).toList(),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Description
                        Text(
                          'Book Description',
                          style: GoogleFonts.roboto(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D3748),
                          ),
                        ),

                        const SizedBox(height: 12),

                        Text(
                          description,
                          style: GoogleFonts.roboto(
                            fontSize: 14,
                            color: Colors.grey.shade800,
                            height: 1.5,
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Book Details
                        Text(
                          'Book Details',
                          style: GoogleFonts.roboto(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D3748),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Details List
                        _buildDetailRow('Author', 'Gloria J. Warren'),
                        _buildDetailRow('Publisher', 'Say It Now Self-Love Kids LLC'),
                        _buildDetailRow('Publication Date', 'January 2023'),
                        _buildDetailRow('Pages', pages.toString()),
                        _buildDetailRow('Language', 'English'),

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),

                  // Action Buttons (Read Now and Watch Video)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, -5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Read Now Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context); // Close bottom sheet
                              _onBookRead(
                                bookId: bookId,
                                title: title,
                                imageUrl: imageUrl,
                                pdfName: pdfName,
                                tags: tags,
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Read Now',
                              style: GoogleFonts.roboto(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        
                        // Watch Video Button (conditional)
                        if (videoUrl != null && videoUrl.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(context); // Close bottom sheet
                                _launchYouTubeVideo(videoUrl, title);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(Icons.play_arrow),
                              label: Text(
                                bookId == 'book1' ? 'Kyle Lemon Happy Birthday' : 'Watch Video',
                                style: GoogleFonts.roboto(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: GoogleFonts.roboto(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3748),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.roboto(
              fontSize: 14, 
              color: Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8E8D0),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFFF9A826),
                    Color(0xFFFF8C00),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade200, width: 1),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                  Text(
                    'Read Books',
                    style: GoogleFonts.roboto(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.search, color: Colors.white),
                        onPressed: _toggleSearch,
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.filter_list, 
                          color: _selectedAgeCategory != null ? Colors.amber : Colors.white,
                        ),
                        onPressed: _toggleFilter,
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.refresh,
                          color: Colors.white,
                        ),
                        onPressed: _loadReadingHistory,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Main Content
            Expanded(
              child: CustomScrollView(
                slivers: [
                  // Search Bar
                  SliverToBoxAdapter(
                    child: Visibility(
                      visible: _isSearchVisible,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: TextFormField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search for books...',
                            hintStyle: GoogleFonts.roboto(),
                            prefixIcon: const Icon(
                              Icons.search,
                              color: Colors.grey,
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: const Color(0xFFFF6B6B).withValues(alpha: 0.2),
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Age Category Filter
                  SliverToBoxAdapter(
                    child: Visibility(
                      visible: _isFilterVisible,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Age Categories',
                                  style: GoogleFonts.roboto(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2D3748),
                                  ),
                                ),
                                if (_selectedAgeCategory != null)
                                  TextButton(
                                    onPressed: () => _selectAgeCategory(null),
                                    child: Text(
                                      'Clear Filter',
                                      style: GoogleFonts.roboto(
                                        fontSize: 14,
                                        color: Color(0xFFFF6B6B),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _ageCategories.map((category) {
                                final isSelected = _selectedAgeCategory == category;
                                return InkWell(
                                  onTap: () => _selectAgeCategory(category),
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected 
                                          ? Color(0xFFF9A826) 
                                          : Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: isSelected 
                                            ? Color(0xFFF9A826) 
                                            : Colors.grey.shade300,
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      category,
                                      style: GoogleFonts.roboto(
                                        fontSize: 14,
                                        fontWeight: isSelected 
                                            ? FontWeight.bold 
                                            : FontWeight.normal,
                                        color: isSelected 
                                            ? Colors.white 
                                            : Color(0xFF2D3748),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            if (_selectedAgeCategory != null) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Color(0xFFF9A826).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.filter_list,
                                      size: 16,
                                      color: Color(0xFFF9A826),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Showing books for $_selectedAgeCategory',
                                      style: GoogleFonts.roboto(
                                        fontSize: 12,
                                        color: Color(0xFFF9A826),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Recently Read Section
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Recently Read',
                            style: GoogleFonts.roboto(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2D3748),
                            ),
                          ),
                          if (_recentlyReadBooks.isNotEmpty)
                          TextButton(
                              onPressed: () {
                                // TODO: Navigate to full reading history
                              },
                              child: Text(
                              'See All',
                                style: GoogleFonts.roboto(
                                fontSize: 14,
                                color: Color(0xFFFF6B6B),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Recently Read Books
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: _recentlyReadBooks.isEmpty ? 120 : 270,
                      child: _isLoadingHistory
                          ? Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFF8B4513),
                              ),
                            )
                          : _recentlyReadBooks.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.book_outlined,
                                        size: 48,
                                        color: Colors.grey.shade400,
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'No books read yet',
                                        style: GoogleFonts.roboto(
                                          fontSize: 16,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      Text(
                                        'Start reading to see your history here',
                                        style: GoogleFonts.roboto(
                                          fontSize: 14,
                                          color: Colors.grey.shade500,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        scrollDirection: Axis.horizontal,
                                  itemCount: _recentlyReadBooks.length,
                                  itemBuilder: (context, index) {
                                    final book = _recentlyReadBooks[index];
                                    return Container(
                                      margin: EdgeInsets.only(
                                        right: index < _recentlyReadBooks.length - 1 ? 16 : 0,
                                      ),
                                      child: GestureDetector(
                                        onTap: () {
                                          // Find the description from _allBooks based on bookId
                                          final bookDetails = _allBooks.firstWhere(
                                            (b) => b['bookId'] == book['bookId'],
                                            orElse: () => {'description': 'No description available.', 'pages': 120},
                                          );
                                          _showBookDetailsBottomSheet(
                                            context,
                                            book['bookId'] ?? '',
                                            book['imageUrl'] ?? '',
                                            book['title'] ?? '',
                                            List<String>.from(book['tags'] ?? []),
                                            book['pdfName'] ?? '',
                                            bookDetails['description'] ?? 'No description available.',
                                            bookDetails['pages'] ?? 120,
                                            bookDetails['videoUrl'],
                                          );
                                        },
                                        child: RecentBookCard(
                                          imageUrl: book['imageUrl'] ?? '',
                                          title: book['title'] ?? '',
                                          lastRead: book['lastRead'] ?? '',
                          ),
                                      ),
                                    );
                                  },
                      ),
                    ),
                  ),

                  // All Books Section
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(
                        left: 16,
                        right: 16,
                        top: 24,
                        bottom: 16,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _selectedAgeCategory != null 
                                ? 'Books for $_selectedAgeCategory'
                                : 'All Books',
                            style: GoogleFonts.roboto(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2D3748),
                            ),
                          ),
                          if (_selectedAgeCategory != null)
                            Text(
                              '${_getFilteredBooks().length} book${_getFilteredBooks().length != 1 ? 's' : ''}',
                              style: GoogleFonts.roboto(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  // All Books Grid or Empty State
                  _getFilteredBooks().isEmpty
                      ? SliverToBoxAdapter(
                          child: SizedBox(
                            height: 200,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.search_off,
                                    size: 48,
                                    color: Colors.grey.shade400,
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'No books found',
                                    style: GoogleFonts.roboto(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'No books available for $_selectedAgeCategory',
                                    style: GoogleFonts.roboto(
                                      fontSize: 14,
                                      color: Colors.grey.shade500,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: () => _selectAgeCategory(null),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Color(0xFFF9A826),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: Text(
                                      'Show All Books',
                                      style: GoogleFonts.roboto(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      : SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          sliver: SliverGrid(
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: _getResponsiveCrossAxisCount(context),
                              childAspectRatio: _getResponsiveChildAspectRatio(context),
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final filteredBooks = _getFilteredBooks();
                                final book = filteredBooks[index];
                                return BookCard(
                                  imageUrl: book['imageUrl']!,
                                  title: book['title']!,
                                  tags: List<String>.from(book['tags']!),
                                  pdfName: book['pdfName']!,
                                  onReadNowPressed: (context, imageUrl, title, tags, pdfName) =>
                                        _showBookDetailsBottomSheet(
                                          context,
                                    book['bookId']!,
                                          imageUrl,
                                          title,
                                          tags,
                                          pdfName,
                                          book['description']!,
                                          book['pages']!,
                                          book['videoUrl'],
                                        ),
                                );
                              },
                              childCount: _getFilteredBooks().length,
                                        ),
                          ),
                        ),

                  // Bottom spacing
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to get responsive cross axis count
  int _getResponsiveCrossAxisCount(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth >= 1200) {
      return 4; // Large tablets and desktops
    } else if (screenWidth >= 800) {
      return 3; // Tablets
    } else if (screenWidth >= 600) {
      return 2; // Large phones
    } else {
      return 2; // Small phones
    }
  }

  // Helper method to get responsive child aspect ratio
  double _getResponsiveChildAspectRatio(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth >= 1200) {
      return 0.73;
    } else if (screenWidth >= 800) {
      return 0.68;
    } else {
      return 0.63;
    }
  }
}

class RecentBookCard extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String lastRead;

  const RecentBookCard({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.lastRead,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Image.asset(
                  imageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: 176,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: double.infinity,
                      height: 176,
                      color: Colors.grey.shade300,
                      child: const Icon(
                        Icons.image_not_supported,
                        color: Colors.grey,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 0, 0),
                child: Text(
                  title,
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF2D3748),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 2),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 0, 10),
                child: Text(
                  lastRead,
                  style: GoogleFonts.roboto(
                    fontSize: 12, 
                    color: Colors.grey.shade600,
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

class BookCard extends StatelessWidget {
  final String imageUrl;
  final String title;
  final List<String> tags;
  final String pdfName;
  final Function(BuildContext, String, String, List<String>, String) onReadNowPressed;

  const BookCard({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.tags,
    required this.onReadNowPressed,
    required this.pdfName,
  });

  // Helper method to get responsive font size
  double _getResponsiveFontSize(BuildContext context, double baseSize) {
    double screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth >= 1200) {
      return baseSize * 1.3; // Larger fonts for big screens
    } else if (screenWidth >= 800) {
      return baseSize * 1.1; // Medium fonts for tablets
    } else {
      return baseSize; // Original size for phones
    }
  }

  // Helper method to get responsive padding
  double _getResponsivePadding(BuildContext context, double basePadding) {
    double screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth >= 1200) {
      return basePadding * 1.5; // Larger padding for big screens
    } else if (screenWidth >= 800) {
      return basePadding * 1.2; // Medium padding for tablets
    } else {
      return basePadding; // Original padding for phones
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Book cover image
            AspectRatio(
              aspectRatio: 1,
              child: Image.asset(
                imageUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey.shade300,
                    child: const Icon(
                      Icons.image_not_supported,
                      color: Colors.grey,
                    ),
                  );
                },
              ),
            ),

            // Book details - minimal layout
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title
                    Text(
                      title,
                      style: GoogleFonts.roboto(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF2D3748),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Tags - minimal
                    Wrap(
                      spacing: 2,
                      runSpacing: 2,
                      children: tags.map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            tag,
                            style: GoogleFonts.roboto(
                              fontSize: 8,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),

            // Read Button at the bottom
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 4),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    onReadNowPressed(context, imageUrl, title, tags, pdfName);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: Text(
                    'Read Now',
                    style: GoogleFonts.roboto(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
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
}

