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

### Client-Side Security
- **No server secrets**: API keys and server credentials are never stored in the client binary. Sensitive operations are handled by Supabase Edge Functions.
- **Encrypted storage**: All sensitive data (tokens, user preferences) is stored using `flutter_secure_storage`, backed by iOS Keychain and Android Keystore.
- **Certificate pinning**: Planned for production releases.

### Backend Security
- **Row-Level Security**: All database access is governed by Supabase RLS policies.
- **Edge Function proxying**: Google Maps routing and push notification dispatch are handled server-side to avoid exposing service keys to the client.
- **Rate limiting**: Server-side rate limits protect Edge Functions from abuse.

### Build & Deployment
- **Environment isolation**: `--dart-define` injects environment-specific configuration at build time. Secrets are passed via CI/CD secrets, never committed to the repository.
- **Dependency pinning**: All dependencies use caret version constraints for reproducible builds.
- **Static analysis**: `flutter analyze` with hardened lint rules runs on every PR.

### Error Handling
- **Three-layer error catching**: `FlutterError.onError` (widget errors), `PlatformDispatcher.instance.onError` (platform errors), and `runZonedGuarded` (zone-level fallback) -- following Flutter's official error handling documentation.
- **No sensitive data in logs**: Error messages are sanitised before logging.

### Data Handling
- **Minimal data collection**: The app only collects data necessary for its core functionality.
- **No analytics SDKs**: No third-party analytics or tracking libraries are included.
- **Local-first caching**: Cached data uses platform-secure storage mechanisms.

## Dependencies

We regularly review dependencies for known vulnerabilities. If you notice an outdated dependency with a known CVE, please open an issue or submit a PR.
