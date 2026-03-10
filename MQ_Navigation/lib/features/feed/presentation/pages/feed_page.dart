import 'package:flutter/material.dart';

/// Events feed page — placeholder, full implementation in Phase 4.
class FeedPage extends StatelessWidget {
  const FeedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Events Feed')),
      body: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.feed_outlined, size: 64),
            SizedBox(height: 16),
            Text('Events Feed — Coming in Phase 4'),
          ],
        ),
      ),
    );
  }
}
