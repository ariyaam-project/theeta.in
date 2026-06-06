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
  int _index = 0;

  AppState get _state => widget.state;

  static const _foodTab = 2;

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
    if (err == null) setState(() => _index = _foodTab);
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      AnalyticsTab(state: _state),
      MapTab(state: _state),
      FoodListTab(state: _state),
      ProfileTab(state: _state),
    ];

    return Scaffold(
      body: SafeArea(child: IndexedStack(index: _index, children: tabs)),
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: ink, width: 2)),
        ),
        child: BottomNavigationBar(
          currentIndex: _index,
          onTap: (i) => setState(() => _index = i),
          type: BottomNavigationBarType.fixed,
          backgroundColor: paper,
          selectedItemColor: accent,
          unselectedItemColor: Colors.black45,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w800),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.insights_outlined),
              activeIcon: Icon(Icons.insights),
              label: 'Analytics',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.map_outlined),
              activeIcon: Icon(Icons.map),
              label: 'Map',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.restaurant_menu_outlined),
              activeIcon: Icon(Icons.restaurant_menu),
              label: 'Food',
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
