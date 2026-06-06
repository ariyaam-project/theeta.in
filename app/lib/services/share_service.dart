import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import 'instagram_link.dart';

/// Listens for content shared into the app (Instagram "Share to Theta")
/// and emits parsed Instagram links.
///
/// Native mobile share targets save into an inbox without opening the app.
/// The inbox is consumed when Theta starts or resumes. The plugin stream is
/// retained for compatibility with shares delivered by older app installs.
class ShareService with WidgetsBindingObserver {
  static const _inbox = MethodChannel('com.example.app/share_inbox');

  final _controller = StreamController<InstagramLink>.broadcast();
  StreamSubscription<List<SharedMediaFile>>? _sub;
  bool _consumingInbox = false;

  Stream<InstagramLink> get links => _controller.stream;

  Future<void> init() async {
    WidgetsBinding.instance.addObserver(this);
    _sub = ReceiveSharingIntent.instance.getMediaStream().listen(
      _handle,
      onError: (_) {},
    );

    await _consumeNativeInbox();

    final initial = await ReceiveSharingIntent.instance.getInitialMedia();
    _handle(initial);

    // Mark the initial intent consumed so it is not re-delivered.
    ReceiveSharingIntent.instance.reset();
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

  void _handle(List<SharedMediaFile> files) {
    for (final f in files) {
      final candidate = (f.message != null && f.message!.isNotEmpty)
          ? '${f.message} ${f.path}'
          : f.path;
      final link = parseInstagram(candidate);
      if (link != null) _controller.add(link);
    }
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sub?.cancel();
    _controller.close();
  }
}
