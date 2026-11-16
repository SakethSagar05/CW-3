import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/callable.dart';
import '../services/challenge_service.dart';
import '../services/coach_service.dart';
import '../services/messages.dart';
import '../services/reward_service.dart';

/// The signed-in learner journey: read today's challenge, ask the coach for
/// a hint, and complete the challenge with one explicit button.
class ChallengeScreen extends StatefulWidget {
  const ChallengeScreen({super.key, required this.user, required this.auth});

  final User user;
  final AuthService auth;

  @override
  State<ChallengeScreen> createState() => _ChallengeScreenState();
}

class _ChallengeScreenState extends State<ChallengeScreen> {
  final _challenges = ChallengeService();
  final _rewards = RewardService();
  final _coach = CoachService();
  final _question = TextEditingController();

  late Future<Challenge> _challenge = _challenges.loadToday();
  late final Stream<Progress> _progress =
      _challenges.watchProgress(widget.user.uid);

  bool _completing = false;
  String? _rewardMessage;
  bool _rewardFailed = false;

  bool _asking = false;
  String? _coachReply;
  bool _coachFailed = false;

  @override
  void dispose() {
    _question.dispose();
    super.dispose();
  }

  /// The only path to a reward: the learner taps the button, and the trusted
  /// Function decides. The coach has no way to trigger this.
  Future<void> _complete() async {
    if (_completing) return;
    setState(() {
      _completing = true;
      _rewardMessage = null;
      _rewardFailed = false;
    });
    try {
      final result = await _rewards.completeChallenge();
      if (!mounted) return;
      setState(() {
        _rewardMessage = result.alreadyCompleted
            ? 'Already completed. You keep your ${result.points} points and the '
                '${badgeName(result.badgeId)} badge; no extra reward was added.'
            : 'Challenge complete! You earned ${result.points} points and the '
                '${badgeName(result.badgeId)} badge.';
      });
    } on CallableException catch (error) {
      debugPrint('completeToday failed: code=${error.code} message=${error.message}');
      if (!mounted) return;
      setState(() {
        _rewardFailed = true;
        _rewardMessage = rewardErrorMessage(error.code);
      });
    } catch (error) {
      debugPrint('completeToday failed: $error');
      if (!mounted) return;
      setState(() {
        _rewardFailed = true;
        _rewardMessage = rewardErrorMessage('unknown');
      });
    } finally {
      if (mounted) setState(() => _completing = false);
    }
  }

  Future<void> _askCoach() async {
    if (_asking) return;
    if (clampQuestion(_question.text).isEmpty) {
      setState(() {
        _coachFailed = true;
        _coachReply = 'Type a question for the coach first.';
      });
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _asking = true;
      _coachReply = null;
      _coachFailed = false;
    });
    try {
      final reply = await _coach.getQuestHint(_question.text);
      if (!mounted) return;
      setState(() => _coachReply = reply);
    } on CallableException catch (error) {
      debugPrint('Quest Coach request failed: code=${error.code} message=${error.message}');
      if (!mounted) return;
      setState(() {
        _coachFailed = true;
        _coachReply = error.code == 'invalid-argument'
            ? 'Ask a question of 300 characters or fewer.'
            : 'The coach is unavailable. Try again.';
      });
    } catch (error) {
      debugPrint('Quest Coach request failed: $error');
      if (!mounted) return;
      setState(() {
        _coachFailed = true;
        _coachReply = 'The coach is unavailable. Try again.';
      });
    } finally {
      if (mounted) setState(() => _asking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cloud Quest'),
        actions: [
          TextButton.icon(
            onPressed: widget.auth.logOut,
            icon: const Icon(Icons.logout),
            label: const Text('Sign out'),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Signed in as ${widget.user.email ?? widget.user.uid}',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            _ProgressCard(progress: _progress),
            const SizedBox(height: 12),
            _ChallengeCard(
              challenge: _challenge,
              onRetry: () =>
                  setState(() => _challenge = _challenges.loadToday()),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _completing ? null : _complete,
              icon: const Icon(Icons.check_circle_outline),
              label: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child:
                    Text(_completing ? 'Completing…' : 'Complete challenge'),
              ),
            ),
            if (_rewardMessage != null) ...[
              const SizedBox(height: 8),
              _StatusText(text: _rewardMessage!, isError: _rewardFailed),
            ],
            const Divider(height: 40),
            Text('Quest Coach', style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              'The coach can read your quest to give a hint. It cannot '
              'change your points or complete the challenge for you.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _question,
              maxLength: maxQuestionLength,
              minLines: 1,
              maxLines: 3,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _askCoach(),
              decoration: const InputDecoration(
                labelText: 'Ask the Quest Coach for a hint',
                border: OutlineInputBorder(),
              ),
            ),
            OutlinedButton.icon(
              onPressed: _asking ? null : _askCoach,
              icon: const Icon(Icons.lightbulb_outline),
              label: Text(_asking ? 'Thinking…' : 'Get hint'),
            ),
            if (_coachReply != null) ...[
              const SizedBox(height: 12),
              // Rendered as plain text only; nothing in a reply is executed.
              _StatusText(text: _coachReply!, isError: _coachFailed),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.progress});

  final Stream<Progress> progress;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: StreamBuilder<Progress>(
          stream: progress,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              debugPrint('Progress read failed: ${snapshot.error}');
              return const Text('Could not load your progress.');
            }
            if (!snapshot.hasData) {
              return const Text('Loading your progress…');
            }
            final value = snapshot.data!;
            return Row(
              children: [
                Icon(
                  value.completed
                      ? Icons.emoji_events
                      : Icons.emoji_events_outlined,
                  size: 36,
                  color: value.completed
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${value.points} points',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text('Badge: ${badgeName(value.badgeId)}'),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ChallengeCard extends StatelessWidget {
  const _ChallengeCard({required this.challenge, required this.onRetry});

  final Future<Challenge> challenge;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: FutureBuilder<Challenge>(
          future: challenge,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 12),
                  Text("Loading today's challenge…"),
                ],
              );
            }
            if (snapshot.hasError) {
              debugPrint('Challenge read failed: ${snapshot.error}');
              final missing = snapshot.error is ChallengeMissingException;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    missing
                        ? "Today's challenge has not been published yet."
                        : "Could not load today's challenge. Check your "
                            'connection and try again.',
                  ),
                  TextButton(onPressed: onRetry, child: const Text('Retry')),
                ],
              );
            }
            final value = snapshot.data!;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Today's challenge", style: theme.textTheme.labelLarge),
                const SizedBox(height: 4),
                Text(value.title, style: theme.textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text(value.prompt, style: theme.textTheme.bodyLarge),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _StatusText extends StatelessWidget {
  const _StatusText({required this.text, required this.isError});

  final String text;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isError ? scheme.errorContainer : scheme.secondaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: SelectableText(
          text,
          style: TextStyle(
            color:
                isError ? scheme.onErrorContainer : scheme.onSecondaryContainer,
          ),
        ),
      ),
    );
  }
}
