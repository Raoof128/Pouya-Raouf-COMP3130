# Contributing to MQ Navigation

Thank you for your interest in contributing. This document outlines the workflow and standards expected for all contributions.

## Getting Started

1. **Fork & clone** the repository.
2. Install [Flutter](https://docs.flutter.dev/get-started/install) (stable channel, SDK ^3.11.0).
3. Navigate to the Flutter project:

```bash
cd MQ_Navigation
flutter pub get
flutter gen-l10n
```

4. Run with environment variables:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key \
  --dart-define=APP_ENV=development
```

## Development Workflow

### Branch Naming

| Type | Pattern | Example |
|------|---------|---------|
| Feature | `feature/<short-description>` | `feature/auth-mfa-flow` |
| Bug fix | `fix/<short-description>` | `fix/login-redirect-loop` |
| Chore | `chore/<short-description>` | `chore/update-deps` |

### Before Submitting a PR

Run the full check suite from `MQ_Navigation/`:

```bash
./scripts/check.sh --quick
```

This executes:
- `flutter pub get` — dependency resolution
- `dart format --set-exit-if-changed lib/ test/ tools/` — format check
- `flutter analyze --no-fatal-infos` — static analysis
- `flutter test` — all unit and widget tests
- `flutter gen-l10n` — localisation generation

All checks must pass before a PR will be reviewed.

### Commit Messages

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
feat: add MFA enrolment screen
fix: resolve calendar date picker crash on RTL locales
chore: pin intl dependency to ^0.20.2
test: add widget tests for MqInput validation
```

## Architecture Rules

- **Feature-first**: each feature lives in `lib/features/<name>/` with `data/`, `domain/`, and `presentation/` layers.
- **State management**: use Riverpod providers exclusively. No `setState`, no Bloc.
- **Routing**: use `go_router` named routes via `RouteNames` constants.
- **Design tokens**: use `MqColors`, `MqTypography`, `MqSpacing` — no magic numbers or hardcoded colors.
- **Accessibility**: all interactive elements must have semantic labels and meet the 48dp minimum tap target.
- **RTL support**: use `EdgeInsetsDirectional` and `TextDirection`-aware layouts.
- **No server secrets**: API keys and server credentials never go in the client binary.

## Code Style

- Follow the rules in `analysis_options.yaml`.
- Prefer `const` constructors where possible.
- Prefer `final` local variables.
- Prefer single quotes for strings.
- Run `dart format .` before committing.

## Testing

- Every new widget should have at least one `testWidgets` test.
- Every new domain entity should have `fromJson`/`toJson` round-trip tests.
- Every new provider should have unit tests covering its state transitions.
- Test files mirror the `lib/` directory structure under `test/`.

## Reporting Issues

Open an issue on the GitHub repository with:
- Steps to reproduce
- Expected vs actual behaviour
- Device/OS/Flutter version
- Screenshots or logs if applicable
