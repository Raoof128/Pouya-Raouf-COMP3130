# Notification Flow Matrix

All notification paths in MQ Navigation — push and local.

## Notification Types

| Type | Trigger | Delivery | Backend |
|------|---------|----------|---------|
| **Push: Announcement** | Admin creates announcement | FCM | `notify` Edge Function + `user_fcm_tokens` |
| **Local: Study prompt** | Daily at user-configured time | flutter_local_notifications | Preference in local storage |

## Architecture

```
┌──────────────────────┐
│   Supabase Backend   │
│  ┌────────────────┐  │     FCM
│  │ Edge Function   │──────────────► Device (push)
│  │ notify          │  │
│  └────────────────┘  │
│  ┌────────────────┐  │
│  │ user_fcm_tokens │  │
│  └────────────────┘  │
└──────────────────────┘

┌──────────────────────┐
│   Flutter App        │
│  ┌────────────────┐  │
│  │ Local Notif     │  │     Scheduled locally
│  │ Service         │──────────────► OS notification tray
│  └────────────────┘  │
└──────────────────────┘
```

## FCM Token Lifecycle

1. App launch → request notification permission
2. Get FCM token via `firebase_messaging`
3. Store token in Supabase `user_fcm_tokens`
4. On token refresh → update Supabase

## Notification Channels (Android)

| Channel ID | Name | Importance | Sound |
|------------|------|-----------|-------|
| `study_prompts` | Study Prompts | Default | Default |
| `announcements` | Announcements | Default | Default |

## Notification Preferences

Preferences are stored locally via `flutter_secure_storage`:

| Preference | Default |
|------------|---------|
| Notifications enabled | true |
| Email notifications | false |
| Study prompt hour | 09 |
| Study prompt minute | 00 |

## Tap Routing

When user taps a notification:

| Notification Type | Route |
|-------------------|-------|
| Announcement | `/notifications` |
| Study prompt | `/home` |
