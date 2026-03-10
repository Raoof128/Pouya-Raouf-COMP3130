# Notification Flow Matrix

All notification paths in MQ Navigation — push, local, and preference sync.

## Notification Types

| Type | Trigger | Delivery | Backend | Phase |
|------|---------|----------|---------|-------|
| **Push: Announcement** | Admin creates announcement | FCM | FCM token stored in Supabase | 4 |
| **Push: Grade update** | Server detects grade change | FCM | Edge Function dispatches | 4 |
| **Push: System alert** | Server maintenance / security | FCM | Edge Function dispatches | 4 |
| **Local: Deadline reminder** | X hours before deadline.due_date | flutter_local_notifications | Schedule locally from deadline data | 4 |
| **Local: Exam reminder** | X hours before exam date | flutter_local_notifications | Schedule locally from deadline data | 4 |
| **Local: Study prompt** | Daily at user-configured time | flutter_local_notifications | Preference in user_preferences | 4 |
| **Local: Event reminder** | X minutes before event.start_at | flutter_local_notifications | Schedule locally from event data | 4 |
| **In-app: Notification badge** | New unread notification | Supabase Realtime subscription | `notifications` table, read=false | 4 |

## Architecture

```
┌──────────────────────┐
│   Supabase Backend   │
│  ┌────────────────┐  │     FCM
│  │ Edge Function   │──────────────► Device (push)
│  │ dispatch-notif  │  │
│  └────────────────┘  │
│  ┌────────────────┐  │     Realtime
│  │ notifications   │──────────────► Flutter (in-app badge)
│  │ table           │  │
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
3. Store token in Supabase (`profiles.fcm_token` or `user_fcm_tokens` table)
4. On token refresh → update Supabase
5. On sign out → delete FCM token from Supabase

## Notification Channels (Android)

| Channel ID | Name | Importance | Sound |
|------------|------|-----------|-------|
| `deadline_reminders` | Deadline Reminders | High | Default |
| `exam_reminders` | Exam Reminders | High | Default |
| `study_prompts` | Study Prompts | Default | Default |
| `announcements` | Announcements | Default | Default |
| `system_alerts` | System Alerts | High | Default |

## Notification Preferences (bidirectional sync)

| Preference | Supabase Field | Local Cache | Default |
|------------|---------------|-------------|---------|
| Push notifications enabled | `user_preferences.notifications_enabled` | flutter_secure_storage | true |
| Email notifications | `user_preferences.email_notifications` | flutter_secure_storage | true |
| Deadline reminder hours | (future) | flutter_secure_storage | 24h |
| Study prompt time | (future) | flutter_secure_storage | 09:00 |

## Tap Routing

When user taps a notification, go_router handles the deep link:

| Notification Type | Deep Link | Route |
|-------------------|-----------|-------|
| Deadline reminder | `/deadline/:id` | DeadlineDetail |
| Exam reminder | `/deadline/:id` | DeadlineDetail |
| Event reminder | `/event/:id` | EventDetail |
| Announcement | `/feed` | FeedPage |
| System alert | `/home` | HomePage |
