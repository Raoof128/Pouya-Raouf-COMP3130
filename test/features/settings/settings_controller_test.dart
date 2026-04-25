import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mq_navigation/features/map/domain/entities/map_renderer_type.dart';
import 'package:mq_navigation/features/settings/data/repositories/settings_repository.dart';
import 'package:mq_navigation/features/settings/presentation/controllers/settings_controller.dart';
import 'package:mq_navigation/shared/models/user_preferences.dart';

class MockSettingsRepository extends Mock implements SettingsRepository {}

void main() {
  late MockSettingsRepository repository;

  setUp(() {
    repository = MockSettingsRepository();
    // Default mock behavior
    when(
      () => repository.loadPreferences(),
    ).thenAnswer((_) async => const UserPreferences());
    registerFallbackValue(const UserPreferences());
    when(() => repository.savePreferences(any())).thenAnswer(
      (invocation) async =>
          invocation.positionalArguments[0] as UserPreferences,
    );
    when(() => repository.wipeAllLocalData()).thenAnswer((_) async {});
  });

  ProviderContainer createContainer() {
    final container = ProviderContainer(
      overrides: [settingsRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('SettingsController wiring tests', () {
    test('updateDefaultRenderer updates state and repository', () async {
      final container = createContainer();
      final controller = container.read(settingsControllerProvider.notifier);

      await controller.updateDefaultRenderer(MapRendererType.google);

      final state = container.read(settingsControllerProvider).value;
      expect(state?.defaultRenderer, MapRendererType.google);
      verify(
        () => repository.savePreferences(
          any(
            that: isA<UserPreferences>().having(
              (p) => p.defaultRenderer,
              'defaultRenderer',
              MapRendererType.google,
            ),
          ),
        ),
      ).called(1);
    });

    test('updateHapticsEnabled updates state and repository', () async {
      final container = createContainer();
      final controller = container.read(settingsControllerProvider.notifier);

      await controller.updateHapticsEnabled(false);

      final state = container.read(settingsControllerProvider).value;
      expect(state?.hapticsEnabled, isFalse);
      verify(
        () => repository.savePreferences(
          any(
            that: isA<UserPreferences>().having(
              (p) => p.hapticsEnabled,
              'hapticsEnabled',
              isFalse,
            ),
          ),
        ),
      ).called(1);
    });

    test('updateHighContrastMap updates state and repository', () async {
      final container = createContainer();
      final controller = container.read(settingsControllerProvider.notifier);

      await controller.updateHighContrastMap(true);

      final state = container.read(settingsControllerProvider).value;
      expect(state?.highContrastMap, isTrue);
      verify(
        () => repository.savePreferences(
          any(
            that: isA<UserPreferences>().having(
              (p) => p.highContrastMap,
              'highContrastMap',
              isTrue,
            ),
          ),
        ),
      ).called(1);
    });

    test('updateCommutePreferences updates state and repository', () async {
      final container = createContainer();
      final controller = container.read(settingsControllerProvider.notifier);

      await controller.updateCommutePreferences(
        commuteMode: 'metro',
        favoriteDirection: 'Tallawong',
        favoriteRoute: 'M1',
        favoriteStopId: '10101403',
        favoriteStopName: 'Macquarie University Station',
      );

      final state = container.read(settingsControllerProvider).value;
      expect(state?.commuteMode, 'metro');
      expect(state?.favoriteDirection, 'Tallawong');
      expect(state?.favoriteRoute, 'M1');
      expect(state?.favoriteStopId, '10101403');
      expect(state?.favoriteStopName, 'Macquarie University Station');
      verify(
        () => repository.savePreferences(
          any(
            that: isA<UserPreferences>()
                .having((p) => p.commuteMode, 'commuteMode', 'metro')
                .having(
                  (p) => p.favoriteDirection,
                  'favoriteDirection',
                  'Tallawong',
                )
                .having((p) => p.favoriteRoute, 'favoriteRoute', 'M1')
                .having((p) => p.favoriteStopId, 'favoriteStopId', '10101403')
                .having(
                  (p) => p.favoriteStopName,
                  'favoriteStopName',
                  'Macquarie University Station',
                ),
          ),
        ),
      ).called(1);
    });

    test(
      'updateCommutePreferences normalizes unsupported commute mode',
      () async {
        final container = createContainer();
        final controller = container.read(settingsControllerProvider.notifier);

        await controller.updateCommutePreferences(commuteMode: 'ferry');

        final state = container.read(settingsControllerProvider).value;
        expect(state?.commuteMode, 'none');
        verify(
          () => repository.savePreferences(
            any(
              that: isA<UserPreferences>().having(
                (p) => p.commuteMode,
                'commuteMode',
                'none',
              ),
            ),
          ),
        ).called(1);
      },
    );

    test('updateQuietHours settings updates state and repository', () async {
      final container = createContainer();
      final controller = container.read(settingsControllerProvider.notifier);

      await controller.updateQuietHoursEnabled(true);
      await controller.updateQuietHoursStart('22:00');
      await controller.updateQuietHoursEnd('07:00');

      final state = container.read(settingsControllerProvider).value;
      expect(state?.quietHoursEnabled, isTrue);
      expect(state?.quietHoursStart, '22:00');
      expect(state?.quietHoursEnd, '07:00');

      // verify 3 separate calls for the 3 updates
      verify(() => repository.savePreferences(any())).called(3);
    });

    test('wipeAllLocalData calls repository and resets state', () async {
      final container = createContainer();
      final controller = container.read(settingsControllerProvider.notifier);

      // Change a value first
      await controller.updateLowDataMode(true);
      expect(
        container.read(settingsControllerProvider).value?.lowDataMode,
        isTrue,
      );

      // Setup repository to return defaults on next load
      when(
        () => repository.loadPreferences(),
      ).thenAnswer((_) async => const UserPreferences());

      await controller.wipeAllLocalData();

      verify(() => repository.wipeAllLocalData()).called(1);
      final state = container.read(settingsControllerProvider).value;
      expect(state?.lowDataMode, isFalse); // Reset to default
    });
  });
}
