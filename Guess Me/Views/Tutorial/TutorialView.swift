import SwiftUI

struct TutorialView: View {
    @EnvironmentObject var navigationCoordinator: NavigationCoordinator
    @State private var currentPage = 0
    @State private var animateBackground = false
    
    // Tutorial slides data
    private let slides = [
        TutorialSlide(
            title: "Welcome to GuessMe!",
            description: "GuessMe is a social guessing game where you can learn about others and let others guess about you.",
            imageName: "person.fill.questionmark",
            backgroundColor: AppTheme.primary
        ),
        TutorialSlide(
            title: "How It Works",
            description: "Create your profile, add your traits, and let others guess about you. You'll also get to guess about others!",
            imageName: "person.2.fill",
            backgroundColor: AppTheme.tertiary
        ),
        TutorialSlide(
            title: "Your Profile",
            description: "Set up your profile with basic information, photos, and traits. The more accurate your profile, the more fun the game becomes!",
            imageName: "person.crop.circle.badge.checkmark",
            backgroundColor: AppTheme.secondary
        ),
        TutorialSlide(
            title: "Guessing Game",
            description: "Browse profiles, make guesses about others, and see how well you know people based on their photos and traits.",
            imageName: "questionmark.circle.fill",
            backgroundColor: AppTheme.accent
        ),
        TutorialSlide(
            title: "Ready to Start?",
            description: "Let's set up your profile and begin your GuessMe journey!",
            imageName: "arrow.right.circle.fill",
            backgroundColor: AppTheme.primary
        )
    ]
    
    var body: some View {
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
            
            VStack(spacing: 0) {
                // Top navigation bar with back/exit button
                HStack {
                    if currentPage > 0 {
                        Button(action: {
                            // Go to previous slide
                            withAnimation(.springy) {
                                currentPage -= 1
                            }
                        }) {
                            HStack {
                                Image(systemName: "chevron.left")
                                Text("Back")
                            }
                            .foregroundColor(AppTheme.textOnDark)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(
                                Capsule()
                                    .fill(AppTheme.textOnDark.opacity(0.2))
                            )
                        }
                        .buttonStyle(ScaleButtonStyle())
                    } else {
                        // On first slide, show "Exit" button to go back to auth
                        Button(action: {
                            // Go back to auth view
                            navigationCoordinator.navigateBack()
                        }) {
                            HStack {
                                Image(systemName: "xmark")
                                Text("Exit")
                            }
                            .foregroundColor(AppTheme.textOnDark)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(
                                Capsule()
                                    .fill(AppTheme.textOnDark.opacity(0.2))
                            )
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                    
                    Spacer()
                    
                    // Skip button
                    Button("Skip") {
                        // Skip tutorial and go to profile setup
                        withAnimation(.bouncy) {
                            navigationCoordinator.navigateToProfileSetup()
                        }
                    }
                    .foregroundColor(AppTheme.textOnDark)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    .background(
                        Capsule()
                            .fill(AppTheme.textOnDark.opacity(0.2))
                    )
                    .buttonStyle(ScaleButtonStyle())
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                // Page indicator
                HStack {
                    ForEach(0..<slides.count, id: \.self) { index in
                        RoundedRectangle(cornerRadius: 4)
                            .fill(currentPage == index ? 
                                AppTheme.textOnDark : 
                                AppTheme.textOnDark.opacity(0.3))
                            .frame(width: currentPage == index ? 20 : 8, height: 8)
                            .animation(.springy, value: currentPage)
                    }
                }
                .padding(.top, 16)
                .padding(.bottom, 20)
                
                // Current slide content
                TabView(selection: $currentPage) {
                    ForEach(0..<slides.count, id: \.self) { index in
                        TutorialSlideView(slide: slides[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .frame(height: 500)
                .animation(.gentle, value: currentPage)
                
                Spacer()
                
                // Next button
                Button(action: {
                    if currentPage < slides.count - 1 {
                        withAnimation(.springy) {
                            currentPage += 1
                        }
                    } else {
                        // Navigate to profile setup on last slide
                        withAnimation(.bouncy) {
                            navigationCoordinator.navigateToProfileSetup()
                        }
                    }
                }) {
                    Text(currentPage < slides.count - 1 ? "Next" : "Get Started")
                        .font(.system(.body, design: .rounded, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(AppTheme.secondary)
                                .shadow(color: AppTheme.secondary.opacity(0.4), radius: 8, x: 0, y: 4)
                        )
                        .foregroundColor(AppTheme.textOnDark)
                }
                .buttonStyle(ScaleButtonStyle())
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
            .padding(.vertical, 10)
        }
        .navigationBarHidden(true)
    }
}

struct TutorialSlide: Identifiable {
    var id = UUID()
    var title: String
    var description: String
    var imageName: String
    var backgroundColor: Color
}

struct TutorialSlideView: View {
    var slide: TutorialSlide
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 30) {
            // Image area
            ZStack {
                Circle()
                    .fill(AppTheme.textOnDark.opacity(0.15))
                    .frame(width: 180, height: 180)
                
                Image(systemName: slide.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .foregroundColor(AppTheme.textOnDark)
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                    .scaleEffect(isAnimating ? 1.1 : 1.0)
            }
            .padding()
            .onAppear {
                withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                    isAnimating = true
                }
            }
            
            // Text content
            VStack(spacing: 20) {
                Text(slide.title)
                    .font(AppTheme.heading())
                    .foregroundColor(AppTheme.textOnDark)
                    .multilineTextAlignment(.center)
                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                
                Text(slide.description)
                    .font(AppTheme.body())
                    .multilineTextAlignment(.center)
                    .foregroundColor(AppTheme.textOnDark.opacity(0.9))
                    .padding(.horizontal, 30)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 30)
        .background(
            RoundedRectangle(cornerRadius: 30)
                .fill(slide.backgroundColor.opacity(0.2))
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
        )
        .padding(.horizontal, 20)
    }
}

#Preview {
    let authService = AuthenticationService()
    return TutorialView()
        .environmentObject(NavigationCoordinator(authService: authService))
} 
