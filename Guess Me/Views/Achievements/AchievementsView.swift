import SwiftUI

struct AchievementsView: View {
    @EnvironmentObject var authService: AuthenticationService
    @State private var showAll = false
    @State private var animateBackground = false
    
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
                    VStack(alignment: .leading, spacing: 25) {
                        achievementsSummary
                        
                        Divider()
                            .background(AppTheme.textSecondary.opacity(0.2))
                            .padding(.horizontal)
                        
                        achievementsList
                    }
                    .padding(.vertical, 15)
                }
                .navigationTitle("Achievements")
                .navigationBarTitleDisplayMode(.large)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(showAll ? "Show Earned" : "Show All") {
                            withAnimation(.bouncy) {
                                showAll.toggle()
                            }
                        }
                        .foregroundColor(AppTheme.primary)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(
                            Capsule()
                                .fill(AppTheme.primary.opacity(0.1))
                        )
                        .buttonStyle(ScaleButtonStyle())
                    }
                }
            }
        }
    }
    
    private var achievementsSummary: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Your Progress")
                .font(AppTheme.subheading())
                .foregroundColor(AppTheme.textPrimary)
                .padding(.bottom, 5)
            
            let earnedCount = authService.user?.achievements.count ?? 0
            let totalCount = Achievement.allAchievements.count
            
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("\(earnedCount) of \(totalCount)")
                        .font(AppTheme.heading())
                        .foregroundColor(AppTheme.textPrimary)
                    
                    Text("Achievements Earned")
                        .font(AppTheme.body())
                        .foregroundColor(AppTheme.textSecondary)
                }
                
                Spacer()
                
                ZStack {
                    Circle()
                        .stroke(AppTheme.textSecondary.opacity(0.2), lineWidth: 10)
                        .frame(width: 80, height: 80)
                    
                    Circle()
                        .trim(from: 0, to: earnedCount == 0 ? 0.001 : CGFloat(earnedCount) / CGFloat(totalCount))
                        .stroke(
                            LinearGradient(
                                colors: [AppTheme.primary, AppTheme.secondary],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            style: StrokeStyle(lineWidth: 10, lineCap: .round)
                        )
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(-90))
                    
                    Text("\(Int(Double(earnedCount) / Double(totalCount) * 100))%")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(AppTheme.primary)
                }
            }
            
            if earnedCount == 0 {
                Text("Start playing to earn achievements!")
                    .font(AppTheme.caption())
                    .foregroundColor(AppTheme.textSecondary)
                    .padding(.top, 5)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(AppTheme.cardBackground)
        )
        .floatingCardStyle()
        .padding(.horizontal, 15)
    }
    
    private var achievementsList: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text(showAll ? "All Achievements" : "Your Achievements")
                .font(AppTheme.subheading())
                .foregroundColor(AppTheme.textPrimary)
                .padding(.horizontal, 15)
                .padding(.bottom, 5)
            
            if showAll {
                // Show all achievements
                ForEach(Achievement.allAchievements, id: \.id) { achievement in
                    achievementRow(achievement)
                        .transition(.opacity)
                }
            } else {
                // Show only earned achievements
                if let userAchievements = authService.user?.achievements, !userAchievements.isEmpty {
                    ForEach(userAchievements, id: \.self) { achievementId in
                        if let achievement = Achievement.allAchievements.first(where: { $0.id == achievementId }) {
                            achievementRow(achievement, earned: true)
                                .transition(.opacity)
                        }
                    }
                } else {
                    emptyAchievementsView
                }
            }
        }
    }
    
    private var emptyAchievementsView: some View {
        VStack(spacing: 20) {
            Image(systemName: "trophy")
                .font(.system(size: 60))
                .foregroundColor(AppTheme.textSecondary.opacity(0.3))
                .padding(.top, 20)
            
            Text("You haven't earned any achievements yet")
                .font(AppTheme.body())
                .foregroundColor(AppTheme.textPrimary)
                .multilineTextAlignment(.center)
            
            Text("Start playing to earn some!")
                .font(AppTheme.caption())
                .foregroundColor(AppTheme.textSecondary)
                .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(AppTheme.cardBackground)
        )
        .floatingCardStyle()
        .padding(.horizontal, 15)
    }
    
    private func achievementRow(_ achievement: Achievement, earned: Bool = false) -> some View {
        let isEarned = authService.user?.achievements.contains(achievement.id) ?? false
        let gradientColor = AppTheme.primary.opacity(0.7)
        
        return HStack(spacing: 15) {
            // Achievement icon
            ZStack {
                Circle()
                    .fill(isEarned ? gradientColor : AppTheme.textSecondary.opacity(0.1))
                    .frame(width: 50, height: 50)
                
                Image(systemName: achievement.imageName)
                    .font(.system(size: 22))
                    .foregroundColor(isEarned ? AppTheme.textOnDark : AppTheme.textSecondary)
            }
            .shadow(color: isEarned ? AppTheme.primary.opacity(0.3) : Color.clear, radius: 5)
            
            // Achievement details
            VStack(alignment: .leading, spacing: 4) {
                Text(achievement.name)
                    .font(AppTheme.body())
                    .foregroundColor(isEarned ? AppTheme.textPrimary : AppTheme.textSecondary)
                
                Text(achievement.description)
                    .font(AppTheme.caption())
                    .foregroundColor(AppTheme.textSecondary)
                
                if !isEarned && showAll {
                    HStack {
                        Text(progressText(for: achievement))
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundColor(AppTheme.primary)
                        
                        // Progress bar
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(AppTheme.textSecondary.opacity(0.2))
                                    .frame(height: 4)
                                
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(
                                        LinearGradient(
                                            colors: [AppTheme.primary, AppTheme.secondary],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: progressWidth(for: achievement, totalWidth: geometry.size.width), height: 4)
                            }
                        }
                        .frame(height: 4)
                        .padding(.top, 4)
                    }
                }
            }
            
            Spacer()
            
            // Checkmark for earned achievements
            if isEarned {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(AppTheme.correct)
                    .font(.system(size: 22))
            }
        }
        .padding(15)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppTheme.cardBackground)
                .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 2)
        )
        .padding(.horizontal, 15)
        .opacity(isEarned ? 1.0 : 0.8)
    }
    
    private func progressText(for achievement: Achievement) -> String {
        guard let user = authService.user else { return "" }
        
        switch achievement.type {
        case .correctGuesses:
            return "\(user.correctGuesses)/\(achievement.requirement)"
        case .streak:
            let current = max(user.highestStreak, user.streak)
            return "\(current)/\(achievement.requirement)"
        case .totalGuesses:
            return "\(user.totalGuesses)/\(achievement.requirement)"
        }
    }
    
    private func progressWidth(for achievement: Achievement, totalWidth: CGFloat) -> CGFloat {
        guard let user = authService.user else { return 0 }
        
        var progress: Double = 0
        
        switch achievement.type {
        case .correctGuesses:
            progress = min(1.0, Double(user.correctGuesses) / Double(achievement.requirement))
        case .streak:
            let current = max(user.highestStreak, user.streak)
            progress = min(1.0, Double(current) / Double(achievement.requirement))
        case .totalGuesses:
            progress = min(1.0, Double(user.totalGuesses) / Double(achievement.requirement))
        }
        
        return CGFloat(progress) * totalWidth
    }
}

#Preview {
    AchievementsView()
        .environmentObject(AuthenticationService())
} 