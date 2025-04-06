import SwiftUI
import GoogleMobileAds

struct HomeView: View {
    @EnvironmentObject var authService: AuthenticationService
    @EnvironmentObject var gameManager: GameManager
    @EnvironmentObject var navigationCoordinator: NavigationCoordinator
    @State private var showWatchAdAlert = false
    @State private var showAdRewardController = false
    @State private var animateBackground = false
    @State private var showAllAchievements = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Animated gradient background using design system
                LinearGradient(
                    colors: [
                        AppTheme.primary.opacity(0.8),
                        AppTheme.tertiary.opacity(0.6),
                        AppTheme.secondary.opacity(0.7)
                    ],
                    startPoint: animateBackground ? .topLeading : .bottomLeading,
                    endPoint: animateBackground ? .bottomTrailing : .topTrailing
                )
                .hueRotation(.degrees(animateBackground ? 45 : 0))
                .ignoresSafeArea()
                .onAppear {
                    withAnimation(.linear(duration: 20).repeatForever(autoreverses: true)) {
                        animateBackground.toggle()
                    }
                }
                
                VStack {
                    ScrollView {
                        VStack(spacing: 25) {
                            // Welcome section
                            welcomeSection
                            
                            // Stats section
                            statsSection
                            
                            // Awards section
                            awardsSection
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 15)
                        
                        // Add some bottom padding to ensure content doesn't get hidden behind the banner
                        Color.clear.frame(height: 60)
                    }
                    
                    // Banner ad at the bottom
                    BannerAdView()
                        .frame(height: 50)
                        .background(AppTheme.cardBackground)
                        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: -2)
                }
                .navigationTitle("Home")
                .navigationBarTitleDisplayMode(.large)
                .sheet(isPresented: $showAdRewardController) {
                    loadingAdView
                }
                .sheet(isPresented: $showAllAchievements) {
                    AchievementsView()
                }
                .alert(isPresented: $showWatchAdAlert) {
                    Alert(
                        title: Text("Watch Ad for Extra Life?"),
                        message: Text("Watch a short video to get an extra life!"),
                        primaryButton: .default(Text("Watch Ad")) {
                            showAdRewardController = true
                        },
                        secondaryButton: .cancel()
                    )
                }
            }
        }
    }
    
    private var loadingAdView: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(AppTheme.primary.opacity(0.1))
                    .frame(width: 80, height: 80)
                
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(AppTheme.primary)
            }
            
            Text("Loading Ad...")
                .font(AppTheme.heading())
                .foregroundColor(AppTheme.textPrimary)
                .padding(.bottom, 4)
            
            Text("Please wait a moment")
                .font(AppTheme.body())
                .foregroundColor(AppTheme.textSecondary)
                .padding(.bottom, 20)
                .onAppear {
                    // Pre-load the ad if not already loaded
                    if !AdMobManager.shared.isRewardedAdReady {
                        print("Ad not ready, loading now")
                        AdMobManager.shared.loadRewardedAd()
                    } else {
                        print("Ad already loaded and ready")
                    }
                    
                    // Attempt to show the ad after a short delay to allow it to load
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                           let rootVC = scene.windows.first?.rootViewController {
                            print("Attempting to show rewarded ad")
                            AdMobManager.shared.showRewardedAd(from: rootVC) { success in
                                if success {
                                    print("Ad watched successfully, adding life")
                                    gameManager.addLife()
                                } else {
                                    print("Ad failed to show or was not watched")
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    showAdRewardController = false
                                }
                            }
                        } else {
                            print("Failed to get root view controller for ad")
                            showAdRewardController = false
                        }
                    }
                }
            
            // Add a cancel button in case the ad doesn't load
            Button("Cancel") {
                showAdRewardController = false
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 24)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppTheme.textSecondary.opacity(0.2))
            )
            .foregroundColor(AppTheme.textPrimary)
            .buttonStyle(ScaleButtonStyle())
        }
        .padding(30)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(AppTheme.cardBackground)
        )
        .floatingCardStyle()
        .padding(20)
    }
    
    private var welcomeSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Welcome, \(authService.user?.username ?? "Player")!")
                .font(AppTheme.heading())
                .foregroundColor(AppTheme.textPrimary)
                
            Text("Ready to test your people-reading skills?")
                .font(AppTheme.body())
                .foregroundColor(AppTheme.textSecondary)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(AppTheme.cardBackground)
        )
        .floatingCardStyle()
    }
    
    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Your Stats")
                .font(AppTheme.subheading())
                .foregroundColor(AppTheme.textPrimary)
                .padding(.bottom, 5)
                
            HStack(spacing: 12) {
                StatItemView(
                    title: "Score",
                    value: "\(authService.user?.score ?? 0)",
                    iconName: "trophy.fill",
                    color: AppTheme.secondary
                )
                
                StatItemView(
                    title: "Streak",
                    value: "\(gameManager.currentStreak)",
                    iconName: "flame.fill",
                    color: AppTheme.accent
                )
                
                StatItemView(
                    title: "Highest",
                    value: "\(authService.user?.highestStreak ?? 0)",
                    iconName: "chart.line.uptrend.xyaxis",
                    color: AppTheme.correct
                )
            }
            
            HStack(spacing: 12) {
                StatItemView(
                    title: "Correct",
                    value: "\(authService.user?.correctGuesses ?? 0)",
                    iconName: "checkmark.circle.fill",
                    color: AppTheme.correct
                )
                
                StatItemView(
                    title: "Total",
                    value: "\(authService.user?.totalGuesses ?? 0)",
                    iconName: "number.circle.fill",
                    color: AppTheme.primary
                )
                
                if let correctGuesses = authService.user?.correctGuesses, 
                   let totalGuesses = authService.user?.totalGuesses,
                   totalGuesses > 0 {
                    let accuracy = Double(correctGuesses) / Double(totalGuesses) * 100
                    StatItemView(
                        title: "Accuracy",
                        value: String(format: "%.1f%%", accuracy),
                        iconName: "percent",
                        color: AppTheme.tertiary
                    )
                } else {
                    StatItemView(
                        title: "Accuracy",
                        value: "0%",
                        iconName: "percent",
                        color: AppTheme.tertiary
                    )
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(AppTheme.cardBackground)
        )
        .floatingCardStyle()
    }
    
    private var awardsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            // Header with title and "See All" button
            HStack {
                Text("Awards")
                    .font(AppTheme.subheading())
                    .foregroundColor(AppTheme.textPrimary)
                
                Spacer()
                
                Button(action: {
                    showAllAchievements = true
                }) {
                    Text("See All")
                        .font(AppTheme.caption())
                        .foregroundColor(AppTheme.primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(AppTheme.primary.opacity(0.1))
                        )
                }
                .buttonStyle(ScaleButtonStyle())
            }
            
            // Awards grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 15) {
                ForEach(Achievement.allAchievements.prefix(6), id: \.id) { achievement in
                    AwardBadgeView(
                        achievement: achievement,
                        isEarned: authService.user?.achievements.contains(achievement.id) ?? false,
                        progress: calculateProgress(for: achievement)
                    )
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(AppTheme.cardBackground)
        )
        .floatingCardStyle()
    }
    
    private func calculateProgress(for achievement: Achievement) -> Double {
        guard let user = authService.user else { return 0 }
        
        switch achievement.type {
        case .correctGuesses:
            return min(1.0, Double(user.correctGuesses) / Double(achievement.requirement))
        case .streak:
            let current = max(user.highestStreak, user.streak)
            return min(1.0, Double(current) / Double(achievement.requirement))
        case .totalGuesses:
            return min(1.0, Double(user.totalGuesses) / Double(achievement.requirement))
        }
    }
}

struct StatItemView: View {
    let title: String
    let value: String
    let iconName: String
    let color: Color
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: iconName)
                .foregroundColor(color)
                .font(.system(size: 24))
                .scaleEffect(isAnimating ? 1.1 : 1.0)
                .animation(
                    Animation.springy
                        .repeatCount(1),
                    value: isAnimating
                )
            
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(AppTheme.textPrimary)
                .padding(.vertical, 2)
            
            Text(title)
                .font(AppTheme.caption())
                .foregroundColor(AppTheme.textSecondary)
        }
        .fillWidth()
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppTheme.cardBackground)
                .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 2)
        )
        .onAppear {
            // Add a slight delay before animating
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isAnimating = true
            }
        }
    }
}

#Preview {
    let authService = AuthenticationService()
    let gameManager = GameManager()
    return HomeView()
        .environmentObject(authService)
        .environmentObject(gameManager)
        .environmentObject(NavigationCoordinator(authService: authService))
} 