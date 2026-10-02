import 'package:flutter/material.dart';

import 'auth_scope.dart';

/// Shown above every screen during the last minute before an inactivity sign-out.
class IdleTimeoutWarning extends StatelessWidget {
  const IdleTimeoutWarning({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);
    final secondsLeft = auth.idleWarningSecondsLeft;
    if (secondsLeft == null || !auth.isAuthenticated) {
      return const SizedBox.shrink();
    }
    final theme = Theme.of(context);

    return Positioned.fill(
      child: Material(
        color: Colors.black54,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              margin: const EdgeInsets.all(24),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.timer_outlined, size: 40, color: Color(0xFFB45309)),
                    const SizedBox(height: 12),
                    Text('Are you still there?', style: theme.textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text(
                      'For your security, you will be signed out in $secondsLeft seconds due to inactivity.',
                      style: theme.textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(onPressed: auth.signOut, child: const Text('Sign out')),
                        const SizedBox(width: 8),
                        FilledButton(onPressed: auth.staySignedIn, child: const Text('Stay signed in')),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
