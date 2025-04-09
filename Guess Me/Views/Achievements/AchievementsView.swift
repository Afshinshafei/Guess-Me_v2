import SwiftUI

struct AchievementsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authService: AuthenticationService
    @State private var showAllAwards = true
    @State private var animateBackground = false
    @State private var selectedAchievement: Achievement? = nil
    @State private var showAchievementDetails = false
    
    private var earnedCount: Int {
        authService.user?.achievements.count ?? 0
    }
    
    private var totalCount: Int {
        Achievement.allAchievements.count
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Animated gradient background
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
                
                ScrollView {
                    VStack(spacing: 25) {
                        // Summary section
                        summarySection
                        
                        // Filter toggle
                        filterToggle
                        
                        // Awards grid
                        awardsGrid
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 15)
                }
            }
            .navigationTitle("Awards")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(AppTheme.textSecondary)
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showAchievementDetails) {
                if let achievement = selectedAchievement {
                    AchievementDetailView(achievement: achievement, isEarned: authService.user?.achievements.contains(achievement.id) ?? false, progress: calculateProgress(for: achievement))
                }
            }
        }
    }
    
    private var summarySection: some View {
        VStack(spacing: 15) {
            Text("Your Awards")
                .font(AppTheme.heading())
                .foregroundColor(AppTheme.textPrimary)
            
            HStack(spacing: 20) {
                // Progress circle
                ZStack {
                    Circle()
                        .stroke(AppTheme.cardBackground, lineWidth: 8)
                        .frame(width: 80, height: 80)
                    
                    Circle()
                        .trim(from: 0, to: CGFloat(earnedCount) / CGFloat(totalCount))
                        .stroke(AppTheme.primary, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(-90))
                    
                    VStack(spacing: 2) {
                        Text("\(earnedCount)")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(AppTheme.textPrimary)
                        
                        Text("of \(totalCount)")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(AppTheme.textSecondary)
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Keep playing to earn more awards!")
                        .font(AppTheme.body())
                        .foregroundColor(AppTheme.textPrimary)
                    
                    Text("Awards are earned by reaching specific milestones in your gameplay.")
                        .font(AppTheme.caption())
                        .foregroundColor(AppTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
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
    
    private var filterToggle: some View {
        HStack {
            Button(action: {
                withAnimation {
                    showAllAwards = true
                }
            }) {
                Text("All Awards")
                    .font(AppTheme.body())
                    .foregroundColor(showAllAwards ? AppTheme.textPrimary : AppTheme.textSecondary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(showAllAwards ? AppTheme.primary.opacity(0.1) : AppTheme.cardBackground)
                    )
            }
            
            Button(action: {
                withAnimation {
                    showAllAwards = false
                }
            }) {
                Text("Your Awards")
                    .font(AppTheme.body())
                    .foregroundColor(!showAllAwards ? AppTheme.textPrimary : AppTheme.textSecondary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(!showAllAwards ? AppTheme.primary.opacity(0.1) : AppTheme.cardBackground)
                    )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(AppTheme.cardBackground)
        )
        .floatingCardStyle()
    }
    
    private var awardsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 20) {
            ForEach(showAllAwards ? Achievement.allAchievements : Achievement.allAchievements.filter { 
                authService.user?.achievements.contains($0.id) ?? false 
            }, id: \.id) { achievement in
                AchievementBadgeView(
                    achievement: achievement,
                    isEarned: authService.user?.achievements.contains(achievement.id) ?? false,
                    progress: calculateProgress(for: achievement)
                )
                .frame(height: 160)
                .onLongPressGesture(minimumDuration: 0.5) {
                    // Haptic feedback for better user experience
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    
                    // Show achievement details
                    selectedAchievement = achievement
                    showAchievementDetails = true
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

struct AchievementDetailView: View {
    let achievement: Achievement
    let isEarned: Bool
    let progress: Double
    @Environment(\.dismiss) private var dismiss
    @State private var animateContent = false
    @State private var animateGlow = false
    
    var body: some View {
        ZStack {
            // Blurred background
            Color.black.opacity(0.2)
                .ignoresSafeArea()
                .blur(radius: 20)
            
            VStack(spacing: 24) {
                // Achievement Icon with animated glow
                ZStack {
                    if isEarned {
                        Circle()
                            .fill(getAchievementColor().opacity(0.3))
                            .frame(width: 120, height: 120)
                            .blur(radius: 20)
                            .scaleEffect(animateGlow ? 1.2 : 1.0)
                            .opacity(animateGlow ? 0.6 : 0.3)
                    }
                    
                    Image(systemName: achievement.imageName)
                        .font(.system(size: 50))
                        .foregroundColor(isEarned ? getAchievementColor() : AppTheme.textSecondary)
                        .frame(width: 100, height: 100)
                        .background(
                            Circle()
                                .fill(isEarned ? getAchievementColor().opacity(0.2) : AppTheme.cardBackground)
                        )
                }
                .scaleEffect(animateContent ? 1 : 0.5)
                .opacity(animateContent ? 1 : 0)
                
                // Achievement details
                VStack(spacing: 16) {
                    Text(achievement.name)
                        .font(AppTheme.heading())
                        .foregroundColor(AppTheme.textPrimary)
                        .multilineTextAlignment(.center)
                    
                    Text(achievement.description)
                        .font(AppTheme.body())
                        .foregroundColor(AppTheme.textSecondary)
                        .multilineTextAlignment(.center)
                    
                    // Progress section
                    VStack(spacing: 8) {
                        ProgressView(value: progress)
                            .tint(getAchievementColor())
                            .frame(maxWidth: 200)
                        
                        Text("\(Int(progress * 100))% Complete")
                            .font(AppTheme.caption())
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    .padding(.top, 8)
                    
                    // Requirement details
                    Text(requirementText)
                        .font(AppTheme.caption())
                        .foregroundColor(AppTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 8)
                }
                .offset(y: animateContent ? 0 : 20)
                .opacity(animateContent ? 1 : 0)
                
                // Close button
                Button(action: { dismiss() }) {
                    Text("Close")
                        .font(AppTheme.body())
                        .foregroundColor(AppTheme.textPrimary)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 24)
                        .background(
                            Capsule()
                                .fill(AppTheme.cardBackground)
                                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                        )
                }
                .padding(.top, 16)
                .offset(y: animateContent ? 0 : 40)
                .opacity(animateContent ? 1 : 0)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(AppTheme.cardBackground.opacity(0.98))
                    .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 10)
            )
            .padding(24)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                animateContent = true
            }
            if isEarned {
                withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                    animateGlow = true
                }
            }
        }
    }
    
    private var requirementText: String {
        switch achievement.type {
        case .correctGuesses:
            return "Correct Guesses Required: \(achievement.requirement)"
        case .streak:
            return "Consecutive Correct Guesses Required: \(achievement.requirement)"
        case .totalGuesses:
            return "Total Guesses Required: \(achievement.requirement)"
        }
    }
    
    private func getAchievementColor() -> Color {
        switch achievement.type {
        case .correctGuesses:
            return AppTheme.correct
        case .streak:
            return AppTheme.accent
        case .totalGuesses:
            return AppTheme.primary
        }
    }
}

#Preview {
    AchievementsView()
        .environmentObject(AuthenticationService())
} 