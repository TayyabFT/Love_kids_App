import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/quiz_service.dart';
import 'quiz_results_screen.dart';

class QuizScreen extends StatefulWidget {
  final String bookId;
  final String bookTitle;

  const QuizScreen({
    super.key,
    required this.bookId,
    required this.bookTitle,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> with TickerProviderStateMixin {
  final QuizService _quizService = QuizService();
  
  List<QuizQuestion> _questions = [];
  List<QuizAnswer?> _userAnswers = [];
  int _currentQuestionIndex = 0;
  bool _isLoading = true;
  
  late AnimationController _progressController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _loadQuiz();
  }

  @override
  void dispose() {
    _progressController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _loadQuiz() async {
    setState(() {
      _isLoading = true;
    });

    await Future.delayed(const Duration(milliseconds: 500)); // Simulate loading

    final questions = _quizService.getRandomQuestionsForBook(widget.bookId, count: 10);
    
    setState(() {
      _questions = questions;
      _userAnswers = List.filled(questions.length, null);
      _isLoading = false;
    });

    _fadeController.forward();
    _updateProgress();
  }

  void _updateProgress() {
    final progress = (_currentQuestionIndex + 1) / _questions.length;
    _progressController.animateTo(progress);
  }

  void _selectAnswer(int selectedIndex) {
    if (_userAnswers[_currentQuestionIndex] != null) {
      print('⚠️ Answer already selected for question ${_currentQuestionIndex + 1}');
      return; // Already answered
    }

    print('🎯 Answer selected for question ${_currentQuestionIndex + 1}: Option ${selectedIndex + 1}');

    final question = _questions[_currentQuestionIndex];
    final isCorrect = selectedIndex == question.correctAnswerIndex;
    
    final answer = QuizAnswer(
      questionId: question.id,
      question: question.question,
      selectedAnswer: question.options[selectedIndex],
      correctAnswer: question.correctAnswer,
      isCorrect: isCorrect,
      explanation: question.explanation,
      selectedIndex: selectedIndex,
    );

    setState(() {
      _userAnswers[_currentQuestionIndex] = answer;
    });

    print('✅ Answer saved. Correct: $isCorrect');
    // Remove auto-advance - let user control navigation
    // User will use Next button to proceed
  }

  void _nextQuestion() {
    print('📝 Next Question called - Current: $_currentQuestionIndex, Total: ${_questions.length}');
    
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
      print('✅ Advanced to question ${_currentQuestionIndex + 1}');
      _updateProgress();
      _fadeController.reset();
      _fadeController.forward();
    } else {
      print('🏁 Quiz finished!');
      _finishQuiz();
    }
  }

  void _previousQuestion() {
    print('◀️ Previous Question called - Current: $_currentQuestionIndex');
    
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
      });
      print('✅ Moved back to question ${_currentQuestionIndex + 1}');
      _updateProgress();
      _fadeController.reset();
      _fadeController.forward();
    }
  }

  void _finishQuiz() {
    // Filter out null answers
    final answers = _userAnswers.whereType<QuizAnswer>().toList();
    
    if (answers.length < _questions.length) {
      // Show dialog if not all questions are answered
      _showIncompleteDialog();
      return;
    }

    // Navigate to results
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => QuizResultsScreen(
          bookId: widget.bookId,
          bookTitle: widget.bookTitle,
          answers: answers,
        ),
      ),
    );
  }

  void _showIncompleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Quiz Incomplete',
          style: GoogleFonts.roboto(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Please answer all questions before finishing the quiz.',
          style: GoogleFonts.roboto(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK', style: GoogleFonts.roboto()),
          ),
        ],
      ),
    );
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Exit Quiz?',
          style: GoogleFonts.roboto(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to exit? Your progress will be lost.',
          style: GoogleFonts.roboto(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.roboto()),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Exit quiz
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('Exit', style: GoogleFonts.roboto()),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _showExitDialog();
        return false;
      },
      child: Scaffold(
        backgroundColor: Color(0xFFF8E8D0),
        body: SafeArea(
          child: _isLoading ? _buildLoadingState() : _buildQuizContent(),
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
            'Preparing your quiz...',
            style: GoogleFonts.roboto(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Get ready to test your knowledge!',
            style: GoogleFonts.roboto(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizContent() {
    if (_questions.isEmpty) {
      return _buildNoQuestionsState();
    }

    final question = _questions[_currentQuestionIndex];
    final userAnswer = _userAnswers[_currentQuestionIndex];

    return Column(
      children: [
        _buildHeader(),
        _buildProgressBar(),
        Expanded(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildQuestionCard(question),
                  const SizedBox(height: 24),
                  Expanded(
                    child: _buildAnswerOptions(question, userAnswer),
                  ),
                  _buildNavigationButtons(),
                ],
              ),
            ),
          ),
        ),
      ],
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
          IconButton(
            icon: Icon(Icons.close, color: Colors.white),
            onPressed: _showExitDialog,
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  'Quiz: ${widget.bookTitle}',
                  style: GoogleFonts.roboto(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Question ${_currentQuestionIndex + 1} of ${_questions.length}',
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '${_userAnswers.whereType<QuizAnswer>().length}/${_questions.length}',
              style: GoogleFonts.roboto(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Container(
      height: 6,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: AnimatedBuilder(
        animation: _progressController,
        builder: (context, child) {
          return LinearProgressIndicator(
            value: _progressController.value,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8B4513)),
          );
        },
      ),
    );
  }

  Widget _buildQuestionCard(QuizQuestion question) {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Text(
        question.question,
        style: GoogleFonts.roboto(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Color(0xFF2D3748),
          height: 1.4,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildAnswerOptions(QuizQuestion question, QuizAnswer? userAnswer) {
    return ListView.builder(
      itemCount: question.options.length,
      itemBuilder: (context, index) {
        final option = question.options[index];
        final isSelected = userAnswer?.selectedIndex == index;
        final isCorrect = index == question.correctAnswerIndex;
        final showResult = userAnswer != null;

        Color backgroundColor = Colors.white;
        Color borderColor = Colors.grey[300]!;
        Color textColor = Color(0xFF2D3748);

        if (showResult) {
          if (isSelected && isCorrect) {
            backgroundColor = Colors.green[50]!;
            borderColor = Colors.green;
            textColor = Colors.green[800]!;
          } else if (isSelected && !isCorrect) {
            backgroundColor = Colors.red[50]!;
            borderColor = Colors.red;
            textColor = Colors.red[800]!;
          } else if (!isSelected && isCorrect) {
            backgroundColor = Colors.green[50]!;
            borderColor = Colors.green;
            textColor = Colors.green[800]!;
          }
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: Material(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: showResult ? null : () => _selectAnswer(index),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: borderColor, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: borderColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderColor),
                      ),
                      child: Center(
                        child: Text(
                          String.fromCharCode(65 + index), // A, B, C, D
                          style: GoogleFonts.roboto(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: borderColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        option,
                        style: GoogleFonts.roboto(
                          fontSize: 16,
                          color: textColor,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ),
                    if (showResult && isCorrect)
                      Icon(Icons.check_circle, color: Colors.green, size: 24),
                    if (showResult && isSelected && !isCorrect)
                      Icon(Icons.cancel, color: Colors.red, size: 24),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavigationButtons() {
    final canGoNext = _userAnswers[_currentQuestionIndex] != null;
    final isLastQuestion = _currentQuestionIndex == _questions.length - 1;
    
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        children: [
          if (_currentQuestionIndex > 0)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _previousQuestion,
                icon: Icon(Icons.arrow_back),
                label: Text('Previous', style: GoogleFonts.roboto()),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Color(0xFF8B4513),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          if (_currentQuestionIndex > 0) const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: canGoNext
                  ? (isLastQuestion ? _finishQuiz : _nextQuestion)
                  : null,
              icon: Icon(isLastQuestion ? Icons.check : Icons.arrow_forward),
              label: Text(
                isLastQuestion ? 'Finish Quiz' : 'Next',
                style: GoogleFonts.roboto(),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: canGoNext ? Color(0xFF8B4513) : Colors.grey,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoQuestionsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.quiz_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'No Quiz Available',
              style: GoogleFonts.roboto(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3748),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Sorry, there are no quiz questions available for this book yet.',
              style: GoogleFonts.roboto(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: Icon(Icons.arrow_back),
              label: Text('Go Back', style: GoogleFonts.roboto()),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF8B4513),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 