# Notification Flow Matrix

All notification paths in MQ Navigation — push, local, and preference sync.

## Notification Types

| Type | Trigger | Delivery | Backend | Phase |
|------|---------|----------|---------|-------|
| **Push: Announcement** | Admin creates announcement | FCM | `notify` Edge Function + `user_fcm_tokens` | 4 |
| **Push: Grade update** | Server detects grade change | FCM | `notify` Edge Function | 4 |
| **Push: System alert** | Server maintenance / security | FCM | `notify` Edge Function | 4 |
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
│  │ notify          │  │
│  └────────────────┘  │
│  ┌────────────────┐  │     Realtime
│  │ notifications   │──────────────► Flutter (in-app badge)
│  │ table           │  │
│  └────────────────┘  │
│  ┌────────────────┐  │
│  │ user_fcm_tokens │  │
│  │ notification_   │  │
│  │ preferences     │  │
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

| Preference | Supabase Table/Field | Local Cache | Default |
|------------|----------------------|-------------|---------|
| Per-type enabled flag | `notification_preferences.enabled` | Riverpod state | true |
| Study prompt hour | `notification_preferences.scheduled_hour` | Riverpod state | 09 |
| Study prompt minute | `notification_preferences.scheduled_minute` | Riverpod state | 00 |

## Tap Routing

When user taps a notification, go_router handles the deep link:

| Notification Type | Deep Link | Route |
|-------------------|-----------|-------|
| Deadline reminder | `/detail/deadline/:id` | Deadline detail page |
| Exam reminder | `/detail/exam/:id` | Exam detail page |
| Event reminder | `/detail/event/:id` | Event detail page |
| Announcement | `/feed` | FeedPage |
| System alert | `/settings` | SettingsPage |
