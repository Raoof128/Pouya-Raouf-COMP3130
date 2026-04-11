import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:mq_navigation/app/theme/mq_colors.dart';
import 'package:mq_navigation/app/theme/mq_spacing.dart';

void main() {
  group('MqColors', () {
    test('brand red matches web token', () {
      expect(MqColors.red, const Color(0xFFA6192E));
    });

    test('alabaster matches web token', () {
      expect(MqColors.alabaster, const Color(0xFFEDEADE));
    });
  });

  group('MqSpacing', () {
    test('minimum tap target is 48dp', () {
      expect(MqSpacing.minTapTarget, 48);
    });

    test('space4 is 16', () {
      expect(MqSpacing.space4, 16);
    });
  });
}
