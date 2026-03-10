import 'package:flutter/material.dart';

/// Calendar page — placeholder, full implementation in Phase 3.
class CalendarPage extends StatelessWidget {
  const CalendarPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Calendar')),
      body: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_month_outlined, size: 64),
            SizedBox(height: 16),
            Text('Calendar — Coming in Phase 3'),
          ],
        ),
      ),
    );
  }
}
