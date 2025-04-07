import SwiftUI

struct GameQuestionCard: View {
    let question: Question
    let onAnswerSelected: (Int) -> Void
    @State private var selectedAnswerIndex: Int? = nil
    @State private var isAnimating = false
    @State private var isCardAnimating = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Question header with icon
            HStack(spacing: 12) {
                Image(systemName: getQuestionIcon(for: question.type))
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(getQuestionColor(for: question.type))
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(getQuestionColor(for: question.type).opacity(0.15))
                    )
                    .accessibilityLabel("\(question.type.rawValue) question")
                
                Text(question.type.rawValue)
                    .font(AppTheme.subheading())
                    .foregroundColor(AppTheme.textSecondary)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            
            // User profile image
            ZStack {
                if let imageURL = question.userProfileImageURL, !imageURL.isEmpty {
                    AsyncImage(url: URL(string: imageURL)) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .profileImageStyle(size: 140)
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .profileImageStyle(size: 140, borderWidth: 3)
                        case .failure:
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .foregroundColor(AppTheme.secondary)
                                .frame(width: 140, height: 140)
                        @unknown default:
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .foregroundColor(AppTheme.secondary)
                                .frame(width: 140, height: 140)
                        }
                    }
                    .accessibilityLabel("Profile image")
                } else {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .foregroundColor(AppTheme.secondary)
                        .frame(width: 140, height: 140)
                        .accessibilityLabel("Profile image placeholder")
                }
            }
            .frame(width: 140, height: 140)
            .padding(.vertical, 12)
            
            // Question text
            Text(question.text)
                .font(AppTheme.heading())
                .foregroundColor(AppTheme.textPrimary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
                .scaleEffect(isAnimating ? 1.02 : 1.0)
                .animation(
                    Animation.gentle
                        .repeatForever(autoreverses: true),
                    value: isAnimating
                )
            
            // Answer options
            VStack(spacing: 12) {
                ForEach(0..<question.choices.count, id: \.self) { index in
                    Button {
                        withAnimation(.springy) {
                            selectedAnswerIndex = index
                        }
                        
                        // Delay the answer processing slightly to show the selection animation
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            onAnswerSelected(index)
                            
                            // Reset selection state after a short delay
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                selectedAnswerIndex = nil
                            }
                        }
                    } label: {
                        HStack {
                            Text(question.choices[index])
                                .font(AppTheme.body())
                                .foregroundColor(selectedAnswerIndex == index ? AppTheme.textOnDark : AppTheme.textPrimary)
                            
                            Spacer()
                            
                            if selectedAnswerIndex == index {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(AppTheme.textOnDark)
                                    .transition(.scale.combined(with: .opacity))
                            }
                        }
                        .padding(.vertical, 14)
                        .padding(.horizontal, 20)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(
                                    selectedAnswerIndex == index ? 
                                    AppTheme.primary : 
                                    AppTheme.cardBackground
                                )
                                .shadow(
                                    color: selectedAnswerIndex == index ? 
                                    AppTheme.primary.opacity(0.25) : 
                                    Color.black.opacity(0.05),
                                    radius: selectedAnswerIndex == index ? 6 : 2,
                                    x: 0, 
                                    y: selectedAnswerIndex == index ? 2 : 1
                                )
                        )
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .disabled(selectedAnswerIndex != nil)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
        }
        .padding(.vertical, 24)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(AppTheme.cardBackground)
                .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 6)
        )
        .floatingCardStyle()
        .rotatingCardStyle(rotationAmount: 1.0, duration: 4)
        .onAppear {
            isAnimating = true
            isCardAnimating = true
        }
    }
    
    private func getQuestionIcon(for type: Question.QuestionType) -> String {
        switch type {
        case .age:
            return "calendar.circle.fill"
        case .occupation:
            return "briefcase.fill"
        case .education:
            return "graduationcap.fill"
        case .height:
            return "ruler.fill"
        case .weight:
            return "scalemass.fill"
        case .smoker:
            return "smoke.fill"
        case .favoriteColor:
            return "paintpalette.fill"
        case .favoriteMovie:
            return "film.fill"
        case .favoriteFood:
            return "fork.knife"
        case .favoriteFlower:
            return "leaf.fill"
        case .favoriteSport:
            return "sportscourt.fill"
        case .favoriteHobby:
            return "heart.fill"
        }
    }
    
    private func getQuestionColor(for type: Question.QuestionType) -> Color {
        switch type {
        case .age:
            return AppTheme.tertiary
        case .occupation:
            return AppTheme.primary
        case .education:
            return AppTheme.accent
        case .height:
            return AppTheme.secondary
        case .weight:
            return AppTheme.correct
        case .smoker:
            return Color.orange
        case .favoriteColor:
            return Color.purple
        case .favoriteMovie:
            return Color.indigo
        case .favoriteFood:
            return Color.orange
        case .favoriteFlower:
            return Color.pink
        case .favoriteSport:
            return Color.green
        case .favoriteHobby:
            return Color.red
        }
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

#Preview {
    GameQuestionCard(
        question: Question(
            type: .age,
            text: "How old do you think Sarah is?",
            choices: ["25", "28", "32", "35"],
            correctAnswer: "28"
        ),
        onAnswerSelected: { _ in }
    )
    .padding(20)
    .background(AppTheme.background)
} 