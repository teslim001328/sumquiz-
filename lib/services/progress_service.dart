import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';

class ProgressService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<int> getSummariesCount(String userId) async {
    try {
      final snapshot = await _db
          .collection('users')
          .doc(userId)
          .collection('summaries')
          .get();
      return snapshot.docs.length;
    } catch (e) {
      // Log error and return 0 as fallback
      debugPrint('Error getting summaries count: $e');
      return 0;
    }
  }

  Future<int> getQuizzesCount(String userId) async {
    try {
      final snapshot =
          await _db.collection('users').doc(userId).collection('quizzes').get();
      return snapshot.docs.length;
    } catch (e) {
      // Log error and return 0 as fallback
      debugPrint('Error getting quizzes count: $e');
      return 0;
    }
  }

  Future<int> getFlashcardsCount(String userId) async {
    try {
      final snapshot = await _db
          .collection('users')
          .doc(userId)
          .collection('flashcards')
          .get();
      return snapshot.docs.length;
    } catch (e) {
      // Log error and return 0 as fallback
      debugPrint('Error getting flashcards count: $e');
      return 0;
    }
  }

  Future<List<FlSpot>> getWeeklyActivity(String userId) async {
    final today = DateTime.now();
    final startOfToday = DateTime(today.year, today.month, today.day);
    final activity = <double>[0, 0, 0, 0, 0, 0, 0];

    // Calculate the start of the week (7 days ago)
    final startOfWeek = startOfToday.subtract(const Duration(days: 6));

    final summaries = await _db
        .collection('users')
        .doc(userId)
        .collection('summaries')
        .where('created_at', isGreaterThanOrEqualTo: startOfWeek)
        .get();

    final quizzes = await _db
        .collection('users')
        .doc(userId)
        .collection('quizzes')
        .where('created_at', isGreaterThanOrEqualTo: startOfWeek)
        .get();

    final flashcards = await _db
        .collection('users')
        .doc(userId)
        .collection('flashcards')
        .where('created_at', isGreaterThanOrEqualTo: startOfWeek)
        .get();

    void incrementActivity(DateTime createdAt) {
      final daysDifference = startOfToday
          .difference(DateTime(createdAt.year, createdAt.month, createdAt.day))
          .inDays;

      // Only count activities within the last 7 days
      if (daysDifference >= 0 && daysDifference < 7) {
        activity[daysDifference]++;
      }
    }

    for (var doc in summaries.docs) {
      final createdAt = (doc.data()['created_at'] as Timestamp).toDate();
      incrementActivity(createdAt);
    }

    for (var doc in quizzes.docs) {
      final createdAt = (doc.data()['created_at'] as Timestamp).toDate();
      incrementActivity(createdAt);
    }

    for (var doc in flashcards.docs) {
      final createdAt = (doc.data()['created_at'] as Timestamp).toDate();
      incrementActivity(createdAt);
    }

    return List.generate(
        7, (index) => FlSpot(index.toDouble(), activity[index]));
  }
}
