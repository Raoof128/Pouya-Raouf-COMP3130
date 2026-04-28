# Security Posture (OWASP 2026 Standards)

## Authentication & Authorization
- **Identity**: Supabase Auth (GoTrue) with PKCE flow for all mobile auth cycles.
- **Authorization**: Row-Level Security (RLS) is enforced at the database layer. No client-side filtering of restricted data.
- **App Lock**: Optional biometric gate (FaceID/TouchID) using `local_auth` for vault-level preference protection.

## Data Security
- **At Rest**: Sensitive keys (Supabase tokens, session data) are stored in the hardware-backed **iOS Keychain** or **Android Keystore** via `flutter_secure_storage`.
- **In Transit**: TLS 1.3 enforced for all Supabase and TfNSW API traffic. Pinning implemented for production endpoints.

## API & Edge Security
- **Proxy Pattern**: All third-party SDK keys (Google Maps, OpenRouteService) are stored as secrets in **Supabase Edge Functions**. The mobile client never holds server-side keys.
- **Throttling**: Rate limiting is applied per UserID and IP at the Edge to prevent scrapers or DDoS on the routing proxy.
- **Input Validation**: All coordinate and route requests are validated against MQ campus bounding boxes before processing.

## 2026 Offensive Security Mitigation
- **Deep Link Protection**: Intent filters are restricted to verified `mq.edu.au` domains using App Links (Android) and Universal Links (iOS) to prevent intent hijacking.
- **Script Injection**: All HTML-rich routing instructions are sanitized via `NavInstruction` normalization to prevent XSS in WebView or text components.
