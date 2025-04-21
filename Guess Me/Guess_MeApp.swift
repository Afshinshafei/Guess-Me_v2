//
//  Guess_MeApp.swift
//  Guess Me
//
//  Created by Afshin on 04/04/25.
//

import SwiftUI
import Firebase
import GoogleMobileAds
import FirebaseFirestore
import Combine
import GoogleSignIn
import AppTrackingTransparency
import AdSupport
import UserNotifications
import AuthenticationServices

// Add AppDelegate class for Firebase
class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        
        // Register for remote notifications
        UNUserNotificationCenter.current().delegate = self
        
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(
            options: authOptions,
            completionHandler: { _, _ in }
        )
        
        application.registerForRemoteNotifications()
        
        return true
    }
    
    // Required for Apple Sign In with Firebase
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // Keep this method for Firebase Auth, but don't use Messaging
    }
    
    // Handle Firebase authentication callbacks
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        return GIDSignIn.sharedInstance.handle(url)
    }
    
    // Handle Apple Sign In with the continuation callback
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        // Handle Apple Sign In callback
        if userActivity.activityType == NSUserActivityTypeBrowsingWeb,
           let incomingURL = userActivity.webpageURL {
            print("Received incoming URL for Apple Sign In: \(incomingURL)")
            // Process the URL as needed for your Apple Sign In implementation
            return true
        }
        return false
    }
}

@main
struct Guess_MeApp: App {
    // Register app delegate for Firebase setup
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    @StateObject private var authService = AuthenticationService()
    @StateObject private var gameManager = GameManager()
    @StateObject private var navigationCoordinator: NavigationCoordinator
    
    init() {
        print("Initializing app and configuring Firebase...")
        
        // Configure Firebase
        FirebaseApp.configure()
        
        // Set up Firestore logging for debugging
        let db = Firestore.firestore()
        let settings = db.settings
        settings.cacheSettings = MemoryCacheSettings()
        db.settings = settings
        
        print("Firebase configured successfully")
        
        // Initialize the Google Mobile Ads SDK
        MobileAds.initialize()
        print("Google Mobile Ads SDK initialized")
        
        // Load the AdMob rewarded ad
        _ = AdMobManager.shared
        
        // Initialize NavigationCoordinator with StateObject
        _navigationCoordinator = StateObject(wrappedValue: NavigationCoordinator(authService: AuthenticationService()))
    }
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                Group {
                    switch navigationCoordinator.currentScreen {
                    case .auth:
                        AuthView()
                            .environmentObject(authService)
                            .environmentObject(gameManager)
                            .environmentObject(navigationCoordinator)
                            .transition(.opacity)
                            .onAppear {
                                print("DEBUG: Showing AuthView")
                            }
                        
                    case .tutorial:
                        TutorialView()
                            .environmentObject(authService)
                            .environmentObject(gameManager)
                            .environmentObject(navigationCoordinator)
                            .transition(.opacity)
                            .onAppear {
                                print("DEBUG: Showing TutorialView")
                            }
                        
                    case .profileSetup:
                        ProfileSetupView()
                            .environmentObject(authService)
                            .environmentObject(gameManager)
                            .environmentObject(navigationCoordinator)
                            .transition(.opacity)
                            .onAppear {
                                print("DEBUG: Showing ProfileSetupView")
                            }
                        
                    case .main:
                        MainTabView()
                            .environmentObject(authService)
                            .environmentObject(gameManager)
                            .environmentObject(navigationCoordinator)
                            .transition(.opacity)
                            .onAppear {
                                print("DEBUG: Showing MainTabView")
                            }
                            .fullScreenCover(isPresented: $navigationCoordinator.showGame) {
                                GameView()
                                    .environmentObject(authService)
                                    .environmentObject(gameManager)
                                    .environmentObject(navigationCoordinator)
                            }
                        
                    case .game:
                        GameView()
                            .environmentObject(authService)
                            .environmentObject(gameManager)
                            .environmentObject(navigationCoordinator)
                            .transition(.opacity)
                            .onAppear {
                                print("DEBUG: Showing GameView directly")
                            }
                    }
                }
            }
            .animation(.easeInOut(duration: 0.3), value: navigationCoordinator.currentScreen)
            
            // Update the NavigationCoordinator when auth service is initialized
            .onAppear {
                DispatchQueue.main.async {
                    navigationCoordinator.updateAuthService(authService)
                    
                    // Listen for user changes to update the GameManager
                    authService.$user
                        .sink { user in
                            if let user = user {
                                print("User changed, updating GameManager with user ID: \(user.id ?? "unknown")")
                                gameManager.loadUserData(user.id)
                            } else {
                                // User signed out, reset GameManager
                                print("User signed out, resetting GameManager")
                                gameManager.loadUserData(nil)
                            }
                        }
                        .store(in: &navigationCoordinator.cancellables)
                }
            }
            // Handle incoming URLs for Google Sign-In authentication
            .onOpenURL { url in
                print("DEBUG: Received URL: \(url.absoluteString)")
                // Check if it's a Google Sign-In URL
                if url.absoluteString.contains("googleusercontent") {
                    GIDSignIn.sharedInstance.handle(url)
                } else {
                    // Could be an Apple Sign In callback
                    print("DEBUG: Received potential Apple Sign In callback URL: \(url)")
                }
            }
            // Request tracking authorization with a slight delay to ensure proper UI presentation
            .onAppear {
                requestTrackingPermission()
            }
        }
    }
    
    // Request tracking authorization with a slight delay to ensure proper UI presentation
    private func requestTrackingPermission() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            ATTrackingManager.requestTrackingAuthorization { status in
                switch status {
                case .authorized:
                    print("Tracking authorization granted")
                    // Enable personalized ads
                    let advertisingIdentifier = ASIdentifierManager.shared().advertisingIdentifier
                    print("Advertising identifier: \(advertisingIdentifier)")
                case .denied, .restricted, .notDetermined:
                    print("Tracking authorization denied or restricted: \(status.rawValue)")
                @unknown default:
                    print("Unknown tracking authorization status")
                }
            }
        }
    }
}
