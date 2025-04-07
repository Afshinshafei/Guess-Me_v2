# GuessMe - The Social Guessing Game

## Overview
GuessMe is a fun and engaging iOS app where users try to guess things about other people based on their profile pictures! It's a mix between a social network and a guessing game, where your ability to "read" people is put to the test.

## Features
- **Profile Creation**: Upload a profile picture and fill in personal details
- **Guessing Game**: Guess attributes about other users based on their photos
- **Lives System**: Start with 5 lives, lose one for each wrong guess
- **Achievements**: Earn badges for guessing streaks and milestones
- **Rewards**: Watch ads to gain extra lives

## Technical Stack
- SwiftUI for the UI
- Firebase (Authentication, Firestore, Storage) for the backend
- Google AdMob for monetization

## Setup Instructions

### Prerequisites
- Xcode 14.0+
- iOS 16.0+
- Swift 5.7+
- An Apple Developer account (for running on physical devices)
- A Firebase project with Authentication, Firestore, and Storage enabled
- An AdMob account

### Firebase Setup
1. Download your `GoogleService-Info.plist` file from the Firebase Console
2. Add it to your Xcode project (ensure "Copy items if needed" is checked)
3. Add the Firebase SDK packages via Swift Package Manager:
   - Go to File > Add Packages
   - Enter the Firebase SDK URL: `https://github.com/firebase/firebase-ios-sdk.git`
   - Select the following products:
     - FirebaseAuth
     - FirebaseFirestore
     - FirebaseStorage
     - FirebaseAnalytics (optional but recommended)

### AdMob Setup
1. Add the Google Mobile Ads SDK package via Swift Package Manager:
   - Go to File > Add Packages
   - Enter the Google Mobile Ads SDK URL: `https://github.com/googleads/swift-package-manager-google-mobile-ads.git`
2. Update your Info.plist with the required AdMob configurations (see `Info_plist_additions.txt`)
3. Replace the test ad unit IDs with your actual Ad Unit IDs for production

### Running the App
1. Open the Xcode project
2. Select your development team in the project settings
3. Build and run the app on a simulator or device

## Project Structure
- **Models**: Data models for User, Question, and Achievement
- **Services**: Firebase services for Authentication, Firestore, and Storage
- **Managers**: Game, Question, and AdMob management
- **Views**: UI components organized by feature (Auth, Home, Game, Profile, Achievements)

## Contact
For questions or support, please contact the development team at [your-email@example.com].

## License
[Your license information here] 