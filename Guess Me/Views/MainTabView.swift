import SwiftUI
import GoogleMobileAds

struct MainTabView: View {
    @State private var selectedTab = 0
    @EnvironmentObject var authService: AuthenticationService
    @EnvironmentObject var gameManager: GameManager
    @State private var showProfileSetup = false
    @State private var forceRefresh = false
    @State private var initialCheckCompleted = false
    @State private var tabBarHeight: CGFloat = 0
    
    var body: some View {
        Group {
            if showProfileSetup {
                NavigationView {
                    ProfileSetupView()
                        .environmentObject(authService)
                        .environmentObject(gameManager)
                        .onDisappear {
                            // Force immediate check when ProfileSetupView disappears
                            print("ProfileSetupView disappeared, rechecking profile...")
                            checkProfileSetupNeeded()
                        }
                }
            } else {
                ZStack(alignment: .bottom) {
                    // Main content
                    TabView(selection: $selectedTab) {
                        // Home Tab
                        HomeView()
                            .ignoresSafeArea(.all, edges: .bottom)
                            .tag(0)
                        
                        // Game Tab
                        GameView()
                            .ignoresSafeArea(.all, edges: .bottom)
                            .tag(1)
                        
                        // Profile Tab (with Achievements integrated)
                        ProfileView()
                            .ignoresSafeArea(.all, edges: .bottom)
                            .tag(2)
                    }
                    
                    // Ad Banner
                    VStack(spacing: 0) {
                        // Custom TabBar
                        CustomTabBar(selectedTab: $selectedTab, tabBarHeight: $tabBarHeight)
                        
                        // Ad Banner
                        BannerAdView()
                            .frame(height: 45)
                            .background(Color(UIColor.systemBackground))
                    }
                }
                .environmentObject(authService)
                .environmentObject(gameManager)
            }
        }
        .id(forceRefresh) // Force view refresh when toggled
        .onAppear {
            print("MainTabView appeared, checking if profile setup is needed")
            // Only check on first appearance if not yet completed
            if !initialCheckCompleted {
                checkProfileSetupNeeded()
                initialCheckCompleted = true
            }
        }
        .onReceive(authService.$isAuthenticated) { isAuthenticated in
            print("DEBUG: MainTabView received auth state change: \(isAuthenticated)")
            // If user is no longer authenticated, we don't need to do anything 
            // as the app will navigate back to AuthView from the main app level
            if !isAuthenticated {
                print("DEBUG: User is not authenticated, will navigate to AuthView")
            }
        }
        .onReceive(authService.$user) { user in
            // Only perform this check during initial navigation after authentication
            // Not when the user object changes due to profile edits
            if !initialCheckCompleted {
                print("User changed in MainTabView, checking if profile setup is needed")
                checkProfileSetupNeeded()
                initialCheckCompleted = true
                forceRefresh.toggle() // Force view to refresh
            } else {
                print("User object updated, but skipping profile setup check since initial check was completed")
            }
        }
    }
    
    private func checkProfileSetupNeeded() {
        // Check if user needs to complete profile setup
        if let user = authService.user {
            print("DEBUG: Checking profile setup for user: \(user.username), ID: \(user.id ?? "no-id")")
            
            // Consider a profile incomplete if ANY of these are missing
            let hasProfileImage = user.profileImageURL != nil && !user.profileImageURL!.isEmpty
            let hasAge = user.age != nil
            let hasEducation = user.education != nil && !user.education!.isEmpty
            let hasOccupation = user.occupation != nil && !user.occupation!.isEmpty
            
            // A profile is incomplete if ANY of these are missing
            let profileIncomplete = !hasProfileImage || !hasAge || (!hasEducation && !hasOccupation)
            
            print("DEBUG: Profile check details:")
            print("- Has profile image: \(hasProfileImage)")
            print("- Has age: \(hasAge)")
            print("- Has education: \(hasEducation)")
            print("- Has occupation: \(hasOccupation)")
            print("- Profile is \(profileIncomplete ? "INCOMPLETE" : "COMPLETE")")
            
            if profileIncomplete != showProfileSetup {
                print("DEBUG: Changing showProfileSetup from \(showProfileSetup) to \(profileIncomplete)")
            }
            
            withAnimation {
                showProfileSetup = profileIncomplete
            }
        } else {
            print("DEBUG: No user available for profile check")
        }
    }
}

struct CustomTabBar: View {
    @Binding var selectedTab: Int
    @Binding var tabBarHeight: CGFloat
    @State private var isAnimating = [false, false, false]
    
    var body: some View {
        HStack(spacing: 0) {
            // Home Tab Button
            tabBarButton(
                title: "Home",
                icon: "house.fill",
                index: 0
            )
            
            // Game Tab Button - Center "GUESS NOW" button
            ZStack {
                VStack(spacing: 0) {
                    // Button
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    AppTheme.primary,
                                    AppTheme.tertiary
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 48, height: 48)
                        .shadow(color: AppTheme.primary.opacity(0.3), radius: 4, x: 0, y: 2)
                        .overlay(
                            Image(systemName: "gamecontroller.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 22, height: 22)
                                .foregroundColor(AppTheme.textOnDark)
                        )
                        .scaleEffect(isAnimating[1] ? 1.1 : 1.0)
                        .offset(y: -12)
                    
                    // Text below the button
                    Text("GUESS NOW")
                        .font(.system(size: 8, weight: .bold, design: .rounded))
                        .foregroundColor(selectedTab == 1 ? AppTheme.primary : AppTheme.textSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .padding(.top, 4)
                        .padding(.bottom, 2)
                        .offset(y: -4)
                }
            }
            .onTapGesture {
                withAnimation(.springy) {
                    selectedTab = 1
                    animateButton(at: 1)
                }
            }
            
            // Profile Tab Button
            tabBarButton(
                title: "Profile",
                icon: "person.fill",
                index: 2
            )
        }
        .padding(.top, 0)
        .padding(.bottom, 2)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.systemBackground))
                .shadow(color: Color.black.opacity(0.06), radius: 6, y: -1)
                .background(GeometryReader { geo in
                    Color.clear.onAppear {
                        tabBarHeight = geo.size.height
                    }
                })
        )
        .padding(.horizontal, 12)
    }
    
    private func tabBarButton(title: String, icon: String, index: Int) -> some View {
        VStack(spacing: 2) {
            Image(systemName: icon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 20, height: 20)
                .foregroundColor(selectedTab == index ? AppTheme.primary : AppTheme.textSecondary)
                .scaleEffect(isAnimating[index] ? 1.2 : 1.0)
            
            Text(title)
                .font(.system(size: 9, weight: .medium, design: .rounded))
                .foregroundColor(selectedTab == index ? AppTheme.primary : AppTheme.textSecondary)
                .padding(.bottom, 4)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 34) // Reduced from 36 to 34
        .opacity(selectedTab == 1 && index != 1 ? 0.7 : 1.0)
        .onTapGesture {
            withAnimation(.springy) {
                selectedTab = index
                animateButton(at: index)
            }
        }
    }
    
    private func animateButton(at index: Int) {
        isAnimating[index] = true
        
        // Reset animation after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isAnimating[index] = false
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(AuthenticationService())
        .environmentObject(GameManager())
} 
