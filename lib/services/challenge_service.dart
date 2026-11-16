import 'package:cloud_firestore/cloud_firestore.dart';

class Challenge {
  const Challenge({required this.title, required this.prompt});

  final String title;
  final String prompt;
}

class Progress {
  const Progress({
    required this.completed,
    required this.points,
    required this.badgeId,
  });

  static const Progress none =
      Progress(completed: false, points: 0, badgeId: null);

  factory Progress.fromMap(Map<String, dynamic>? data) {
    if (data == null) return none;
    return Progress(
      completed: data['completed'] == true,
      points: (data['points'] as num?)?.toInt() ?? 0,
      badgeId: data['badgeId'] as String?,
    );
  }

  final bool completed;
  final int points;
  final String? badgeId;
}

class ChallengeMissingException implements Exception {
  const ChallengeMissingException();
}

/// Read-only Firestore access. The app never writes: rules deny client
/// writes, and rewards are written only by the completeToday Function.
class ChallengeService {
  ChallengeService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  /// Loads the one shared challenge, challenges/today.
  Future<Challenge> loadToday() async {
    final snapshot = await _db.collection('challenges').doc('today').get();
    final data = snapshot.data();
    if (!snapshot.exists || data == null) {
      throw const ChallengeMissingException();
    }
    return Challenge(
      title: data['title'] as String? ?? "Today's challenge",
      prompt: data['prompt'] as String? ?? '',
    );
  }

  /// Live view of users/{uid}/progress/today for the signed-in learner only.
  Stream<Progress> watchProgress(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('progress')
        .doc('today')
        .snapshots()
        .map((snapshot) => Progress.fromMap(snapshot.data()));
  }
}
