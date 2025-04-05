import Foundation
import GoogleMobileAds
import UIKit
import SwiftUI

class AdMobManager: NSObject, ObservableObject {
    static let shared = AdMobManager()
    
    @Published var isRewardedAdReady = false
    @Published var isLoading = false
    
    private var rewardedAd: RewardedAd?
    // Use test ad unit ID for development (change this to your ad unit ID for production)
    private let rewardedAdUnitID = "ca-app-pub-3940256099942544/1712485313" // Test Rewarded Ad Unit ID
    
    // Banner ad test ID
    let bannerAdUnitID = "ca-app-pub-3940256099942544/2435281174" // Test Banner Ad Unit ID
    
    private override init() {
        super.init()
        print("AdMobManager: Initializing and loading initial rewarded ad")
        loadRewardedAd()
    }
    
    func loadRewardedAd() {
        guard !isLoading else { 
            print("AdMobManager: Already loading a rewarded ad, skipping duplicate request")
            return 
        }
        
        isLoading = true
        print("AdMobManager: Starting to load rewarded ad with ID: \(rewardedAdUnitID)")
        
        let request = Request()
        RewardedAd.load(with: rewardedAdUnitID, request: request) { [weak self] ad, error in
            guard let self = self else { return }
            
            self.isLoading = false
            
            if let error = error {
                print("AdMobManager: Failed to load rewarded ad with error: \(error.localizedDescription)")
                self.isRewardedAdReady = false
                
                // Try loading again after a delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    print("AdMobManager: Attempting to reload rewarded ad after failure")
                    self.loadRewardedAd()
                }
                return
            }
            
            self.rewardedAd = ad
            self.isRewardedAdReady = true
            print("AdMobManager: Rewarded ad loaded successfully and is ready to show")
            
            // Set up a callback for when the ad expires
            ad?.paidEventHandler = { [weak self] adValue in
                print("AdMobManager: Rewarded ad paid event: \(adValue.value) \(adValue.currencyCode)")
            }
        }
    }
    
    func showRewardedAd(from viewController: UIViewController, completion: @escaping (Bool) -> Void) {
        guard let rewardedAd = rewardedAd, isRewardedAdReady else {
            print("AdMobManager: Rewarded ad not ready yet, loading a new one...")
            loadRewardedAd()
            
            // Wait a moment and try again
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                if let ad = self.rewardedAd, self.isRewardedAdReady {
                    print("AdMobManager: Ad loaded after delay, presenting now")
                    self.presentAd(ad, from: viewController, completion: completion)
                } else {
                    print("AdMobManager: Ad still not ready after delay, giving up")
                    completion(false)
                }
            }
            return
        }
        
        presentAd(rewardedAd, from: viewController, completion: completion)
    }
    
    private func presentAd(_ ad: RewardedAd, from viewController: UIViewController, completion: @escaping (Bool) -> Void) {
        print("AdMobManager: Presenting rewarded ad to user")
        
        // Double-check that viewController is valid
        if viewController.view.window == nil {
            print("AdMobManager: Error - View controller is not in view hierarchy")
            completion(false)
            return
        }
        
        ad.present(from: viewController) { [weak self] in
            print("AdMobManager: User completed watching the ad and earned reward")
            completion(true)
            self?.isRewardedAdReady = false
            
            // Load the next ad immediately
            DispatchQueue.main.async {
                print("AdMobManager: Loading next rewarded ad after successful display")
                self?.loadRewardedAd()
            }
        }
    }
    
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
            print("AdMobManager: Failed to get root view controller for banner ad")
        }
        
        return bannerView
    }
}

// UIViewControllerRepresentable for showing rewarded ads in SwiftUI
struct RewardedAdController: UIViewControllerRepresentable {
    let completion: (Bool) -> Void
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<RewardedAdController>) -> UIViewController {
        let viewController = UIViewController()
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: UIViewControllerRepresentableContext<RewardedAdController>) {
        // Only attempt to show the ad if we've successfully loaded one
        if AdMobManager.shared.isRewardedAdReady {
            print("Showing rewarded ad from controller")
            AdMobManager.shared.showRewardedAd(from: uiViewController, completion: completion)
        } else {
            print("Rewarded ad not ready in controller, attempting to load")
            // If ad is not ready, try loading it and dismiss after a short delay
            AdMobManager.shared.loadRewardedAd()
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                completion(false)
            }
        }
    }
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