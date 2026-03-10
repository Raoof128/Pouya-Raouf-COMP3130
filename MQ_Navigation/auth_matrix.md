# Auth Flow Matrix

Authentication flow for MQ Navigation (Open Day guest mode).

## Current Auth Model

The app runs in **guest mode** for Macquarie University Open Day. No login is required — all users can access the full app immediately.

| Method | Implementation | Status |
|--------|---------------|--------|
| Session restore | `supabase_flutter` auto-restore from Keychain/Keystore | Active |
| Guest access | No auth required — splash redirects to home | Active |

## Auth State Machine

```
App Launch
  │
  └─ /splash → /home (automatic redirect, no login required)
```

## Route Guards (go_router redirect)

| Guard | Condition | Redirects To |
|-------|-----------|-------------|
| SplashGuard | Auth state loaded | `/home` |

## Deep Links

| Flow | Callback URL | Platform Config |
|------|-------------|-----------------|
| Custom scheme | `io.mqnavigation://callback` | iOS: URL scheme in Info.plist; Android: Intent filter in AndroidManifest.xml |

## Security Measures

| Measure | Implementation | Status |
|---------|---------------|--------|
| Encrypted storage | flutter_secure_storage (Keychain/Keystore) | Active |
| Biometric gate | local_auth for sensitive actions | Available |
| RLS enforcement | Supabase Row-Level Security on all queries | Active |

## Not Implemented (web app only)

The following auth features exist in the web app but are not in the Flutter app:

- Email/password signup & login
- Email verification
- Password reset
- Google OAuth
- TOTP/SMS MFA
- Passkeys/WebAuthn
- Session timeout / auto-lock
