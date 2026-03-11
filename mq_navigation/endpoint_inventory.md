# Endpoint Inventory — API Routes → Edge Functions Mapping

Maps every Next.js API route to the planned Supabase Edge Function or direct Supabase SDK call.

**Legend:**
- **SDK** = Call directly from Flutter via supabase_flutter (no server proxy needed)
- **EF** = Requires a Supabase Edge Function (server-side logic or secret keys)
- **N/A** = Not needed in Flutter (web-only concern)

## Auth Endpoints

| Web Route | Method | Flutter Approach | Phase | Notes |
|-----------|--------|-----------------|-------|-------|
| `/api/auth/signin` | POST | SDK: `supabase.auth.signInWithPassword()` | 2 | |
| `/api/auth/signup` | POST | SDK: `supabase.auth.signUp()` | 2 | |
| `/api/auth/signout` | POST | SDK: `supabase.auth.signOut()` | 2 | |
| `/api/auth/user` | GET | SDK: `supabase.auth.currentUser` | 1 | |
| `/api/auth/sessions` | GET | SDK: `supabase.from('user_sessions')` | 2 | |
| `/api/auth/password` | GET/PUT | SDK: `supabase.auth.updateUser()` | 2 | |
| `/api/auth/password/reset` | POST | SDK: `supabase.auth.resetPasswordForEmail()` | 2 | |
| `/api/auth/password/request-reset` | POST | SDK: `supabase.auth.resetPasswordForEmail()` | 2 | |
| `/api/auth/password/cleanup` | POST | EF: `auth-cleanup` | 2 | Server cron |
| `/api/auth/email/send-verification` | POST | EF: `auth-email` | 2 | Needs Resend key |
| `/api/auth/email/resend-verification` | POST | EF: `auth-email` | 2 | Needs Resend key |
| `/api/auth/email/verify` | POST | EF: `auth-email` | 2 | |
| `/api/auth/email/cleanup` | POST | EF: `auth-cleanup` | 2 | Server cron |
| `/api/auth/onboarding` | POST | SDK: `supabase.from('profiles').update()` | 2 | |
| `/api/auth/biometric` | POST | N/A | — | Web-only; Flutter uses local_auth |
| `/api/auth/mfa/status` | GET | SDK: `supabase.auth.mfa.getAuthenticatorAssuranceLevel()` | 2 | |
| `/api/auth/mfa/enroll` | POST | SDK: `supabase.auth.mfa.enroll()` | 2 | |
| `/api/auth/mfa/verify` | POST | SDK: `supabase.auth.mfa.verify()` | 2 | |
| `/api/auth/mfa/challenge` | POST | SDK: `supabase.auth.mfa.challenge()` | 2 | |
| `/api/auth/mfa/challenge-verify` | POST | SDK: `supabase.auth.mfa.challengeAndVerify()` | 2 | |
| `/api/auth/mfa/unenroll` | POST | SDK: `supabase.auth.mfa.unenroll()` | 2 | |
| `/api/auth/mfa/sms/enroll` | POST | SDK: `supabase.auth.mfa.enroll(factorType: 'phone')` | 2 | |
| `/api/auth/mfa/sms/verify` | POST | SDK: `supabase.auth.mfa.verify()` | 2 | |
| `/api/auth/passkey/*` | Various | Deferred | v1.1 | Passkeys deferred |
| `/api/webauthn/*` | Various | Deferred | v1.1 | WebAuthn deferred |

## Content Endpoints

