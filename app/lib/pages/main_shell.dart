import 'dart:async';

import 'package:flutter/material.dart';

import '../services/instagram_link.dart';
import '../services/share_service.dart';
import '../state/app_state.dart';
import '../theme.dart';
import 'tabs/analytics_tab.dart';
import 'tabs/food_list_tab.dart';
import 'tabs/map_tab.dart';
import 'tabs/profile_tab.dart';

/// Logged-in shell: bottom-nav over Analytics / Map / Food / Profile.
/// Owns the native share-inbox listener so shared reels save from any tab.
class MainShell extends StatefulWidget {
  final AppState state;
  const MainShell({super.key, required this.state});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final _share = ShareService();
  StreamSubscription<InstagramLink>? _sub;
  Future<void> _queue = Future.value();
  static const _homeTab = 0;
  static const _mapTab = 1;
  int _index = _homeTab;

  AppState get _state => widget.state;

  @override
  void initState() {
    super.initState();
    _sub = _share.links.listen(_onShared);
    _share.init();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _share.dispose();
    super.dispose();
  }

  void _onShared(InstagramLink link) {
    _queue = _queue.then((_) => _handleShared(link));
  }

  Future<void> _handleShared(InstagramLink link) async {
    final err = await _state.addLink(link.url);
    if (!mounted) return;
    _snack(err == null ? 'Reel saved for processing' : 'Could not save reel: $err');
    if (err == null) setState(() => _index = _homeTab);
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      FoodListTab(
        state: _state,
        onOpenMap: () {
          setState(() => _index = _mapTab);
          _state.refreshAll();
        },
      ),
      MapTab(state: _state),
      AnalyticsTab(state: _state),
      ProfileTab(state: _state),
    ];

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(child: IndexedStack(index: _index, children: tabs)),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: paper,
          border: Border(top: BorderSide(color: ink.withValues(alpha: 0.06))),
          boxShadow: [
            BoxShadow(
              color: ink.withValues(alpha: 0.06),
              blurRadius: 24,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _index,
          onTap: (i) {
            setState(() => _index = i);
            // Refresh spot data whenever the Map tab is opened.
            if (i == _mapTab) _state.refreshAll();
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: paper,
          elevation: 0,
          selectedItemColor: accent,
          unselectedItemColor: muted,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w800),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.map_outlined),
              activeIcon: Icon(Icons.map),
              label: 'Map',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.insights_outlined),
              activeIcon: Icon(Icons.insights),
              label: 'Analytics',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
