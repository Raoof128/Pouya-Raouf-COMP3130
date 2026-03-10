# Auth Flow Matrix

Every authentication path in MQ Navigation, comparing web and Flutter implementations.

## Authentication Methods

| Method | Web | Flutter | Phase | Owner |
|--------|-----|---------|-------|-------|
| Email/Password signup | `supabase.auth.signUp()` via API route | SDK: `supabase.auth.signUp()` | 2 | Pouya (UI) + Raouf (backend) |
| Email/Password login | `supabase.auth.signInWithPassword()` via API route | SDK: `supabase.auth.signInWithPassword()` | 2 | Pouya + Raouf |
| Email verification | Custom API + Resend | EF: `auth-email` + deep link callback | 2 | Raouf |
| Password reset | Custom API + Resend | SDK: `supabase.auth.resetPasswordForEmail()` + deep link | 2 | Raouf |
| Google OAuth | `supabase.auth.signInWithOAuth({provider: 'google'})` | SDK: `supabase.auth.signInWithOAuth(OAuthProvider.google)` | 2 | Raouf |
| TOTP MFA enrol | `supabase.auth.mfa.enroll({factorType: 'totp'})` | SDK: same API via supabase_flutter | 2 | Raouf |
| TOTP MFA challenge | `supabase.auth.mfa.challenge()` + `verify()` | SDK: same API | 2 | Raouf |
| SMS MFA | `supabase.auth.mfa.enroll({factorType: 'phone'})` | SDK: same API | 2 | Raouf |
| Biometric re-auth | N/A (web uses WebAuthn) | `local_auth` plugin | 2 | Raouf |
| Passkeys/WebAuthn | Custom WebAuthn server | Deferred to v1.1 | v1.1 | Raouf |
| Session restoration | Browser cookies + localStorage | `supabase_flutter` auto-restore from Keychain/Keystore | 1 | — |

## Auth State Machine

```
App Launch
  │
  ├─ No session → /login
  │
  ├─ Session exists, email NOT verified → /verify-email
  │
  ├─ Session exists, email verified, AAL < required → /mfa
  │
  ├─ Session exists, profile incomplete → /onboarding
  │
  └─ Session exists, fully verified → /home
```

## Route Guards (go_router redirect)

| Guard | Condition | Redirects To |
|-------|-----------|-------------|
| AuthGuard | No valid session | `/login` |
| EmailVerificationGuard | Email unverified | `/verify-email` |
| MFAGuard | AAL < aal2 (when required) | `/mfa` |
| OnboardingGuard | Profile fields empty | `/onboarding` |

## Deep Link Callbacks

| Flow | Callback URL | Platform Config |
|------|-------------|-----------------|
| OAuth return | `io.mqnavigation://callback` | iOS: URL scheme + AASA; Android: App Links + DAL |
| Email verification | `io.mqnavigation://verify?token=...` | Same as above |
| Password reset | `io.mqnavigation://reset-password?token=...` | Same as above |

## Security Measures

| Measure | Implementation | Priority |
|---------|---------------|----------|
| Encrypted token storage | flutter_secure_storage (Keychain/Keystore) | P0 |
| Biometric gate | local_auth before sensitive actions | P0 |
| Deep link validation | Validate all params before processing | P0 |
| Certificate pinning | Custom HttpClient with pinned certs | P1 |
| Session timeout | Auto-lock after 15 min inactivity | P1 |
| Jailbreak detection | flutter_jailbreak_detection | P2 |
