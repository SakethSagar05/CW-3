import 'callable.dart';
import 'messages.dart';

class CoachService {
  /// Sends only the question. No uid, tool name or reward is sent; the
  /// server-side agent reads the caller's own quest state through its one
  /// read-only tool and returns plain text.
  Future<String> getQuestHint(String question) async {
    final result =
        await callFunction('askQuestCoach', {'question': clampQuestion(question)});
    return result['reply'] as String? ?? '';
  }
}
