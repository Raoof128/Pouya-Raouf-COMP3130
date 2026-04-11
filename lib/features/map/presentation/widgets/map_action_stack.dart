import 'package:flutter/material.dart';
import 'package:mq_navigation/app/theme/mq_spacing.dart';

class MapActionStack extends StatelessWidget {
  const MapActionStack({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < children.length; index++) ...[
          children[index],
          if (index != children.length - 1)
            const SizedBox(height: MqSpacing.space2),
        ],
      ],
    );
  }
}
