import SwiftUI

struct AwardBadgeView: View {
    let achievement: Achievement
    let isEarned: Bool
    let progress: Double
    @State private var animateContent = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Achievement Icon with animated glow
            ZStack {
                // Animated glow for earned achievements
                if isEarned {
                    Circle()
                        .fill(getAchievementColor().opacity(0.3))
                        .frame(width: 120, height: 120)
                        .blur(radius: 20)
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
            }
            .offset(y: animateContent ? 0 : 20)
            .opacity(animateContent ? 1 : 0)
        }
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(AppTheme.cardBackground.opacity(0.98))
                .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 10)
        )
        .padding(24)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                animateContent = true
            }
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