# Setting Up Google AdMob in Your iOS App

This guide will walk you through the process of setting up Google AdMob banner ads in your iOS application.

## Step 1: Create an AdMob Account

1. Go to [AdMob's website](https://admob.google.com)
2. Sign in with your Google account or create a new one
3. Follow the setup steps to create your AdMob account

## Step 2: Add a New App

1. In your AdMob dashboard, click on "Apps" in the sidebar
2. Click the "+ Add App" button
3. Choose whether your app is on iOS or Android
4. You can either choose "Yes, it's published in app store" if your app is already in the App Store, or "No, I'll add details about my app"
5. Follow the prompts to complete the registration of your app

## Step 3: Create Ad Units

For banner ads:

1. From your AdMob dashboard, select "Apps" in the sidebar
2. Select your app from the list
3. Click on "Ad units" in the left navigation
4. Click on "+ Create ad unit" button
5. Select "Banner" as the ad format
6. Name your ad unit (e.g., "Home Screen Banner", "Profile Banner", etc.)
7. Configure any additional settings as needed
8. Click "Create" to generate the ad unit
9. AdMob will provide you with an Ad unit ID (save this for later use)

For rewarded ads:

1. Follow the same steps as above, but select "Rewarded" as the ad format
2. Configure the reward settings (e.g., reward type, amount)
3. Save the rewarded ad unit ID

## Step 4: Configure Your iOS App

1. Update your `Info.plist` file with the following entries:

```xml
<key>GADApplicationIdentifier</key>
<string>ca-app-pub-XXXXXXXXXXXXXXXX~NNNNNNNNNN</string>
<key>GADIsAdManagerApp</key>
<true/>
<key>SKAdNetworkItems</key>
<array>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>cstr6suwn9.skadnetwork</string>
    </dict>
</array>
<key>NSUserTrackingUsageDescription</key>
<string>This identifier will be used to deliver personalized ads to you.</string>
```

Replace `ca-app-pub-XXXXXXXXXXXXXXXX~NNNNNNNNNN` with your AdMob App ID.

2. Initialize the Mobile Ads SDK in your app:

For SwiftUI apps (using the new app lifecycle):

```swift
import GoogleMobileAds

@main
struct YourApp: App {
    init() {
        // Initialize the Google Mobile Ads SDK
        MobileAds.initialize()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

For UIKit apps (using AppDelegate):

```swift
import GoogleMobileAds

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Initialize Google Mobile Ads SDK
        GADMobileAds.sharedInstance().start(completionHandler: nil)
        
        return true
    }
}
```

## Step 5: Replace Test Ad Unit IDs with Your Own

In the AdMobManager class, replace the test ad unit IDs with your own:

```swift
// Replace these test IDs with your actual ad unit IDs for production
private let rewardedAdUnitID = "ca-app-pub-XXXXXXXXXXXXXXXX/NNNNNNNNNN" // Your Rewarded Ad Unit ID
let bannerAdUnitID = "ca-app-pub-XXXXXXXXXXXXXXXX/NNNNNNNNNN" // Your Banner Ad Unit ID
```

## Step 6: Implement Banner Ads

Here's an example of how to implement banner ads using the latest Google Mobile Ads SDK:

```swift
// Create a banner ad view with adaptive size
func createBannerAdView() -> BannerView {
    let bannerView = BannerView()
    bannerView.adUnitID = bannerAdUnitID
    
    let viewWidth = UIScreen.main.bounds.width
    bannerView.adSize = adSizeFor(cgSize: CGSize(width: viewWidth, height: 50))
    
    // Fix for iOS 15+ to get the root view controller
    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
       let rootViewController = windowScene.windows.first?.rootViewController {
        bannerView.rootViewController = rootViewController
        bannerView.load(Request())
    } else {
        print("Failed to get root view controller for banner ad")
    }
    
    return bannerView
}

// SwiftUI wrapper for BannerView
struct BannerAdView: UIViewRepresentable {
    func makeUIView(context: Context) -> BannerView {
        return AdMobManager.shared.createBannerAdView()
    }
    
    func updateUIView(_ uiView: BannerView, context: Context) {
        // No update needed
    }
}
```

## Testing Best Practices

- Always use test ad unit IDs during development:
  - Banner: `ca-app-pub-3940256099942544/2435281174`
  - Interstitial: `ca-app-pub-3940256099942544/4411468910`
  - Rewarded: `ca-app-pub-3940256099942544/1712485313`
  - App ID: `ca-app-pub-3940256099942544~1458002511`

- Only replace with your actual ad unit IDs when publishing the app

## Troubleshooting

- If ads aren't appearing, check the console for error messages
- Ensure you've properly set up your AdMob account and ad units
- Verify your app's bundle ID matches what you registered in AdMob
- Make sure you have an active internet connection for testing
- For iOS 15+, make sure you're using the correct method to get the root view controller for banner ads
- If you see errors about renamed classes, make sure you're using the latest class names from the Google Mobile Ads SDK

## Additional Resources

- [AdMob iOS Guide](https://developers.google.com/admob/ios/quick-start)
- [AdMob Policies](https://support.google.com/admob/answer/6128543) 