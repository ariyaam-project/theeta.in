import 'package:flutter/material.dart';

import '../models/reel.dart';

class ReelTile extends StatelessWidget {
  final Reel reel;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  const ReelTile({
    super.key,
    required this.reel,
    required this.onOpen,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const CircleAvatar(child: Icon(Icons.play_arrow)),
      title: Text(
        reel.shortcode,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(reel.url, maxLines: 1, overflow: TextOverflow.ellipsis),
          Text(reel.timeAgo, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
      isThreeLine: true,
      trailing: PopupMenuButton<String>(
        onSelected: (v) {
          if (v == 'open') onOpen();
          if (v == 'delete') onDelete();
        },
        itemBuilder: (_) => const [
          PopupMenuItem(value: 'open', child: Text('Open in Instagram')),
          PopupMenuItem(value: 'delete', child: Text('Delete')),
        ],
      ),
      onTap: onOpen,
    );
  }
}
