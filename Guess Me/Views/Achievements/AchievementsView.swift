import SwiftUI

struct AchievementsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authService: AuthenticationService
    @State private var showAllAwards = true
    @State private var animateBackground = false
    
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
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 15) {
            ForEach(showAllAwards ? Achievement.allAchievements : Achievement.allAchievements.filter { authService.user?.achievements.contains($0.id) ?? false }, id: \.id) { achievement in
                AwardBadgeView(
                    achievement: achievement,
                    isEarned: authService.user?.achievements.contains(achievement.id) ?? false,
                    progress: calculateProgress(for: achievement)
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

#Preview {
    AchievementsView()
        .environmentObject(AuthenticationService())
} 