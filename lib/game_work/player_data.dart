import 'package:flutter/material.dart';
import 'game_models.dart';

// Complete PlayerData class with money system and game properties
class PlayerData {
  final String name;
  final Color color;
  final int characterIndex;
  final String imagePath;

  // Money properties
  int totalMoney = 100; // Starting money
  int ones = 5; // $1 x 5
  int fives = 3; // $5 x 3
  int tens = 1; // $10 x 1
  int twenties = 1; // $20 x 1
  int fifties = 1; // $50 x 1
  int hundreds = 0; // $100 x 0

  // Player position property
  int position = 0; // Starting position (0 = first square)

  // Turn tracking
  int turnsCompleted = 0;

  int lapsCompleted = 0;

  // Question history tracking
  List<QuestionHistoryItem> questionHistory = [];

  // Skip turn property
  bool skipNextTurn = false;

  PlayerData({
    required this.name,
    required this.color,
    required this.characterIndex,
    required this.imagePath,
  });

  // Calculate total money based on denominations
  void recalculateTotal() {
    totalMoney = ones + (fives * 5) + (tens * 10) + (twenties * 20) + (fifties * 50) + (hundreds * 100);
  }

  // Add money by denomination
  void addMoney(int amount) {
    // Add money in the most efficient way (largest denominations first)
    while (amount >= 100 && amount > 0) {
      hundreds++;
      amount -= 100;
    }

    while (amount >= 50 && amount > 0) {
      fifties++;
      amount -= 50;
    }

    while (amount >= 20 && amount > 0) {
      twenties++;
      amount -= 20;
    }

    while (amount >= 10 && amount > 0) {
      tens++;
      amount -= 10;
    }

    while (amount >= 5 && amount > 0) {
      fives++;
      amount -= 5;
    }

    while (amount >= 1 && amount > 0) {
      ones++;
      amount -= 1;
    }

    recalculateTotal();
  }

  // Subtract money
  bool subtractMoney(int amount) {
    if (amount > totalMoney) {
      return false; // Not enough money
    }

    // Make a copy of current denominations
    int tempOnes = ones;
    int tempFives = fives;
    int tempTens = tens;
    int tempTwenties = twenties;
    int tempFifties = fifties;
    int tempHundreds = hundreds;

    // Take money from largest denominations first
    while (amount >= 100 && tempHundreds > 0) {
      tempHundreds--;
      amount -= 100;
    }

    while (amount >= 50 && tempFifties > 0) {
      tempFifties--;
      amount -= 50;
    }

    while (amount >= 20 && tempTwenties > 0) {
      tempTwenties--;
      amount -= 20;
    }

    while (amount >= 10 && tempTens > 0) {
      tempTens--;
      amount -= 10;
    }

    while (amount >= 5 && tempFives > 0) {
      tempFives--;
      amount -= 5;
    }

    while (amount >= 1 && tempOnes > 0) {
      tempOnes--;
      amount -= 1;
    }

    // If we couldn't subtract the full amount, we need to make change
    if (amount > 0) {
      // Try to make change - simplified algorithm
      if (amount <= 5 && tempFives > 0) {
        tempFives--;
        tempOnes += 5 - amount;
        amount = 0;
      }
      // Similar logic for other denominations...
    }

    if (amount == 0) {
      // Apply the changes
      ones = tempOnes;
      fives = tempFives;
      tens = tempTens;
      twenties = tempTwenties;
      fifties = tempFifties;
      hundreds = tempHundreds;
      recalculateTotal();
      return true;
    }

    return false; // Couldn't make exact change
  }

  // Method to add completed turn
  void completeTurn() {
    turnsCompleted++;
  }

  // Method to add question to history
  void addQuestionToHistory(
    EducationQuestion question,
    int answeredIndex,
    bool wasCorrect,
  ) {
    questionHistory.add(
      QuestionHistoryItem(
        question: question,
        answeredIndex: answeredIndex,
        wasCorrect: wasCorrect,
      ),
    );
  }
}

// Class to store question history items
class QuestionHistoryItem {
  final EducationQuestion question;
  final int answeredIndex;
  final bool wasCorrect;

  QuestionHistoryItem({
    required this.question,
    required this.answeredIndex,
    required this.wasCorrect,
  });
}
