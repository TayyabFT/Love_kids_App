import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/quiz_service.dart';
import 'quiz_screen.dart';

class QuizResultsScreen extends StatefulWidget {
  final String bookId;
  final String bookTitle;
  final List<QuizAnswer> answers;

  const QuizResultsScreen({
    super.key,
    required this.bookId,
    required this.bookTitle,
    required this.answers,
  });

  @override
  State<QuizResultsScreen> createState() => _QuizResultsScreenState();
}

class _QuizResultsScreenState extends State<QuizResultsScreen> 
    with TickerProviderStateMixin {
  final QuizService _quizService = QuizService();
  late QuizAnalytics _analytics;
  bool _isSaving = false;
  
  late AnimationController _scoreController;
  late AnimationController _confettiController;
  late Animation<double> _scoreAnimation;

  @override
  void initState() {
    super.initState();
    _analytics = _quizService.calculateAnalytics(widget.answers);
    
    _scoreController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _confettiController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );
    
    _scoreAnimation = Tween<double>(begin: 0.0, end: _analytics.scorePercentage)
        .animate(CurvedAnimation(parent: _scoreController, curve: Curves.easeOutCubic));
    
    _saveResults();
    _startAnimations();
  }

  @override
  void dispose() {
    _scoreController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  void _startAnimations() {
    Future.delayed(const Duration(milliseconds: 500), () {
      _scoreController.forward();
      if (_analytics.scorePercentage >= 80) {
        _confettiController.forward();
      }
    });
  }

  void _saveResults() async {
    setState(() {
      _isSaving = true;
    });

    try {
      await _quizService.saveQuizResult(
        bookId: widget.bookId,
        answers: widget.answers,
        scorePercentage: _analytics.scorePercentage,
      );
    } catch (e) {
      print('Error saving quiz results: $e');
    }

    setState(() {
      _isSaving = false;
    });
  }

  Color get _performanceColor {
    if (_analytics.scorePercentage >= 90) return Colors.green;
    if (_analytics.scorePercentage >= 80) return Colors.blue;
    if (_analytics.scorePercentage >= 70) return Colors.orange;
    if (_analytics.scorePercentage >= 60) return Colors.amber;
    return Colors.red;
  }

  IconData get _performanceIcon {
    if (_analytics.scorePercentage >= 90) return Icons.emoji_events;
    if (_analytics.scorePercentage >= 80) return Icons.thumb_up;
    if (_analytics.scorePercentage >= 70) return Icons.sentiment_satisfied;
    if (_analytics.scorePercentage >= 60) return Icons.sentiment_neutral;
    return Icons.sentiment_dissatisfied;
  }

  String get _performanceMessage {
    if (_analytics.scorePercentage >= 90) {
      return 'Outstanding! You really understood this book!';
    } else if (_analytics.scorePercentage >= 80) {
      return 'Great job! You have a good understanding of the story!';
    } else if (_analytics.scorePercentage >= 70) {
      return 'Good work! Consider reading the book again to improve!';
    } else if (_analytics.scorePercentage >= 60) {
      return 'Not bad! You might want to read the book once more!';
    } else {
      return 'Keep trying! Reading the book again will help you learn more!';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8E8D0),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildScoreCard(),
                    const SizedBox(height: 24),
                    _buildAnalyticsCards(),
                    const SizedBox(height: 24),
                    _buildAnswerReview(),
                    const SizedBox(height: 32),
                    _buildActionButtons(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF9A826), Color(0xFFFF8C00)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.quiz, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quiz Results',
                  style: GoogleFonts.roboto(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  widget.bookTitle,
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (_isSaving)
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildScoreCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            _performanceIcon,
            size: 64,
            color: _performanceColor,
          ),
          const SizedBox(height: 16),
          Text(
            _analytics.performance,
            style: GoogleFonts.roboto(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: _performanceColor,
            ),
          ),
          const SizedBox(height: 8),
          AnimatedBuilder(
            animation: _scoreAnimation,
            builder: (context, child) {
              return Text(
                '${_scoreAnimation.value.toInt()}%',
                style: GoogleFonts.roboto(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          Text(
            _performanceMessage,
            style: GoogleFonts.roboto(
              fontSize: 16,
              color: Colors.grey[600],
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsCards() {
    return Row(
      children: [
        Expanded(
          child: _buildAnalyticsCard(
            'Correct',
            '${_analytics.correctAnswers}',
            Colors.green,
            Icons.check_circle,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildAnalyticsCard(
            'Wrong',
            '${_analytics.wrongAnswers.length}',
            Colors.red,
            Icons.cancel,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildAnalyticsCard(
            'Total',
            '${_analytics.totalQuestions}',
            Color(0xFF8B4513),
            Icons.quiz,
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyticsCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.roboto(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: GoogleFonts.roboto(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerReview() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.list_alt, color: Color(0xFF8B4513)),
                const SizedBox(width: 8),
                Text(
                  'Answer Review',
                  style: GoogleFonts.roboto(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3748),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey[200]),
          ...widget.answers.asMap().entries.map((entry) {
            final index = entry.key;
            final answer = entry.value;
            return _buildAnswerItem(index + 1, answer);
          }),
        ],
      ),
    );
  }

  Widget _buildAnswerItem(int questionNumber, QuizAnswer answer) {
    final isCorrect = answer.isCorrect;
    final color = isCorrect ? Colors.green : Colors.red;
    final icon = isCorrect ? Icons.check_circle : Icons.cancel;

    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 16),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      leading: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color),
        ),
        child: Center(
          child: Text(
            '$questionNumber',
            style: GoogleFonts.roboto(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ),
      title: Text(
        answer.question,
        style: GoogleFonts.roboto(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Color(0xFF2D3748),
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Icon(icon, color: color),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isCorrect) ...[
                _buildAnswerRow('Your Answer:', answer.selectedAnswer, Colors.red),
                const SizedBox(height: 8),
              ],
              _buildAnswerRow('Correct Answer:', answer.correctAnswer, Colors.green),
              const SizedBox(height: 12),
              Text(
                'Explanation:',
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                answer.explanation,
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAnswerRow(String label, String answer, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.roboto(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D3748),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            answer,
            style: GoogleFonts.roboto(
              fontSize: 14,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              // Better approach: Navigate back step by step
              _navigateBackToBooks();
            },
            icon: Icon(Icons.home),
            label: Text(
              'Back to Books',
              style: GoogleFonts.roboto(fontSize: 16),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF8B4513),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  // Retake quiz
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => QuizScreen(
                        bookId: widget.bookId,
                        bookTitle: widget.bookTitle,
                      ),
                    ),
                  );
                },
                icon: Icon(Icons.refresh),
                label: Text('Retake Quiz', style: GoogleFonts.roboto()),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Color(0xFF8B4513),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  _shareResults();
                },
                icon: Icon(Icons.share),
                label: Text('Share', style: GoogleFonts.roboto()),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Color(0xFF8B4513),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _navigateBackToBooks() {
    // Count how many screens we need to pop
    int popCount = 0;
    Navigator.of(context).popUntil((route) {
      popCount++;
      // Stop when we reach a route that might be the books page
      // or when we've popped enough screens
      return popCount >= 3 || route.isFirst;
    });
  }

  void _shareResults() {
    // Show sharing options
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Share Your Results',
              style: GoogleFonts.roboto(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3748),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'I just completed the quiz for "${widget.bookTitle}" and scored ${_analytics.scorePercentage.toInt()}%! 📚✨',
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  color: Color(0xFF2D3748),
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Sharing feature will be available soon!',
              style: GoogleFonts.roboto(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF8B4513),
                  foregroundColor: Colors.white,
                ),
                child: Text('Close', style: GoogleFonts.roboto()),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 