import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mq_navigation/core/config/env_config.dart';
import 'package:mq_navigation/core/error/error_boundary.dart';
import 'package:mq_navigation/core/logging/app_logger.dart';
import 'package:mq_navigation/features/notifications/data/datasources/fcm_service.dart';

/// Initialises all critical services before the widget tree mounts.
Future<void> bootstrap(Widget Function() appBuilder) async {
  // Catch errors outside the Flutter framework.
  await runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // Install global error handlers.
      installErrorHandlers();
      // Validate required env vars.
      EnvConfig.validate();

      if (!kIsWeb) {
        try {
          await Firebase.initializeApp();
          FirebaseMessaging.onBackgroundMessage(
            firebaseMessagingBackgroundHandler,
          );
          AppLogger.info('Firebase initialised');
        } catch (error, stackTrace) {
          AppLogger.warning(
            'Firebase initialisation skipped. Check native Firebase service files.',
            error,
            stackTrace,
          );
        }
      }

      // Initialise Supabase.
      await Supabase.initialize(
        url: EnvConfig.supabaseUrl,
        anonKey: EnvConfig.supabaseAnonKey,
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
        ),
      );

      AppLogger.info('Supabase initialised', EnvConfig.appEnv);

      runApp(ProviderScope(child: ErrorBoundary(child: appBuilder())));
    },
    (error, stack) {
      AppLogger.error('Unhandled zone error', error, stack);
    },
  );
}
