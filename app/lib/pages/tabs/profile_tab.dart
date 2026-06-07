import 'package:flutter/material.dart';

import '../../state/app_state.dart';
import '../../theme.dart';
import '../../widgets/ui.dart';

/// Account summary + logout.
class ProfileTab extends StatelessWidget {
  final AppState state;
  const ProfileTab({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: state,
      builder: (context, _) {
        final name = state.displayName;
        final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
        return ListView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
          children: [
            const SectionTitle(title: 'Profile'),
            const SizedBox(height: 14),
            ShadowCard(
              color: ink,
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: gold,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      initial,
                      style: const TextStyle(
                        color: ink,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        if (state.email.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            state.email,
                            style: const TextStyle(
                              color: Color(0xFFFFE3B5),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _stat('Saved', '${state.reels.length}'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _stat('Resolved', '${state.located.length}'),
                ),
              ],
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: state.busy ? null : () => _confirmLogout(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: peach,
                  side: BorderSide(color: peach.withValues(alpha: 0.6), width: 1.5),
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                icon: const Icon(Icons.logout),
                label: const Text(
                  'Log out',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _stat(String label, String value) {
    return ShadowCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Colors.black54,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: paper,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('Log out?'),
        content: const Text('You will need to sign in again to save reels.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (ok == true) await state.logout();
  }
}
