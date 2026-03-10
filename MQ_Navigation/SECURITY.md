# Security Policy

## Reporting a Vulnerability

If you discover a security vulnerability in this project, please report it responsibly.

**Do NOT open a public GitHub issue for security vulnerabilities.**

Instead, email the maintainers directly with:
- A description of the vulnerability
- Steps to reproduce
- Potential impact assessment
- Suggested fix (if any)

We will acknowledge receipt within 48 hours and provide a detailed response within 7 days.

## Supported Versions

| Version | Supported |
|---------|-----------|
| 1.x.x   | Yes       |

## Security Practices

This project follows these security principles:

### Client-Side Security
- **No server secrets**: API keys and server credentials are never stored in the client binary. Only `ORS_API_KEY` and `GOOGLE_MAPS_API_KEY` are client-side.
- **Encrypted storage**: All sensitive data (tokens, user preferences) is stored using `flutter_secure_storage`, which uses iOS Keychain and Android Keystore.
- **Biometric gates**: Optional biometric authentication via `local_auth` for sensitive operations.

### Authentication
- **Guest mode**: The app runs in guest mode for Open Day — no login required.
- **PKCE flow**: OAuth uses Proof Key for Code Exchange (PKCE) for secure token exchange.
- **Row-Level Security**: All database access is governed by Supabase RLS policies.
- **Session management**: Sessions are managed by Supabase Auth with automatic token refresh.
- **MFA support**: Multi-factor authentication is supported and can be enforced.

### Build & Deployment
- **Environment isolation**: `--dart-define` injects environment-specific configuration at build time. Secrets are passed via CI/CD secrets, never committed.
- **Dependency pinning**: All dependencies use caret version constraints for reproducible builds.
- **Static analysis**: `flutter analyze` runs on every PR to catch potential issues.

### Data Handling
- **Minimal data collection**: The app only collects data necessary for its core functionality.
- **No analytics SDKs**: No third-party analytics or tracking libraries are included.
- **Local-first caching**: Cached data uses platform-secure storage mechanisms.

## Dependencies

We regularly review dependencies for known vulnerabilities. If you notice an outdated dependency with a known CVE, please open an issue or submit a PR.
