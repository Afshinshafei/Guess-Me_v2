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

@main
struct Guess_MeApp: App {
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
        }
    }
}
