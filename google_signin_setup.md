# Setting Up Google Sign-In with Firebase

This guide provides detailed steps for implementing Google Sign-In authentication in your application using Firebase.

## Prerequisites

1. A Firebase project
2. Firebase SDK installed in your project
3. Google Cloud Console access
4. Your application's SHA-1 fingerprint (for Android)

## Step 1: Configure Firebase Project

1. Go to the [Firebase Console](https://console.firebase.google.com/)
2. Select your project or create a new one
3. In the left sidebar, click on "Authentication"
4. Navigate to the "Sign-in method" tab
5. Find "Google" in the list of providers
6. Click on Google and enable it
7. Configure the OAuth consent screen if prompted
8. Save your changes

## Step 2: Configure Google Cloud Console

1. Go to the [Google Cloud Console](https://console.cloud.google.com/)
2. Select your Firebase project
3. Navigate to "APIs & Services" > "Credentials"
4. Click "Create Credentials" > "OAuth client ID"
5. Choose your application type (Web, Android, or iOS)
6. Fill in the required information:
   - For Web: Add authorized JavaScript origins and redirect URIs
   - For Android: Enter your package name and SHA-1 fingerprint
   - For iOS: Enter your bundle ID
7. Save your configuration

## Step 3: Platform-Specific Setup

### For Web Applications

1. Add the Firebase SDK to your project:
```html
<script src="https://www.gstatic.com/firebasejs/9.x.x/firebase-app.js"></script>
<script src="https://www.gstatic.com/firebasejs/9.x.x/firebase-auth.js"></script>
```

2. Initialize Firebase with your configuration:
```javascript
const firebaseConfig = {
  // Your Firebase configuration object
};

firebase.initializeApp(firebaseConfig);
```

3. Implement the Google Sign-In flow:
```javascript
const provider = new firebase.auth.GoogleAuthProvider();
firebase.auth().signInWithPopup(provider)
  .then((result) => {
    // Handle successful sign-in
    const user = result.user;
  })
  .catch((error) => {
    // Handle errors
    console.error(error);
  });
```

### For Android Applications

1. Add the Google Sign-In dependency to your `build.gradle`:
```gradle
implementation 'com.google.android.gms:play-services-auth:20.x.x'
```

2. Configure your `AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.INTERNET"/>
```

3. Initialize Google Sign-In:
```kotlin
val gso = GoogleSignInOptions.Builder(GoogleSignInOptions.DEFAULT_SIGN_IN)
    .requestIdToken(getString(R.string.default_web_client_id))
    .requestEmail()
    .build()

val googleSignInClient = GoogleSignIn.getClient(this, gso)
```

### For iOS Applications

1. Install the Firebase iOS SDK using CocoaPods:
```ruby
pod 'Firebase/Auth'
pod 'GoogleSignIn'
```

2. Configure your `Info.plist`:
```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>com.googleusercontent.apps.YOUR-CLIENT-ID</string>
        </array>
    </dict>
</array>
```

3. Initialize Google Sign-In:
```swift
import Firebase
import GoogleSignIn

GIDSignIn.sharedInstance.signIn(with: GIDConfiguration(clientID: FirebaseApp.app()?.options.clientID ?? ""),
                              presenting: self) { user, error in
    // Handle sign-in result
}
```

## Step 4: Testing the Implementation

1. Run your application
2. Attempt to sign in with a Google account
3. Verify that:
   - The sign-in popup appears correctly
   - User authentication succeeds
   - User information is properly stored in Firebase
   - Error handling works as expected

## Common Issues and Troubleshooting

1. **SHA-1 Fingerprint Issues**
   - Ensure your SHA-1 fingerprint is correctly added to Firebase
   - Verify the fingerprint matches your debug and release keys

2. **OAuth Configuration**
   - Check that your OAuth consent screen is properly configured
   - Verify all required scopes are enabled

3. **Redirect URI Issues**
   - Ensure your redirect URIs are correctly configured
   - Check that they match your application's domain

4. **Client ID Mismatch**
   - Verify the client ID in your configuration matches the one in Firebase
   - Check for any typos or incorrect values

## Security Best Practices

1. Always verify the user's email if required
2. Implement proper error handling
3. Use secure storage for user tokens
4. Implement proper sign-out functionality
5. Handle token refresh properly
6. Implement proper session management

## Additional Resources

- [Firebase Authentication Documentation](https://firebase.google.com/docs/auth)
- [Google Sign-In Documentation](https://developers.google.com/identity/sign-in)
- [Firebase Console](https://console.firebase.google.com/)
- [Google Cloud Console](https://console.cloud.google.com/) 