# Contributing Guidelines

## Development Workflow
We maintain a strict quality gate to ensure campus-ready stability.

1.  **Branching**: `feature/` or `fix/` prefixes.
2.  **Testing**: New logic MUST be covered by unit/widget tests.
3.  **Verification**: 
    ```bash
    ./scripts/check.sh --quick
    ```

## Definition of Done
- All **154 tests** pass.
- No new linter warnings in `lib/`.
- `CONTRIBUTING.md` and `README.md` updated if feature surface changes.
- RTL layout verified for Arabic (ar) and Farsi (fa) locales.

## Design Standards
Use the `MqSpacing` tokens for all layouts. **Magic numbers are prohibited.** 
Target 48x48dp for all interactive surfaces to meet 2026 mobile accessibility standards.
