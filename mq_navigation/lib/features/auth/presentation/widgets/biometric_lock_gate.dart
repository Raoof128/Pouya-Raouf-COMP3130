import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mq_navigation/app/theme/mq_spacing.dart';
import 'package:mq_navigation/core/error/app_exception.dart' as app_exception;
import 'package:mq_navigation/core/security/biometric_service.dart';
import 'package:mq_navigation/features/settings/presentation/controllers/settings_controller.dart';
import 'package:mq_navigation/shared/extensions/context_extensions.dart';
import 'package:mq_navigation/shared/providers/auth_provider.dart';
import 'package:mq_navigation/shared/widgets/mq_button.dart';

class BiometricLockGate extends ConsumerStatefulWidget {
  const BiometricLockGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<BiometricLockGate> createState() => _BiometricLockGateState();
}

class _BiometricLockGateState extends ConsumerState<BiometricLockGate>
    with WidgetsBindingObserver {
  bool _isLocked = false;
  bool _isUnlocking = false;
  bool _hasBypassedUnavailableProtection = false;
  bool _wasProtectionEnabled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _shouldProtect) {
      setState(() {
        _isLocked = true;
      });
    }
  }

  bool get _shouldProtect {
    final preferences = ref.read(settingsControllerProvider).value;
    final session = ref.read(authProvider).value;
    return !_hasBypassedUnavailableProtection &&
        session != null &&
        (preferences?.biometricLockEnabled ?? false);
  }

  Future<void> _unlock() async {
    if (!_shouldProtect || _isUnlocking) {
      return;
    }
    setState(() {
      _isUnlocking = true;
    });

    try {
      final success = await ref
          .read(biometricServiceProvider)
          .authenticate(reason: 'Unlock MQ Navigation');

      if (!mounted) {
        return;
      }

      setState(() {
        _isUnlocking = false;
        _isLocked = !success;
      });
    } on app_exception.UnsupportedException catch (error) {
      final saveMessage = await ref
          .read(settingsControllerProvider.notifier)
          .updateBiometricLockEnabled(false);
      if (!mounted) {
        return;
      }

      setState(() {
        _hasBypassedUnavailableProtection = true;
        _isUnlocking = false;
        _isLocked = false;
        _wasProtectionEnabled = false;
      });
      context.showSnackBar(
        saveMessage ??
            '${error.message} Biometric lock has been disabled for this session.',
        isError: true,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isUnlocking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final preferences = ref.watch(settingsControllerProvider).value;
    final session = ref.watch(authProvider).value;
    final shouldProtect =
        !_hasBypassedUnavailableProtection &&
        session != null &&
        (preferences?.biometricLockEnabled ?? false);

    if (!shouldProtect) {
      if (session == null || !(preferences?.biometricLockEnabled ?? false)) {
        _hasBypassedUnavailableProtection = false;
      }
      _wasProtectionEnabled = false;
      if (_isLocked) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _isLocked = false;
            });
          }
        });
      }
      return widget.child;
    }

    var showLockedOverlay = _isLocked;
    if (!_wasProtectionEnabled) {
      _wasProtectionEnabled = true;
      showLockedOverlay = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _isLocked = true;
          });
        }
      });
    }

    if (!showLockedOverlay) {
      return widget.child;
    }

    return Stack(
      children: [
        widget.child,
        Positioned.fill(
          child: ColoredBox(
            color: Theme.of(
              context,
            ).scaffoldBackgroundColor.withValues(alpha: 0.94),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(MqSpacing.space6),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.lock_outline, size: 56),
                        const SizedBox(height: MqSpacing.space4),
                        Text(
                          'App locked',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: MqSpacing.space2),
                        Text(
                          'Use biometrics to continue to your secure workspace.',
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: MqSpacing.space6),
                        MqButton(
                          label: 'Unlock with biometrics',
                          icon: Icons.fingerprint,
                          isLoading: _isUnlocking,
                          onPressed: _unlock,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
