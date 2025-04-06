import SwiftUI

struct AwardBadgeView: View {
    let achievement: Achievement
    let isEarned: Bool
    let progress: Double
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 8) {
            // Badge icon
            ZStack {
                Circle()
                    .fill(isEarned ? 
                          LinearGradient(
                            colors: [getColorForAchievement(type: achievement.type), 
                                    getColorForAchievement(type: achievement.type).opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                          ) : 
                          LinearGradient(
                            colors: [AppTheme.textSecondary.opacity(0.1), 
                                    AppTheme.textSecondary.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                          )
                    )
                    .frame(width: 70, height: 70)
                    .shadow(color: isEarned ? 
                            getColorForAchievement(type: achievement.type).opacity(0.3) : 
                            Color.clear, 
                           radius: 5)
                
                Image(systemName: achievement.imageName)
                    .font(.system(size: 28))
                    .foregroundColor(isEarned ? AppTheme.textOnDark : AppTheme.textSecondary)
                    .scaleEffect(isAnimating ? 1.1 : 1.0)
                    .animation(
                        Animation.spring(response: 0.5, dampingFraction: 0.6)
                            .repeatCount(1),
                        value: isAnimating
                    )
                
                if !isEarned {
                    // Lock overlay for unearned badges
                    Circle()
                        .stroke(AppTheme.textSecondary.opacity(0.3), lineWidth: 2)
                        .frame(width: 70, height: 70)
                }
            }
            
            // Achievement name
            Text(achievement.name)
                .font(AppTheme.caption())
                .foregroundColor(isEarned ? AppTheme.textPrimary : AppTheme.textSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(height: 32)
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(AppTheme.textSecondary.opacity(0.2))
                        .frame(height: 4)
                    
                    RoundedRectangle(cornerRadius: 2)
                        .fill(
                            LinearGradient(
                                colors: [getColorForAchievement(type: achievement.type), 
                                        getColorForAchievement(type: achievement.type).opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * CGFloat(progress), height: 4)
                }
            }
            .frame(height: 4)
            
            // Progress text
            Text("\(Int(progress * 100))%")
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundColor(getColorForAchievement(type: achievement.type))
        }
        .padding(.vertical, 8)
        .onAppear {
            if isEarned {
                // Add a slight delay before animating
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    isAnimating = true
                }
            }
        }
    }
    
    private func getColorForAchievement(type: Achievement.AchievementType) -> Color {
        switch type {
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
    AwardBadgeView(
        achievement: Achievement.allAchievements[0],
        isEarned: true,
        progress: 0.7
    )
    .padding()
    .background(Color.gray.opacity(0.1))
} 