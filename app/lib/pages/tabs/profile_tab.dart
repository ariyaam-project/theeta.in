import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../state/app_state.dart';
import '../../theme.dart';
import '../../widgets/ui.dart';

const _appVersion = '1.0.0';
const _webBase = 'https://theeta.in';

/// Account summary, settings links + logout.
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
            const SizedBox(height: 24),
            const SectionTitle(title: 'Discover'),
            const SizedBox(height: 12),
            _group(context, [
              _Item(Icons.public_outlined, 'Theeta on the web',
                  () => _open(context, _webBase)),
              _Item(Icons.camera_alt_outlined, 'Follow on Instagram',
                  () => _open(context, 'https://instagram.com/theetadotin')),
            ]),
            const SizedBox(height: 22),
            const SectionTitle(title: 'About & legal'),
            const SizedBox(height: 12),
            _group(context, [
              _Item(Icons.info_outline, 'About Theeta',
                  () => _showAbout(context)),
              _Item(Icons.description_outlined, 'Terms of Service',
                  () => _open(context, '$_webBase/terms')),
              _Item(Icons.privacy_tip_outlined, 'Privacy Policy',
                  () => _open(context, '$_webBase/privacy')),
              _Item(Icons.mail_outline, 'Contact us',
                  () => _open(context, 'mailto:contact@theeta.in')),
              _Item(Icons.verified_outlined, 'Version', null,
                  trailing: _appVersion),
            ]),
            const SizedBox(height: 24),
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

  Widget _group(BuildContext context, List<_Item> items) {
    return ShadowCard(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            for (var i = 0; i < items.length; i++) ...[
              _row(items[i]),
              if (i < items.length - 1)
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: Color(0x0F000000),
                  indent: 16,
                  endIndent: 16,
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _row(_Item item) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: softPurple,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(item.icon, color: accent, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  item.label,
                  style: const TextStyle(
                    color: ink,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
              if (item.trailing != null)
                Text(
                  item.trailing!,
                  style: const TextStyle(color: muted, fontWeight: FontWeight.w700),
                )
              else if (item.onTap != null)
                const Icon(Icons.chevron_right, color: Colors.black26),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _open(BuildContext context, String url) async {
    final ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open link')),
      );
    }
  }

  void _showAbout(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Theeta',
      applicationVersion: _appVersion,
      applicationLegalese: '© 2026 Theeta',
      children: const [
        SizedBox(height: 10),
        Text('Turn Instagram food reels into real, mapped food spots.'),
      ],
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

class _Item {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final String? trailing;
  const _Item(this.icon, this.label, this.onTap, {this.trailing});
}
