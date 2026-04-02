# Notification Implementation Notes

## Implemented Flow

- FCM background handler: [notification_service.dart](/e:/FlutterProjects/aqar%20masrien/Aqar%20El%20Masryeen/aqarelmasryeen/lib/core/services/notification_service.dart)
- Permission request and iOS foreground presentation: same file
- Notification tap routing from splash bootstrap: [splash_screen.dart](/e:/FlutterProjects/aqar%20masrien/Aqar%20El%20Masryeen/aqarelmasryeen/lib/features/auth/presentation/screens/splash_screen.dart)
- In-app notification center: [notifications_center_screen.dart](/e:/FlutterProjects/aqar%20masrien/Aqar%20El%20Masryeen/aqarelmasryeen/lib/features/notifications/presentation/notifications_center_screen.dart)

## Android

- `POST_NOTIFICATIONS` permission is declared.
- High-priority local display uses channel `finance_alerts`.
- Foreground messages are surfaced through `flutter_local_notifications`.

## iOS

- Permission request uses alert, badge, sound, and provisional support.
- Foreground presentation is explicitly enabled with alert, badge, and sound.
- Remote notification background mode is enabled in `Info.plist`.
- Production reliability still depends on APNs key upload and Apple capabilities in Xcode.

## Payload Contract

Use `data.payload` as JSON:

```json
{
  "route": "/properties/<propertyId>",
  "extraId": "optional-id"
}
```

## Recommended Server Triggers

- installment due in 7 days
- overdue installment
- new expense created
- payment received
- new device login
- critical system announcement
