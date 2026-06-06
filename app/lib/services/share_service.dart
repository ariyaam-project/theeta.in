import 'dart:async';

import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import 'instagram_link.dart';

/// Listens for content shared into the app (Instagram "Share to Theta")
/// and emits parsed Instagram links.
///
/// Handles both:
///  - cold start (app launched via the share sheet) -> getInitialMedia
///  - warm share (app already open) -> getMediaStream
class ShareService {
  final _controller = StreamController<InstagramLink>.broadcast();
  StreamSubscription<List<SharedMediaFile>>? _sub;

  Stream<InstagramLink> get links => _controller.stream;

  Future<void> init() async {
    _sub = ReceiveSharingIntent.instance
        .getMediaStream()
        .listen(_handle, onError: (_) {});

    final initial = await ReceiveSharingIntent.instance.getInitialMedia();
    _handle(initial);

    // Mark the initial intent consumed so it is not re-delivered.
    ReceiveSharingIntent.instance.reset();
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
    _sub?.cancel();
    _controller.close();
  }
}
