import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class QuizService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Quiz questions for each book
  final Map<String, List<QuizQuestion>> _bookQuizzes = {
    'book1': [
      QuizQuestion(
        id: 'book1_q1',
        question: 'What does Kyle eat for breakfast?',
        options: [
          'Cereal',
          'Pancakes',
          'Toast',
          'Eggs'
        ],
        correctAnswerIndex: 1,
        explanation: 'Kyle eats pancakes for breakfast.',
      ),
      QuizQuestion(
        id: 'book1_q2',
        question: 'What does Mr. Redduck say about Kyle?',
        options: [
          'You are so fast.',
          'You have quite the appetite.',
          'You are very smart.',
          'You are getting tall.'
        ],
        correctAnswerIndex: 1,
        explanation: 'Mr. Redduck says "You have quite the appetite" about Kyle.',
      ),
      QuizQuestion(
        id: 'book1_q3',
        question: 'What does Kyle do right before leaving for school?',
        options: [
          'Brushes his teeth.',
          'Put on his shoes.',
          'Grabs his pencils and stuff them in his book bag.',
          'Says goodbye to his parents.'
        ],
        correctAnswerIndex: 2,
        explanation: 'Right before leaving for school, Kyle grabs his pencils and stuffs them in his book bag.',
      ),
      QuizQuestion(
        id: 'book1_q4',
        question: 'Who is Kyle\'s dad?',
        options: [
          'Mr. Smith',
          'Mr. Johnson',
          'Mr. Redduck',
          'Mr. Brown'
        ],
        correctAnswerIndex: 2,
        explanation: 'Kyle\'s father is Mr. Redduck.',
      ),
      QuizQuestion(
        id: 'book1_q5',
        question: 'Name three of Kyle\'s friends playing at the park.',
        options: [
          'Bobby, Jessica and Doug.',
          'Bobby, Mitchell and Sallie.',
          'Sallie, Mitchell and Terry.',
          'Mary, Thomas and James.'
        ],
        correctAnswerIndex: 1,
        explanation: 'Kyle\'s three friends playing at the park are Bobby, Mitchell and Sallie.',
      ),
      QuizQuestion(
        id: 'book1_q6',
        question: 'Who had an adopted sister in the story?',
        options: [
          'Regina',
          'Bobby',
          'Sallie',
          'Mitchell'
        ],
        correctAnswerIndex: 2,
        explanation: 'Sallie had an adopted sister in the story.',
      ),
      QuizQuestion(
        id: 'book1_q7',
        question: 'What was the name of Kyle\'s mother\'s doctor in the book?',
        options: [
          'Dr. Mason',
          'Dr. Johnson',
          'Dr. Smith',
          'Dr. Brown'
        ],
        correctAnswerIndex: 2,
        explanation: 'Kyle\'s mother\'s doctor was named Dr. Smith.',
      ),
      QuizQuestion(
        id: 'book1_q8',
        question: 'What was Kyle\'s baby sister\'s name?',
        options: [
          'Susan',
          'Danielle',
          'Sallie',
          'Jessica'
        ],
        correctAnswerIndex: 1,
        explanation: 'Kyle\'s baby sister\'s name is Danielle.',
      ),
      QuizQuestion(
        id: 'book1_q9',
        question: 'Who came to visit The Redduck Family at the hospital?',
        options: [
          'Mary',
          'Kyle\'s teacher',
          'Grandpa and Grandma',
          'Aunt Sara'
        ],
        correctAnswerIndex: 2,
        explanation: 'Grandpa and Grandma came to visit The Redduck Family at the hospital.',
      ),
      QuizQuestion(
        id: 'book1_q10',
        question: 'What things did Kyle\'s parents allow him to do with his new sister?',
        options: [
          'Cook for her.',
          'Hold her in his arms and feed her a bottle.',
          'Ride her on his bike.',
          'Put her in a swing.'
        ],
        correctAnswerIndex: 1,
        explanation: 'Kyle\'s parents allowed him to hold her in his arms and feed her a bottle.',
      ),
    ],

    'book2': [
      QuizQuestion(
        id: 'book2_q1',
        question: 'How old is Hunter Reed?',
        options: [
          'Six years old',
          'Seven years old',
          'Eight years old',
          'Nine years old'
        ],
        correctAnswerIndex: 2,
        explanation: 'Hunter Reed is eight years old.',
      ),
      QuizQuestion(
        id: 'book2_q2',
        question: 'What grade is Hunter in?',
        options: [
          'First grade',
          'Second grade',
          'Third grade',
          'Kindergarten'
        ],
        correctAnswerIndex: 1,
        explanation: 'Hunter is in second grade.',
      ),
      QuizQuestion(
        id: 'book2_q3',
        question: 'Where did Hunter\'s parents take him to get tested?',
        options: [
          'The red building',
          'The blue building',
          'The brown building',
          'The white building'
        ],
        correctAnswerIndex: 2,
        explanation: 'Hunter\'s parents took him to the brown building to get tested.',
      ),
      QuizQuestion(
        id: 'book2_q4',
        question: 'Who tested Hunter at the brown building?',
        options: [
          'Mrs. Smith',
          'Mrs. Johnson',
          'Mrs. Jones',
          'Mrs. Brown'
        ],
        correctAnswerIndex: 2,
        explanation: 'Mrs. Jones tested Hunter at the brown building.',
      ),
      QuizQuestion(
        id: 'book2_q5',
        question: 'What does Hunter like better - addition or subtraction?',
        options: [
          'Subtraction',
          'Addition',
          'He likes them both the same',
          'He doesn\'t like math'
        ],
        correctAnswerIndex: 1,
        explanation: 'Hunter likes addition better than subtraction.',
      ),
      QuizQuestion(
        id: 'book2_q6',
        question: 'What happened to Hunter\'s mom after the meeting?',
        options: [
          'She went to the store',
          'She got on a bus and never came back',
          'She went to work',
          'She stayed home'
        ],
        correctAnswerIndex: 1,
        explanation: 'Hunter\'s mom got on a bus and never came back after the meeting.',
      ),
      QuizQuestion(
        id: 'book2_q7',
        question: 'What is the name of Hunter\'s new school?',
        options: [
          'North Creek Elementary',
          'West Creek Elementary',
          'East Creek Elementary',
          'South Creek Elementary'
        ],
        correctAnswerIndex: 3,
        explanation: 'Hunter\'s new school is called South Creek Elementary.',
      ),
      QuizQuestion(
        id: 'book2_q8',
        question: 'Who is Hunter\'s main teacher?',
        options: [
          'Mrs. Santrock',
          'Ms. Walker',
          'Ms. Malcolm',
          'Mrs. Camps'
        ],
        correctAnswerIndex: 0,
        explanation: 'Mrs. Santrock is Hunter\'s main teacher.',
      ),
      QuizQuestion(
        id: 'book2_q9',
        question: 'What did Kelvin and the other boys make a mess with during art class?',
        options: [
          'Paint',
          'Crayons',
          'Glue',
          'Water'
        ],
        correctAnswerIndex: 2,
        explanation: 'Kelvin and the other boys made a mess with glue during art class.',
      ),
      QuizQuestion(
        id: 'book2_q10',
        question: 'How did Hunter feel at the end of his first day at the new school?',
        options: [
          'Sad and upset',
          'Angry and mad',
          'Scared and worried',
          'Happy and good about it'
        ],
        correctAnswerIndex: 3,
        explanation: 'Hunter felt happy and good about it at the end of his first day at the new school.',
      ),
    ],

    'book3': [
      QuizQuestion(
        id: 'book3_q1',
        question: 'How long have Kylie and Kyle been living with Mrs. Walker?',
        options: [
          'Three months',
          'Six months',
          'One year',
          'Two years'
        ],
        correctAnswerIndex: 1,
        explanation: 'Kylie and Kyle have been living with Mrs. Walker for six months.',
      ),
      QuizQuestion(
        id: 'book3_q2',
        question: 'What special breakfast did Mrs. Walker make for them?',
        options: [
          'Chocolate chip pancakes',
          'Regular pancakes',
          'Blueberry pancakes',
          'Waffles'
        ],
        correctAnswerIndex: 2,
        explanation: 'Mrs. Walker made special blueberry pancakes for breakfast.',
      ),
      QuizQuestion(
        id: 'book3_q3',
        question: 'What did Dr. Mathis find when he checked Kyle\'s teeth?',
        options: [
          'His teeth were perfect',
          'He needed braces',
          'He had a small cavity',
          'He lost a tooth'
        ],
        correctAnswerIndex: 2,
        explanation: 'Dr. Mathis found that Kyle had a small cavity when he checked his teeth.',
      ),
      QuizQuestion(
        id: 'book3_q4',
        question: 'How many times a day should Kyle brush his teeth?',
        options: [
          'One time',
          'Two times',
          'Three times',
          'Four times'
        ],
        correctAnswerIndex: 2,
        explanation: 'Kyle should brush his teeth three times a day.',
      ),
      QuizQuestion(
        id: 'book3_q5',
        question: 'Who did they visit at McDonald\'s?',
        options: [
          'Their mom',
          'Their dad',
          'Grandma Jessie',
          'Their teacher'
        ],
        correctAnswerIndex: 2,
        explanation: 'They visited Grandma Jessie at McDonald\'s.',
      ),
      QuizQuestion(
        id: 'book3_q6',
        question: 'What is the name of the new boy who came for a weekend visit?',
        options: [
          'Brandon',
          'Brian',
          'Bradley',
          'Bryan'
        ],
        correctAnswerIndex: 1,
        explanation: 'The new boy who came for a weekend visit is named Brian.',
      ),
      QuizQuestion(
        id: 'book3_q7',
        question: 'Where is their mother Karen now?',
        options: [
          'At work',
          'In jail',
          'In rehab',
          'At home'
        ],
        correctAnswerIndex: 2,
        explanation: 'Their mother Karen is currently in rehab.',
      ),
      QuizQuestion(
        id: 'book3_q8',
        question: 'Who took Kylie and Kyle to court?',
        options: [
          'Mrs. Walker',
          'Ms. Alice',
          'Their grandmother',
          'Their teacher'
        ],
        correctAnswerIndex: 1,
        explanation: 'Ms. Alice took Kylie and Kyle to court.',
      ),
      QuizQuestion(
        id: 'book3_q9',
        question: 'What did Judge Reiner decide at the court hearing?',
        options: [
          'The children had to go back to their mom',
          'The children could stay with Mrs. Walker',
          'The children had to move to a new home',
          'The children had to live with their grandmother'
        ],
        correctAnswerIndex: 1,
        explanation: 'Judge Reiner decided that the children could stay with Mrs. Walker.',
      ),
      QuizQuestion(
        id: 'book3_q10',
        question: 'What did Mrs. Walker suggest they do after the court hearing?',
        options: [
          'Go home and rest',
          'Stop for ice cream',
          'Visit their grandmother',
          'Go to the park'
        ],
        correctAnswerIndex: 1,
        explanation: 'Mrs. Walker suggested they stop for ice cream after the court hearing.',
      ),
    ],
  };

  // Get quiz questions for a specific book
  List<QuizQuestion> getQuizForBook(String bookId) {
    return _bookQuizzes[bookId] ?? [];
  }

  // Get random questions for a book (10-12 questions)
  List<QuizQuestion> getRandomQuestionsForBook(String bookId, {int count = 10}) {
    final allQuestions = _bookQuizzes[bookId] ?? [];
    if (allQuestions.isEmpty) return [];
    
    allQuestions.shuffle();
    return allQuestions.take(count).toList();
  }

  // Save quiz result
  Future<void> saveQuizResult({
    required String bookId,
    required List<QuizAnswer> answers,
    required double scorePercentage,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final quizResult = {
        'bookId': bookId,
        'userId': user.uid,
        'answers': answers.map((answer) => answer.toMap()).toList(),
        'scorePercentage': scorePercentage,
        'correctAnswers': answers.where((a) => a.isCorrect).length,
        'totalQuestions': answers.length,
        'completedAt': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('quizResults')
          .doc('${bookId}_${DateTime.now().millisecondsSinceEpoch}')
          .set(quizResult);

      print('Quiz result saved successfully');
    } catch (e) {
      print('Error saving quiz result: $e');
    }
  }

  // Get quiz history for a user
  Future<List<Map<String, dynamic>>> getQuizHistory({int limit = 20}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final querySnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('quizResults')
          .orderBy('completedAt', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print('Error getting quiz history: $e');
      return [];
    }
  }

  // Calculate quiz analytics
  QuizAnalytics calculateAnalytics(List<QuizAnswer> answers) {
    final correctAnswers = answers.where((a) => a.isCorrect).length;
    final totalQuestions = answers.length;
    final scorePercentage = (correctAnswers / totalQuestions) * 100;

    String performance;
    if (scorePercentage >= 90) {
      performance = 'Excellent';
    } else if (scorePercentage >= 80) {
      performance = 'Great';
    } else if (scorePercentage >= 70) {
      performance = 'Good';
    } else if (scorePercentage >= 60) {
      performance = 'Fair';
    } else {
      performance = 'Needs Improvement';
    }

    return QuizAnalytics(
      correctAnswers: correctAnswers,
      totalQuestions: totalQuestions,
      scorePercentage: scorePercentage,
      performance: performance,
      wrongAnswers: answers.where((a) => !a.isCorrect).toList(),
    );
  }
}

