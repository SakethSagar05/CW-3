// Plain Dart helpers with no Firebase imports, so they can be unit tested.

const int maxQuestionLength = 300;

/// Trims the learner's question and caps it at [maxQuestionLength].
/// The server validates again; this only keeps the request small.
String clampQuestion(String question) {
  final trimmed = question.trim();
  return trimmed.length > maxQuestionLength
      ? trimmed.substring(0, maxQuestionLength)
      : trimmed;
}

/// Turns a FirebaseAuthException code into text that is safe to show.
/// Sign-in failures do not reveal whether an email is registered.
String authErrorMessage(String code) {
  switch (code) {
    case 'invalid-email':
      return 'Enter a valid email address.';
    case 'weak-password':
      return 'Use a password with at least 6 characters.';
    case 'email-already-in-use':
      return 'An account already exists for that email. Try signing in.';
    case 'user-not-found':
    case 'wrong-password':
    case 'invalid-credential':
    case 'INVALID_LOGIN_CREDENTIALS':
      return 'Email or password is incorrect.';
    case 'user-disabled':
      return 'This account has been disabled.';
    case 'too-many-requests':
      return 'Too many attempts. Wait a moment and try again.';
    case 'network-request-failed':
      return 'Cannot reach the server. Check that the emulators are running.';
    default:
      return 'Something went wrong. Try again.';
  }
}

/// Turns a CallableException code from the reward call into text.
String rewardErrorMessage(String code) {
  switch (code) {
    case 'unauthenticated':
      return 'Sign in again to complete the challenge.';
    case 'not-found':
      return "Today's challenge is not available yet.";
    case 'unavailable':
    case 'deadline-exceeded':
      return 'The reward service is unavailable. Your progress is unchanged; try again.';
    default:
      return 'Could not complete the challenge. Your progress is unchanged; try again.';
  }
}

String badgeName(String? badgeId) {
  if (badgeId == null) return 'No badge yet';
  if (badgeId == 'first-quest') return 'First Quest';
  return badgeId;
}
