import SwiftUI

struct TutorialView: View {
    @EnvironmentObject var navigationCoordinator: NavigationCoordinator
    @State private var currentPage = 0
    @State private var animateBackground = false
    
    // Tutorial slides data
    private let slides = [
        TutorialSlide(
            title: "Welcome to MugMatch! 🎮",
            description: "Ready for a wild ride? Discover just how mysterious you really are! Let the mind-reading begin! 🧠✨",
            imageName: "person.fill.questionmark",
            backgroundColor: AppTheme.primary
        ),
        TutorialSlide(
            title: "How It Works 🤔",
            description: "Create your profile, add your quirky traits, and watch other players guess about you! Plus, you get to play detective too! 🕵️‍♀️",
            imageName: "person.2.fill",
            backgroundColor: AppTheme.tertiary
        ),
        TutorialSlide(
            title: "Your Profile 🌟",
            description: "Time to shine! Add your pics and traits. The more authentic your profile, the more fun the guesses will be!",
            imageName: "person.crop.circle.badge.checkmark",
            backgroundColor: AppTheme.secondary
        ),
        TutorialSlide(
            title: "Guessing Game 🎯",
            description: "Browse profiles, make wild guesses, and see if you're psychic or hilariously clueless! Are you the ultimate people-reader?",
            imageName: "questionmark.circle.fill",
            backgroundColor: AppTheme.accent
        ),
        TutorialSlide(
            title: "Stay Safe & Awesome 🛡️",
            description: "Keep it clean! Upload appropriate photos and be respectful. Together we'll create a positive community for everyone.",
            imageName: "shield.fill",
            backgroundColor: AppTheme.tertiary
        ),
        TutorialSlide(
            title: "Ready to Rock? 🚀",
            description: "Let's set up your profile and dive into the wacky world of MugMatch! Other players will love guessing about you!",
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
        VStack(spacing: 20) {
            // Image area
            ZStack {
                Circle()
                    .fill(AppTheme.textOnDark.opacity(0.15))
                    .frame(width: 160, height: 160)
                
                Image(systemName: slide.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 90, height: 90)
                    .foregroundColor(AppTheme.textOnDark)
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                    .scaleEffect(isAnimating ? 1.1 : 1.0)
            }
            .padding(.top)
            .onAppear {
                withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                    isAnimating = true
                }
            }
            
            // Text content
            VStack(spacing: 16) {
                Text(slide.title)
                    .font(AppTheme.heading())
                    .foregroundColor(AppTheme.textOnDark)
                    .multilineTextAlignment(.center)
                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                
                Text(slide.description)
                    .font(AppTheme.body())
                    .multilineTextAlignment(.center)
                    .foregroundColor(AppTheme.textOnDark.opacity(0.9))
                    .padding(.horizontal, 20)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.bottom, 10)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 30)
                .fill(slide.backgroundColor.opacity(0.2))
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
        )
        .padding(.horizontal, 16)
    }
}

#Preview {
    let authService = AuthenticationService()
    return TutorialView()
        .environmentObject(NavigationCoordinator(authService: authService))
} 