class QuizQuestion {
  final String id;
  final String question;
  final List<String> options;
  final int correctAnswerIndex;
  final String explanation;

  QuizQuestion({
    required this.id,
    required this.question,
    required this.options,
    required this.correctAnswerIndex,
    required this.explanation,
  });

  String get correctAnswer => options[correctAnswerIndex];
}

class QuizAnswer {
  final String questionId;
  final String question;
  final String selectedAnswer;
  final String correctAnswer;
  final bool isCorrect;
  final String explanation;
  final int selectedIndex;

  QuizAnswer({
    required this.questionId,
    required this.question,
    required this.selectedAnswer,
    required this.correctAnswer,
    required this.isCorrect,
    required this.explanation,
    required this.selectedIndex,
  });

  Map<String, dynamic> toMap() {
    return {
      'questionId': questionId,
      'question': question,
      'selectedAnswer': selectedAnswer,
      'correctAnswer': correctAnswer,
      'isCorrect': isCorrect,
      'explanation': explanation,
      'selectedIndex': selectedIndex,
    };
  }
}

class QuizAnalytics {
  final int correctAnswers;
  final int totalQuestions;
  final double scorePercentage;
  final String performance;
  final List<QuizAnswer> wrongAnswers;

  QuizAnalytics({
    required this.correctAnswers,
    required this.totalQuestions,
    required this.scorePercentage,
    required this.performance,
    required this.wrongAnswers,
  });
} 