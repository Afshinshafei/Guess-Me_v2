import Foundation
import GoogleMobileAds
import UIKit
import SwiftUI

// Conforms to FullScreenContentDelegate to handle ad lifecycle events
class AdMobManager: NSObject, ObservableObject, FullScreenContentDelegate {
    static let shared = AdMobManager()
    
    @Published var isRewardedAdReady = false
    @Published private(set) var isLoading = false // Use private(set) to control modification
    
    // Use RewardedAd instead of GADRewardedAd
    private var rewardedAd: RewardedAd?
    // Production Rewarded Ad Unit ID for Lives Reset Reward
    private let rewardedAdUnitID = "ca-app-pub-1651937682854848/5620357296"
    
    // Production Banner Ad Unit ID for home banner
    let bannerAdUnitID = "ca-app-pub-1651937682854848/8131481318"
    
    private override init() {
        super.init()
        print("AdMobManager: Initializing.")
        // Load the first ad asynchronously
        Task {
            await loadRewardedAd()
        }
    }
    
    // Use async/await for loading
    func loadRewardedAd() async {
        // Prevent concurrent loading attempts
        guard !isLoading else {
            print("AdMobManager: Already loading a rewarded ad.")
            return
        }
        // Prevent loading if an ad is already loaded and ready
        guard rewardedAd == nil else {
             print("AdMobManager: An ad is already loaded and ready.")
             isRewardedAdReady = true // Ensure state is correct
             return
        }

        isLoading = true
        isRewardedAdReady = false // Mark ad as not ready while loading
        print("AdMobManager: Starting to load rewarded ad with ID: \(rewardedAdUnitID)")

        do {
            // Use Request and the async load method
            let ad = try await RewardedAd.load(
                with: rewardedAdUnitID, request: Request())

            self.rewardedAd = ad
            // Set the delegate to handle presentation events
            self.rewardedAd?.fullScreenContentDelegate = self
            self.isRewardedAdReady = true
            self.isLoading = false
            print("AdMobManager: Rewarded ad loaded successfully and is ready.")

        } catch {
            self.rewardedAd = nil // Ensure ad is nil on failure
            self.isRewardedAdReady = false
            self.isLoading = false
            print("AdMobManager: Failed to load rewarded ad with error: \(error.localizedDescription)")

            // Optional: Retry loading after a delay
            // Consider a more robust retry strategy (e.g., exponential backoff)
            try? await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds
            print("AdMobManager: Retrying ad load after failure.")
            await loadRewardedAd()
        }
    }
    
    // Simplified presentation function
    func showRewardedAd(from viewController: UIViewController, completion: @escaping (Bool) -> Void) {
        guard let ad = rewardedAd, isRewardedAdReady else {
            print("AdMobManager: Rewarded ad is not ready to show.")
            completion(false)
            // Attempt to load a new ad if none is ready
            if !isLoading {
                Task {
                    await loadRewardedAd()
                }
            }
            return
        }

        // Ensure the view controller is valid for presentation
        guard viewController.view.window != nil else {
            print("AdMobManager: Error - View controller is not in view hierarchy. Cannot present ad.")
            completion(false)
            return
        }
        
        print("AdMobManager: Attempting to present rewarded ad.")
        // Present the ad and handle the reward callback
        ad.present(from: viewController) { [weak self] in
            print("AdMobManager: User earned reward.")
            // Reward granted
            completion(true)
            
            // Ad is used, mark as not ready and prepare for the next one
            self?.rewardedAd = nil // Ad can only be shown once
            self?.isRewardedAdReady = false
            // Load the next ad immediately in the background
            Task {
                await self?.loadRewardedAd()
            }
        }
    }
    
    // MARK: - FullScreenContentDelegate Methods

    /// Tells the delegate that the ad failed to present full screen content.
    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        print("AdMobManager: Ad failed to present full screen content with error: \(error.localizedDescription)")
        rewardedAd = nil // Ad failed, discard it
        isRewardedAdReady = false
        // Load the next ad
        Task {
            await loadRewardedAd()
        }
    }

    /// Tells the delegate that the ad will present full screen content.
    func adWillPresentFullScreenContent(_ ad: FullScreenPresentingAd) {
        print("AdMobManager: Ad will present full screen content.")
        // You could pause game audio here if needed
    }

    /// Tells the delegate that the ad dismissed full screen content.
    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        print("AdMobManager: Ad did dismiss full screen content.")
        // If the user dismissed the ad *without* earning the reward, the reward handler in present() won't fire.
        // We still need to load the next ad.
        if rewardedAd === ad { // Check if it's the same ad instance
             rewardedAd = nil // Ad is used/dismissed
             isRewardedAdReady = false
             Task {
                 await loadRewardedAd()
             }
        }
        // You could resume game audio here
    }

    // MARK: - Banner Ad Logic (Unchanged)

    // Create a banner ad view with adaptive size
    func createBannerAdView() -> BannerView { // Use BannerView
        let bannerView = BannerView() // Use BannerView
        bannerView.adUnitID = bannerAdUnitID
        
        let viewWidth = UIScreen.main.bounds.width
        // Use currentOrientationAnchoredAdaptiveBanner
        bannerView.adSize = currentOrientationAnchoredAdaptiveBanner(width: viewWidth)
        
        // Fix for iOS 15+ to get the root view controller
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            bannerView.rootViewController = rootViewController
            bannerView.load(Request()) // Use Request
        } else {
            print("AdMobManager: Failed to get root view controller for banner ad")
        }
        
        return bannerView
    }
}

// MARK: - SwiftUI Wrappers (Banner Ad Only)

// SwiftUI wrapper for BannerView
struct BannerAdView: UIViewRepresentable {
    // Use BannerView
    func makeUIView(context: Context) -> BannerView {
        return AdMobManager.shared.createBannerAdView()
    }
    
    // Use BannerView
    func updateUIView(_ uiView: BannerView, context: Context) {
        // No update needed generally for banner ads unless properties change
    }
} 
