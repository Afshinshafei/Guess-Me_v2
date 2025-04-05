import SwiftUI
import Combine
import FirebaseAuth

/// Navigation state enum for the app
enum AppScreen {
    case auth
    case tutorial
    case profileSetup
    case main
    case game
}

/// NavigationCoordinator manages app-wide navigation
class NavigationCoordinator: ObservableObject {
    @Published var currentScreen: AppScreen = .auth
    @Published var showProfileSetup: Bool = false
    @Published var showGame: Bool = false
    
    // Debugging flags
    @Published var lastAuthState: Bool = false
    @Published var lastNavigationReason: String = "Initial"
    
    var authService: AuthenticationService
    var cancellables = Set<AnyCancellable>()
    
    init(authService: AuthenticationService) {
        self.authService = authService
        setupAuthListener()
    }
    
    // Method to update the auth service reference
    func updateAuthService(_ newAuthService: AuthenticationService) {
        // Cancel existing subscriptions
        cancellables.removeAll()
        
        // Update the reference
        self.authService = newAuthService
        
        print("DEBUG: NavigationCoordinator - Auth service updated")
        
        // Re-setup listeners
        setupAuthListener()
    }
    
    // Force navigation to a specific screen
    func forceNavigateTo(_ screen: AppScreen, reason: String) {
        print("DEBUG: NavigationCoordinator - Force navigating to \(screen) because: \(reason)")
        lastNavigationReason = reason
        DispatchQueue.main.async {
            self.currentScreen = screen
        }
    }
    
    private func setupAuthListener() {
        // Monitor authentication changes
        authService.$isAuthenticated
            .sink { [weak self] isAuthenticated in
                guard let self = self else { return }
                
                print("DEBUG: NavigationCoordinator - Auth state changed: \(isAuthenticated)")
                self.lastAuthState = isAuthenticated
                
                if isAuthenticated {
                    // If user is authenticated and has completed setup, show main
                    // Otherwise show profile setup
                    if let user = authService.user {
                        print("DEBUG: NavigationCoordinator - Got user: \(user.username)")
                        if user.hasCompletedSetup {
                            print("DEBUG: NavigationCoordinator - User has completed setup, showing main screen")
                            self.forceNavigateTo(.main, reason: "User authenticated with completed setup")
                        } else {
                            print("DEBUG: NavigationCoordinator - User has not completed setup, showing tutorial")
                            self.forceNavigateTo(.tutorial, reason: "New user needs tutorial")
                        }
                    } else {
                        print("DEBUG: NavigationCoordinator - Auth is true but no user data yet, waiting...")
                        // We don't set the screen yet - wait for user data to be loaded
                    }
                } else {
                    print("DEBUG: NavigationCoordinator - User not authenticated, showing auth screen")
                    self.forceNavigateTo(.auth, reason: "User not authenticated")
                }
            }
            .store(in: &cancellables)
            
        // Also monitor user changes independently
        authService.$user
            .sink { [weak self] user in
                guard let self = self else { return }
                
                if let user = user {
                    print("DEBUG: NavigationCoordinator - User updated: \(user.username), hasCompletedSetup: \(user.hasCompletedSetup)")
                    
                    // If we already know the user is authenticated, update navigation accordingly
                    if self.authService.isAuthenticated {
                        if user.hasCompletedSetup {
                            self.forceNavigateTo(.main, reason: "User data loaded with completed setup")
                        } else {
                            self.forceNavigateTo(.tutorial, reason: "New user needs tutorial")
                        }
                    }
                } else {
                    print("DEBUG: NavigationCoordinator - User data cleared")
                }
            }
            .store(in: &cancellables)
    }
    
    // Navigation actions
    func signOut() {
        print("DEBUG: NavigationCoordinator - Initiating sign out")
        
        // Directly use Firebase Auth
        do {
            print("DEBUG: NavigationCoordinator - Directly calling Firebase Auth signOut()")
            
            // Check if a user is currently signed in
            if let currentUser = Auth.auth().currentUser {
                print("DEBUG: NavigationCoordinator - Current user exists: \(currentUser.uid)")
            } else {
                print("DEBUG: NavigationCoordinator - No current user found in Auth")
            }
            
            try Auth.auth().signOut()
            print("DEBUG: NavigationCoordinator - Firebase Auth signOut() completed successfully")
            
            // Update auth service state first (this will trigger auth listener)
            print("DEBUG: NavigationCoordinator - Manually updating auth state")
            authService.isAuthenticated = false
            authService.user = nil
            
            // Force navigation for extra reliability
            print("DEBUG: NavigationCoordinator - Forcing navigation to auth screen")
            self.forceNavigateTo(.auth, reason: "Manual sign out")
            
            // Post notification for any observers
            print("DEBUG: NavigationCoordinator - Posting SignOutComplete notification")
            NotificationCenter.default.post(name: NSNotification.Name("SignOutComplete"), object: nil)
            
            print("DEBUG: NavigationCoordinator - Sign out complete")
        } catch {
            print("ERROR: NavigationCoordinator - Sign out failed: \(error)")
            
            // Try to recover by manually updating state anyway
            print("DEBUG: NavigationCoordinator - Attempting manual recovery")
            authService.isAuthenticated = false
            authService.user = nil
            self.forceNavigateTo(.auth, reason: "Sign out error recovery")
            NotificationCenter.default.post(name: NSNotification.Name("SignOutComplete"), object: nil)
        }
    }
    
    func navigateToGame(gameManager: GameManager? = nil) {
        print("NavigationCoordinator: Navigating to game")
        
        // If gameManager is provided, check for lives
        if let gameManager = gameManager, gameManager.lives <= 0 {
            print("NavigationCoordinator: User has no lives, but still navigating to game to show no-lives overlay")
            // We'll still navigate to the game view, which will show the no-lives overlay
            showGame = true
            return
        }
        
        // Always allow navigation to game view - the game view will handle the no-lives case
        showGame = true
    }
    
    func completeProfileSetup() {
        print("NavigationCoordinator: Completed profile setup")
        forceNavigateTo(.main, reason: "Profile setup completed")
    }
    
    func navigateToProfileSetup() {
        print("NavigationCoordinator: Navigating to profile setup")
        forceNavigateTo(.profileSetup, reason: "User needs to complete profile setup")
    }
    
    func navigateBack() {
        print("NavigationCoordinator: Navigating back")
        forceNavigateTo(.auth, reason: "User wants to go back")
    }
} 