| Web Route | Method | Flutter Approach | Phase | Notes |
|-----------|--------|-----------------|-------|-------|
| `/api/units` | GET | SDK: `supabase.from('units').select()` | 3 | RLS-filtered |
| `/api/units` | POST | SDK: `supabase.rpc('create_unit_with_schedule')` | 3 | |
| `/api/units/[id]` | GET/PUT/DELETE | SDK: direct table ops | 3 | |
| `/api/units/sync` | POST | SDK: `supabase.rpc('upsert_unit_with_schedule')` | 3 | |
| `/api/deadlines` | GET/POST | SDK: `supabase.from('deadlines')` | 3 | |
| `/api/deadlines/[id]` | GET/PUT/DELETE | SDK: direct table ops | 3 | |
| `/api/events` | GET/POST | SDK: `supabase.from('events')` | 3 | |
| `/api/events/[id]` | GET/PUT/DELETE | SDK: direct table ops | 3 | |
| `/api/todos` | GET/POST | SDK: `supabase.from('todos')` | 3 | |
| `/api/todos/[id]` | GET/PUT/DELETE | SDK: direct table ops | 3 | |
| `/api/notifications` | GET | SDK: `supabase.from('notifications')` | 4 | Inbox read/query |
| `/api/notifications` | POST | EF: `notify` | 4 | Stores inbox row + dispatches push |
| `/api/notifications/[id]` | GET/PUT/DELETE | SDK: direct table ops | 4 | |
| `/api/notifications/mark-all-read` | POST | SDK: `supabase.from('notifications').update({read: true})` | 4 | |
| `/api/profiles` | GET/PUT | SDK: `supabase.rpc('get_my_profile')` | 2 | |
| `/api/user-preferences` | GET/PUT | SDK: `supabase.from('user_preferences')` | 2 | |
| `/api/sync` | POST | SDK: Realtime subscriptions | 3 | |

## Maps & Navigation

| Web Route | Method | Flutter Approach | Phase | Notes |
|-----------|--------|-----------------|-------|-------|
| `/api/navigate` | POST | EF: `routes-proxy` | 5 | Legacy proxy retained for backward compatibility |
| `/api/maps/routes` | POST | EF: `maps-routes` | 5 | Authenticated Flutter routing proxy |
| `/api/maps/place-search` | GET | EF: `places-proxy` | 5 | Needs server key |
| `/api/maps/place-details` | GET | EF: `places-proxy` | 5 | Needs server key |

## Gamification

| Web Route | Method | Flutter Approach | Phase | Notes |
|-----------|--------|-----------------|-------|-------|
| `/api/gamification` | GET | SDK: `supabase.from('gamification_profiles')` | 3 | |
| `/api/gamification/award-xp` | POST | SDK: `supabase.rpc('award_xp')` | 3 | |

## Utility & Security

| Web Route | Method | Flutter Approach | Phase | Notes |
|-----------|--------|-----------------|-------|-------|
| `/api/weather` | GET | EF: `weather-proxy` | 5 | Needs GOOGLE_WEATHER_API_KEY |
| `/api/health` | GET | N/A | — | Vercel health check only |
| `/api/audit` | GET | SDK: `supabase.rpc('get_my_audit_logs')` | 2 | |
| `/api/csp-report` | POST | N/A | — | Browser CSP only |
| `/api/security/rate-limit/cleanup` | POST | EF: `cleanup-cron` | — | Server cron |
| `/api/security/scan-headers` | GET | N/A | — | Browser security only |
| `/api/security/check-password-breach` | POST | EF: `security-utils` | 2 | |
| `/api/admin/update-building-positions` | POST | N/A | — | Admin tool only |

## Edge Functions to Build

| Edge Function | Routes It Replaces | Priority | Phase |
|---------------|-------------------|----------|-------|
| `auth-email` | email/send-verification, resend, verify | P0 | 2 |
| `auth-cleanup` | password/cleanup, email/cleanup | P2 | 2 |
| `routes-proxy` | navigate, maps/routes | P0 | 5 |
| `places-proxy` | maps/place-search, maps/place-details | P1 | 5 |
| `weather-proxy` | weather | P2 | 5 |
| `security-utils` | check-password-breach | P1 | 2 |
| `cleanup-cron` | rate-limit/cleanup | P2 | — |
