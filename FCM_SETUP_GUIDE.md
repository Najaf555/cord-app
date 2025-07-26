# FCM Notification Setup Guide

This guide will help you set up Firebase Cloud Messaging (FCM) notifications for session invitations in your Cord app.

## Prerequisites

1. Firebase project with FCM enabled
2. FCM Server Key
3. Flutter app with Firebase configured

## Step 1: Get Your FCM Server Key

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project (`cord-bfb48`)
3. Go to **Project Settings** (gear icon)
4. Go to **Cloud Messaging** tab
5. Copy the **Server key** (starts with `AAAA...`)

## Step 2: Update FCM Server Key

1. Open `lib/utils/fcm_notification_service.dart`
2. Replace `YOUR_FCM_SERVER_KEY` with your actual server key:

```dart
static const String _serverKey = 'AAAA...your-actual-server-key...';
```

## Step 3: Install Dependencies

Run the following command to install the new dependencies:

```bash
flutter pub get
```

## Step 4: Configure Android

### Update android/app/build.gradle

Add the following to your `android/app/build.gradle` file in the `android` block:

```gradle
android {
    // ... existing config ...
    
    defaultConfig {
        // ... existing config ...
        multiDexEnabled true
    }
}
```

### Update android/app/src/main/AndroidManifest.xml

Add the following permissions to your `AndroidManifest.xml`:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- ... existing permissions ... -->
    
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.WAKE_LOCK" />
    <uses-permission android:name="android.permission.VIBRATE" />
    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
    
    <application>
        <!-- ... existing application config ... -->
        
        <!-- FCM Service -->
        <service
            android:name="io.flutter.plugins.firebase.messaging.FlutterFirebaseMessagingService"
            android:exported="false">
            <intent-filter android:priority="0">
                <action android:name="com.google.firebase.MESSAGING_EVENT" />
            </intent-filter>
        </service>
        
        <!-- Default notification icon -->
        <meta-data
            android:name="com.google.firebase.messaging.default_notification_icon"
            android:resource="@drawable/ic_launcher" />
            
        <!-- Default notification color -->
        <meta-data
            android:name="com.google.firebase.messaging.default_notification_color"
            android:resource="@color/colorAccent" />
    </application>
</manifest>
```

## Step 5: Configure iOS

### Update ios/Runner/Info.plist

Add the following to your `Info.plist` file:

```xml
<key>UIBackgroundModes</key>
<array>
    <string>fetch</string>
    <string>remote-notification</string>
</array>
<key>FirebaseAppDelegateProxyEnabled</key>
<false/>
```

### Update ios/Runner/AppDelegate.swift

Make sure your `AppDelegate.swift` includes FCM configuration:

```swift
import UIKit
import Flutter
import Firebase
import FirebaseMessaging

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    FirebaseApp.configure()
    
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
      let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
      UNUserNotificationCenter.current().requestAuthorization(
        options: authOptions,
        completionHandler: { _, _ in }
      )
    } else {
      let settings: UIUserNotificationSettings =
        UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
      application.registerUserNotificationSettings(settings)
    }
    
    application.registerForRemoteNotifications()
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

## Step 6: Test the Implementation

### Test FCM Token Storage

1. Run the app and log in
2. Check the console logs for FCM token storage messages
3. Verify in Firebase Console that tokens are being stored in the `users` collection

### Test Invitation Notifications

1. Create a session
2. Invite another user by email
3. Check that the invited user receives a push notification
4. Test accepting/rejecting invitations and verify notifications are sent to the inviter

## How It Works

### FCM Token Storage

- FCM tokens are automatically saved when users log in
- Tokens are stored in the `users` collection as an array in the `fcmTokens` field
- Multiple tokens per user are supported (for multiple devices)

### Notification Flow

1. **Session Invitation**: When a user invites someone to a session
   - Invitation is saved to `user_invitations` collection
   - FCM notification is sent to the invited user
   - Notification includes session name and inviter's name

2. **Invitation Response**: When a user accepts/rejects an invitation
   - Invitation status is updated in Firestore
   - FCM notification is sent to the original inviter
   - Notification includes the response and user's name

### Notification Types

- **Session Invitation**: "John Doe invited you to join 'My Session'"
- **Invitation Accepted**: "Jane Smith accepted your invitation to 'My Session'"
- **Invitation Declined**: "Jane Smith declined your invitation to 'My Session'"

## Troubleshooting

### Common Issues

1. **No notifications received**
   - Check FCM server key is correct
   - Verify user has granted notification permissions
   - Check console logs for FCM errors

2. **Notifications not showing when app is in foreground**
   - Ensure local notifications are properly configured
   - Check notification channel setup for Android

3. **Invalid FCM tokens**
   - The app automatically cleans up invalid tokens
   - Check console logs for token cleanup messages

### Debug Steps

1. Check Firebase Console > Cloud Messaging > Reports
2. Monitor console logs for FCM-related messages
3. Verify FCM tokens are being stored in Firestore
4. Test with a simple notification first

## Security Considerations

- Keep your FCM server key secure
- Consider using Firebase Cloud Functions for server-side notification sending
- Implement rate limiting for notification sending
- Validate user permissions before sending notifications

## Next Steps

1. **Customize Notification Content**: Modify notification titles and messages
2. **Add Deep Linking**: Navigate to specific screens when notifications are tapped
3. **Implement Notification Preferences**: Allow users to control notification types
4. **Add Analytics**: Track notification engagement and effectiveness 