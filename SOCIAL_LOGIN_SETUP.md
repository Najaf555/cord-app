# Social Login Setup Guide

This guide will help you configure Google Sign-In, Facebook Login, and Apple Sign-In for your Cord app.

## Prerequisites

1. Flutter project with Firebase already configured
2. Google Cloud Console account
3. Facebook Developer account
4. Apple Developer account (for Apple Sign-In)

## 1. Google Sign-In Setup

### Step 1: Configure Google Cloud Console

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select an existing one
3. Enable the Google+ API
4. Go to "Credentials" → "Create Credentials" → "OAuth 2.0 Client IDs"
5. Configure the OAuth consent screen
6. Create OAuth 2.0 Client IDs for:
   - Android: Use your package name and SHA-1 fingerprint
   - iOS: Use your bundle identifier
   - Web: Add your domain

### Step 2: Update Android Configuration

1. Download the `google-services.json` file and place it in `android/app/`
2. Update `android/app/build.gradle.kts`:
   ```kotlin
   // Add to dependencies
   implementation 'com.google.android.gms:play-services-auth:20.7.0'
   ```

### Step 3: Update iOS Configuration

1. Download the `GoogleService-Info.plist` file and add it to your iOS project
2. Update `ios/Runner/Info.plist`:
   ```xml
   <!-- Replace YOUR_GOOGLE_CLIENT_ID with your actual client ID -->
   <string>com.googleusercontent.apps.YOUR_GOOGLE_CLIENT_ID</string>
   ```

## 2. Facebook Login Setup

### Step 1: Configure Facebook Developer Console

1. Go to [Facebook Developers](https://developers.facebook.com/)
2. Create a new app or select an existing one
3. Add Facebook Login product
4. Configure OAuth redirect URIs
5. Get your App ID and Client Token

### Step 2: Update Android Configuration

1. Update `android/app/src/main/res/values/strings.xml`:
   ```xml
   <!-- Replace with your actual Facebook App ID and Client Token -->
   <string name="facebook_app_id">YOUR_FACEBOOK_APP_ID</string>
   <string name="facebook_client_token">YOUR_FACEBOOK_CLIENT_TOKEN</string>
   <string name="fb_login_protocol_scheme">fbYOUR_FACEBOOK_APP_ID</string>
   ```

2. Update `android/app/src/main/AndroidManifest.xml`:
   ```xml
   <!-- Replace fb123456789012345 with your actual Facebook App ID -->
   <data android:scheme="fbYOUR_FACEBOOK_APP_ID" />
   ```

### Step 3: Update iOS Configuration

1. Update `ios/Runner/Info.plist`:
   ```xml
   <!-- Replace with your actual Facebook App ID and Client Token -->
   <string>YOUR_FACEBOOK_APP_ID</string>
   <string>YOUR_FACEBOOK_CLIENT_TOKEN</string>
   <string>fbYOUR_FACEBOOK_APP_ID</string>
   ```

## 3. Apple Sign-In Setup

### Step 1: Configure Apple Developer Console

1. Go to [Apple Developer](https://developer.apple.com/)
2. Create an App ID with Sign In with Apple capability
3. Create a Services ID for web authentication
4. Configure your domain and redirect URLs

### Step 2: Update iOS Configuration

1. Enable "Sign In with Apple" capability in Xcode
2. Update your provisioning profile
3. The configuration in `Info.plist` is already set up

## 4. Firebase Configuration

### Step 1: Enable Authentication Providers

1. Go to Firebase Console → Authentication → Sign-in method
2. Enable the following providers:
   - Google
   - Facebook
   - Apple

### Step 2: Configure OAuth Providers

For each provider, add the necessary configuration:
- **Google**: Add your OAuth 2.0 Client IDs
- **Facebook**: Add your Facebook App ID and App Secret
- **Apple**: Add your Services ID and private key

## 5. Code Implementation

The social login implementation is already complete in the following files:

- `lib/login/social_login_service.dart` - Main service class
- `lib/login/login_view.dart` - Login screen with social buttons
- `lib/login/signup.dart` - Signup screen with social buttons

## 6. Testing

### Test Each Provider

1. **Google Sign-In**: Test on both Android and iOS
2. **Facebook Login**: Test on both platforms
3. **Apple Sign-In**: Test on iOS (requires real device for full testing)

### Common Issues

1. **SHA-1 Fingerprint**: Make sure you're using the correct SHA-1 for your debug/release builds
2. **Bundle ID**: Ensure bundle ID matches across all configurations
3. **OAuth Redirect URIs**: Verify all redirect URIs are correctly configured
4. **Firebase Rules**: Ensure Firestore rules allow user data creation

## 7. Production Deployment

### Before Release

1. Update all placeholder values with real credentials
2. Test on real devices
3. Verify all OAuth flows work correctly
4. Check Firestore security rules
5. Test user data persistence

### Security Considerations

1. Never commit real API keys to version control
2. Use environment variables for sensitive data
3. Implement proper error handling
4. Add rate limiting if needed
5. Monitor authentication logs

## 8. Troubleshooting

### Common Errors

1. **"Google Sign-In Error"**: Check OAuth client configuration
2. **"Facebook login failed"**: Verify App ID and permissions
3. **"Apple Sign-In is not available"**: Check device compatibility and capabilities

### Debug Steps

1. Check console logs for detailed error messages
2. Verify all configuration files are properly set
3. Test with different user accounts
4. Check network connectivity
5. Verify Firebase project settings

## Support

If you encounter issues:

1. Check the official documentation for each provider
2. Review Firebase Authentication logs
3. Test with minimal configuration first
4. Ensure all dependencies are up to date

## Files Modified

- `pubspec.yaml` - Added social login dependencies
- `lib/login/social_login_service.dart` - Created social login service
- `lib/login/login_view.dart` - Updated with social login buttons
- `lib/login/signup.dart` - Updated with social login buttons
- `android/app/build.gradle.kts` - Updated Android configuration
- `android/app/src/main/AndroidManifest.xml` - Added permissions and activities
- `android/app/src/main/res/values/strings.xml` - Added Facebook configuration
- `ios/Runner/Info.plist` - Added iOS configuration
- `SOCIAL_LOGIN_SETUP.md` - This setup guide 