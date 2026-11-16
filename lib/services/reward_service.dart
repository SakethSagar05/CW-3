import 'callable.dart';

class RewardResult {
  const RewardResult({
    required this.points,
    required this.badgeId,
    required this.alreadyCompleted,
  });

  factory RewardResult.fromMap(Map<dynamic, dynamic> data) {
    return RewardResult(
      points: (data['points'] as num?)?.toInt() ?? 0,
      badgeId: data['badgeId'] as String?,
      alreadyCompleted: data['alreadyCompleted'] == true,
    );
  }

  final int points;
  final String? badgeId;
  final bool alreadyCompleted;
}

class RewardService {
  /// Asks the trusted backend to complete today's challenge.
  /// Only the challenge id is sent. The Function takes the uid from the
  /// verified sign-in and decides the points and badge itself.
  Future<RewardResult> completeChallenge() async {
    final result = await callFunction('completeToday', {'challengeId': 'today'});
    return RewardResult.fromMap(result);
  }
}
