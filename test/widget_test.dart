import 'package:cloud_quest/services/challenge_service.dart';
import 'package:cloud_quest/services/messages.dart';
import 'package:cloud_quest/services/reward_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('clampQuestion trims and caps at 300 characters', () {
    expect(clampQuestion('  hint?  '), 'hint?');
    expect(clampQuestion('x' * 500).length, 300);
    expect(clampQuestion('   '), isEmpty);
  });

  test('auth errors never reveal whether an email is registered', () {
    expect(authErrorMessage('user-not-found'), authErrorMessage('wrong-password'));
    expect(authErrorMessage('something-new'), 'Something went wrong. Try again.');
  });

  test('progress defaults to zero points and no badge', () {
    final none = Progress.fromMap(null);
    expect(none.completed, isFalse);
    expect(none.points, 0);
    expect(badgeName(none.badgeId), 'No badge yet');
  });

  test('reward result distinguishes first completion from a retry', () {
    final first = RewardResult.fromMap(
      {'points': 10, 'badgeId': 'first-quest', 'alreadyCompleted': false},
    );
    final retry = RewardResult.fromMap(
      {'points': 10, 'badgeId': 'first-quest', 'alreadyCompleted': true},
    );
    expect(first.alreadyCompleted, isFalse);
    expect(retry.alreadyCompleted, isTrue);
    expect(retry.points, first.points);
    expect(badgeName(first.badgeId), 'First Quest');
  });
}
