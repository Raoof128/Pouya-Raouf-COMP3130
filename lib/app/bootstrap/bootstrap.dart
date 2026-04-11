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
///
/// Uses [runZonedGuarded] to catch any asynchronous errors that escape the
/// normal Flutter framework boundaries. This ensures errors during early startup
/// or background processes are logged correctly rather than crashing silently.
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
          // Native platforms require Firebase for push notifications.
          // This must happen before any FCM services are initialized.
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
      // This is the primary backend connection for map routing and notifications.
      // We use PKCE auth flow for better security on mobile clients.
      await Supabase.initialize(
        url: EnvConfig.supabaseUrl,
        anonKey: EnvConfig.supabaseAnonKey,
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
        ),
      );

      AppLogger.info('Supabase initialised', EnvConfig.appEnv);

      // Start the app wrapped in Riverpod's ProviderScope for state management
      // and a top-level ErrorBoundary to catch rendering exceptions.
      runApp(ProviderScope(child: ErrorBoundary(child: appBuilder())));
    },
    (error, stack) {
      AppLogger.error('Unhandled zone error', error, stack);
    },
  );
}
