import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'instagram_link.dart';

/// Listens for content shared into the app (Instagram "Share to Theeta")
/// and emits parsed Instagram links.
///
/// Native mobile share targets save into an inbox without opening the app.
/// The inbox is consumed when Theeta starts or resumes.
class ShareService with WidgetsBindingObserver {
  static const _inbox = MethodChannel('com.example.app/share_inbox');

  final _controller = StreamController<InstagramLink>.broadcast();
  bool _consumingInbox = false;

  Stream<InstagramLink> get links => _controller.stream;

  Future<void> init() async {
    WidgetsBinding.instance.addObserver(this);
    await _consumeNativeInbox();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _consumeNativeInbox();
    }
  }

  Future<void> _consumeNativeInbox() async {
    if (_consumingInbox) return;
    _consumingInbox = true;
    try {
      final pending = await _inbox.invokeListMethod<String>('consume') ?? [];
      for (final value in pending) {
        final link = parseInstagram(value);
        if (link != null) _controller.add(link);
      }
    } on MissingPluginException {
      // Desktop and web builds do not provide a native share inbox.
    } finally {
      _consumingInbox = false;
    }
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.close();
  }
}
