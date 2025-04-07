import SwiftUI
import Combine
import UIKit
import GoogleMobileAds

class GameViewModel: ObservableObject {
    @Published var targetUsers: [User] = []
    @Published var currentIndex = 0
    @Published var currentQuestion: Question?
    @Published var isLoading = true
    @Published var error: Error?
    @Published var showSuccessAnimation = false
    @Published var showFailureAnimation = false
    @Published var showNewAchievementAlert = false
    @Published var newAchievements: [Achievement] = []
    @Published var isLoadingNextUser = false
    @Published var selectedAnswer: String?
    
    var authService: AuthenticationService
    var gameManager: GameManager
    private var cancellables = Set<AnyCancellable>()
    
    init(authService: AuthenticationService, gameManager: GameManager) {
        self.authService = authService
        self.gameManager = gameManager
    }
    
    func updateServices(authService: AuthenticationService, gameManager: GameManager) {
        self.authService = authService
        self.gameManager = gameManager
    }
    
    func loadUsers() {
        guard let currentUser = authService.user else {
            error = NSError(domain: "GameView", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not logged in"])
            isLoading = false
            return
        }
        
        isLoading = true
        error = nil
        
        UserService.shared.fetchRandomUsers(excluding: currentUser.id ?? "", limit: 10)
            .receive(on: DispatchQueue.main)
            .sink { completion in
                self.isLoading = false
                
                if case .failure(let fetchError) = completion {
                    self.error = fetchError
                }
            } receiveValue: { users in
                self.targetUsers = users
                
                if !users.isEmpty {
                    self.currentIndex = 0
                    self.generateQuestion()
                }
            }
            .store(in: &cancellables)
    }
    
    func generateQuestion() {
        guard currentIndex < targetUsers.count else { return }
        
        if let question = QuestionManager.generateQuestion(for: targetUsers[currentIndex]) {
            currentQuestion = question
            selectedAnswer = nil
        } else {
            // If we can't generate a question for this user, move to the next one
            currentIndex += 1
            if currentIndex < targetUsers.count {
                generateQuestion()
            }
        }
    }
    
    func checkAnswer(_ answer: String) {
        guard let question = currentQuestion,
              let currentUser = authService.user,
              let currentUserId = currentUser.id else {
            return
        }
        
        // Check if we have lives left
        if gameManager.lives <= 0 {
            // If we're out of lives, make sure the game is marked as over
            gameManager.isGameOver = true
            return
        }
        
        let isCorrect = answer == question.correctAnswer
        
        // Use a life for wrong answers
        if !isCorrect {
            _ = gameManager.useLife()
            gameManager.resetStreak()
            
            // Show failure animation
            withAnimation {
                showFailureAnimation = true
            }
            
            // Hide animation after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation {
                    self.showFailureAnimation = false
                }
                
                self.moveToNextProfile()
            }
        } else {
            // For correct answers
            let points = 10 * (gameManager.currentStreak + 1) // Points increase with streak
            gameManager.incrementStreak()
            
            // Update game manager score
            gameManager.score += points
            gameManager.correctAnswers += 1
            
            // Show success animation
            withAnimation {
                showSuccessAnimation = true
            }
            
            // Update user score in Firestore
            UserService.shared.updateUserScore(uid: currentUserId, points: points, isCorrect: true)
                .receive(on: DispatchQueue.main)
                .sink { completion in
                    if case .failure(let error) = completion {
                        print("Error updating score: \(error)")
                    }
                    
                    // Hide animation after delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        withAnimation {
                            self.showSuccessAnimation = false
                        }
                        
                        self.moveToNextProfile()
                    }
                } receiveValue: { _ in
                    // Check for new achievements
                    self.checkForNewAchievements()
                    
                    // Refresh user data
                    UserService.shared.fetchUser(withUID: currentUserId)
                        .receive(on: DispatchQueue.main)
                        .sink(receiveCompletion: { _ in }, receiveValue: { user in
                            self.authService.user = user
                        })
                        .store(in: &self.cancellables)
                }
                .store(in: &cancellables)
        }
    }
    
    func moveToNextProfile() {
        isLoadingNextUser = true
        
        // Move to next profile
        currentIndex += 1
        
        // Generate new question or load more profiles if needed
        if currentIndex < targetUsers.count {
            generateQuestion()
        } else if gameManager.lives > 0 {
            // Load more profiles when we run out
            loadUsers()
        } else {
            // Game over if we're out of lives
            gameManager.isGameOver = true
            
            // Update last life regeneration time if not already set
            if gameManager.lastLifeRegenTime == nil {
                gameManager.updateLastLifeRegenTime()
            }
        }
        
        isLoadingNextUser = false
    }
    
    func checkForNewAchievements() {
        guard let user = authService.user else { return }
        
        // Get achievements the user might have just earned
        newAchievements = Achievement.allAchievements.filter { achievement in
            // Skip if user already has this achievement
            if user.achievements.contains(achievement.id) {
                return false
            }
            
            var requirementMet = false
            
            switch achievement.type {
            case .correctGuesses:
                requirementMet = (user.correctGuesses + 1) >= achievement.requirement
            case .streak:
                requirementMet = (gameManager.currentStreak) >= achievement.requirement
            case .totalGuesses:
                requirementMet = (user.totalGuesses + 1) >= achievement.requirement
            }
            
            return requirementMet
        }
        
        if !newAchievements.isEmpty {
            showNewAchievementAlert = true
        }
    }
}

struct GameView: View {
    @EnvironmentObject var gameManager: GameManager
    @EnvironmentObject var authService: AuthenticationService
    @Environment(\.dismiss) private var dismiss
    @State private var showExitAlert = false
    @State private var animateBackground = false
    @StateObject private var viewModel: GameViewModel
    @State private var showRewardedAd = false
    @State private var showNoLivesOverlay = false
    
    init() {
        // Initialize with a temporary view model, will be updated in onAppear
        // We'll use the environment objects in onAppear
        _viewModel = StateObject(wrappedValue: GameViewModel(
            authService: AuthenticationService(),
            gameManager: GameManager()
        ))
    }
    
    var body: some View {
        ZStack {
            // Animated gradient background
            GameBackgroundView(animateBackground: $animateBackground)
            
            // Main content
            GameMainContentView(
                viewModel: viewModel,
                gameManager: gameManager,
                showExitAlert: $showExitAlert,
                dismiss: dismiss
            )
            
            // Success animation overlay
            if viewModel.showSuccessAnimation {
                GameSuccessAnimationView()
            }
            
            // Failure animation overlay
            if viewModel.showFailureAnimation {
                GameFailureAnimationView()
            }
            
            // New achievement alert
            if viewModel.showNewAchievementAlert {
                AchievementAlertView(
                    achievements: viewModel.newAchievements,
                    onDismiss: { viewModel.showNewAchievementAlert = false }
                )
            }
            
            // No lives overlay
            if gameManager.lives <= 0 {
                NoLivesOverlayView(
                    timeUntilNextLife: gameManager.timeUntilNextLife(),
                    onWatchAd: {
                        showRewardedAd = true
                    },
                    onExit: {
                        dismiss()
                    }
                )
                .transition(.opacity)
                .zIndex(1) // Ensure it's above other content
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            // Update the view model with the current services
            viewModel.updateServices(authService: authService, gameManager: gameManager)
            
            // Check if we're out of lives
            if gameManager.lives <= 0 {
                gameManager.isGameOver = true
                showNoLivesOverlay = true
                
                // Make sure we start the life regeneration timer if not already started
                if gameManager.lastLifeRegenTime == nil {
                    gameManager.updateLastLifeRegenTime()
                }
            }
            
            // Load users from Firebase
            viewModel.loadUsers()
            
            // Debug print to verify the questions have user profile images
            if !viewModel.targetUsers.isEmpty {
                print("DEBUG: Total users loaded: \(viewModel.targetUsers.count)")
                for (index, user) in viewModel.targetUsers.enumerated() {
                    print("DEBUG: User \(index) image URL: \(user.profileImageURL ?? "none")")
                }
            }
        }
        .fullScreenCover(isPresented: $showRewardedAd) {
            RewardedAdView { success in
                if success {
                    // Reset lives to max when ad is successfully watched
                    gameManager.resetLives()
                    showNoLivesOverlay = false
                }
                showRewardedAd = false
            }
        }
    }
}

// MARK: - Background View
struct GameBackgroundView: View {
    @Binding var animateBackground: Bool
    
    var body: some View {
        LinearGradient(
            colors: [
                AppTheme.primary.opacity(0.7),
                AppTheme.tertiary.opacity(0.5),
                AppTheme.secondary.opacity(0.6)
            ],
            startPoint: animateBackground ? .topLeading : .bottomLeading,
            endPoint: animateBackground ? .bottomTrailing : .topTrailing
        )
        .hueRotation(.degrees(animateBackground ? 30 : 0))
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.linear(duration: 20).repeatForever(autoreverses: true)) {
                animateBackground.toggle()
            }
        }
    }
}

// MARK: - Main Content View
struct GameMainContentView: View {
    @ObservedObject var viewModel: GameViewModel
    @ObservedObject var gameManager: GameManager
    @Binding var showExitAlert: Bool
    let dismiss: DismissAction
    
    var body: some View {
        VStack(spacing: 0) {
            // Game header
            GameHeaderView(
                currentQuestion: viewModel.currentIndex + 1,
                totalQuestions: viewModel.targetUsers.count,
                streak: gameManager.currentStreak,
                onExit: { showExitAlert = true }
            )
            .padding(.horizontal)
            .padding(.top, 10)
            
            // Content in ScrollView for better layout
            ScrollView {
                VStack(spacing: 0) {
                    if viewModel.isLoading {
                        // Loading state
                        GameLoadingView()
                    } else if gameManager.isGameOver && gameManager.lives > 0 {
                        // Game over view (only show if we have lives)
                        GameOverView(
                            score: gameManager.score,
                            correctAnswers: gameManager.correctAnswers,
                            totalQuestions: viewModel.targetUsers.count,
                            onPlayAgain: {
                                gameManager.restartGame()
                                viewModel.loadUsers()
                            },
                            onExit: {
                                dismiss()
                            }
                        )
                        .transition(.opacity.combined(with: .move(edge: .trailing)))
                        .padding(.horizontal)
                    } else {
                        // Current question card
                        if let question = viewModel.currentQuestion {
                            GameQuestionCard(
                                question: question,
                                onAnswerSelected: { choiceIndex in
                                    if let answer = question.choices[safe: choiceIndex] {
                                        viewModel.checkAnswer(answer)
                                    }
                                }
                            )
                            .padding(.horizontal)
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                            .id(viewModel.currentIndex) // Important: Add an ID for animation
                            .onAppear {
                                // Debug prints
                                if let imageURL = question.userProfileImageURL {
                                    print("DEBUG: Question has image URL: \(imageURL)")
                                } else {
                                    print("DEBUG: Question has NO image URL")
                                }
                            }
                        }
                    }
                }
                .padding(.bottom, 70) // Add padding to prevent content from hiding behind banner
            }
            
            Spacer(minLength: 0)
            
            // Add banner ad at the bottom
            BannerAdView()
                .frame(height: 45)
                .background(AppTheme.cardBackground)
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: -2)
        }
        .alert(isPresented: $showExitAlert) {
            Alert(
                title: Text("Exit Game"),
                message: Text("Are you sure you want to exit? Your progress will be saved."),
                primaryButton: .destructive(Text("Exit")) {
                    // Exit the game
                    dismiss()
                },
                secondaryButton: .cancel()
            )
        }
    }
}

// MARK: - Loading View
struct GameLoadingView: View {
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(AppTheme.primary)
            
            Text("Loading questions...")
                .font(AppTheme.body())
                .foregroundColor(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 100)
    }
}

// MARK: - Success Animation View
struct GameSuccessAnimationView: View {
    var body: some View {
        VStack {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 100))
                .foregroundColor(AppTheme.correct)
                .transition(.scale.combined(with: .opacity))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.3))
        .transition(.opacity)
    }
}

// MARK: - Failure Animation View
struct GameFailureAnimationView: View {
    var body: some View {
        VStack {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 100))
                .foregroundColor(AppTheme.error)
                .transition(.scale.combined(with: .opacity))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.3))
        .transition(.opacity)
    }
}

// MARK: - Achievement Alert View
struct AchievementAlertView: View {
    let achievements: [Achievement]
    let onDismiss: () -> Void
    
    var body: some View {
        VStack {
            Text("New Achievement!")
                .font(AppTheme.title())
                .foregroundColor(AppTheme.textPrimary)
                .padding(.bottom, 5)
            
            ForEach(achievements) { achievement in
                HStack {
                    Image(systemName: achievement.imageName)
                        .font(.system(size: 24))
                        .foregroundColor(AppTheme.accent)
                    
                    VStack(alignment: .leading) {
                        Text(achievement.name)
                            .font(AppTheme.subheading())
                            .foregroundColor(AppTheme.textPrimary)
                        
                        Text(achievement.description)
                            .font(AppTheme.caption())
                            .foregroundColor(AppTheme.textSecondary)
                    }
                }
                .padding(.vertical, 5)
            }
            
            Button("Continue", action: onDismiss)
                .primaryButtonStyle()
                .padding(.top, 10)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(AppTheme.cardBackground)
                .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
        )
        .padding(20)
        .transition(.scale.combined(with: .opacity))
    }
}

// Helper extension for safe array access
extension Array {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

struct GameHeaderView: View {
    let currentQuestion: Int
    let totalQuestions: Int
    let streak: Int
    let onExit: () -> Void
    @EnvironmentObject var gameManager: GameManager
    
    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            // Lives indicator
            HStack(spacing: 4) {
                ForEach(0..<gameManager.maxLives, id: \.self) { index in
                    Image(systemName: index < gameManager.lives ? "heart.fill" : "heart")
                        .foregroundColor(index < gameManager.lives ? AppTheme.accent : AppTheme.textSecondary.opacity(0.3))
                        .font(.system(size: 14, weight: .semibold))
                        .symbolEffect(.pulse, options: .repeating, value: gameManager.lives > 0 && index == gameManager.lives - 1)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(AppTheme.cardBackground)
                    .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
            )
            
            Spacer()
            
            // Streak indicator
            HStack(spacing: 6) {
                Image(systemName: "flame.fill")
                    .foregroundColor(AppTheme.accent)
                    .symbolEffect(
                        .variableColor,
                        options: .repeating,
                        value: streak > 0
                    )
                
                Text("\(streak)")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.textPrimary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(AppTheme.cardBackground)
                    .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
            )
        }
        .padding(.vertical, 8)
    }
}

struct GameOverView: View {
    let score: Int
    let correctAnswers: Int
    let totalQuestions: Int
    let onPlayAgain: () -> Void
    let onExit: () -> Void
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 30) {
            // Celebration animation/image
            ZStack {
                Circle()
                    .fill(AppTheme.primary.opacity(0.1))
                    .frame(width: 150, height: 150)
                
                Image(systemName: "trophy.fill")
                    .font(.system(size: 64))
                    .foregroundColor(AppTheme.secondary)
                    .scaleEffect(isAnimating ? 1.1 : 0.9)
                    .shadow(color: AppTheme.secondary.opacity(0.5), radius: isAnimating ? 20 : 10, x: 0, y: 0)
            }
            .padding(.top, 20)
            
            // Game results
            VStack(spacing: 16) {
                Text("Game Complete!")
                    .font(AppTheme.title())
                    .foregroundColor(AppTheme.textPrimary)
                
                Text("You scored")
                    .font(AppTheme.body())
                    .foregroundColor(AppTheme.textSecondary)
                
                Text("\(score) pts")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.primary)
                    .padding(.vertical, 5)
                
                Text("\(correctAnswers) out of \(totalQuestions) correct")
                    .font(AppTheme.subheading())
                    .foregroundColor(AppTheme.textSecondary)
                
                // Accuracy pie chart or visual
                AccuracyRingView(correctAnswers: correctAnswers, totalQuestions: totalQuestions)
                    .frame(width: 140, height: 140)
                    .padding(.vertical, 10)
            }
            .padding(.horizontal, 20)
            
            // Buttons
            VStack(spacing: 16) {
                Button(action: onPlayAgain) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Play Again")
                    }
                    .fillWidth()
                    .padding(.vertical, 16)
                }
                .primaryButtonStyle()
                .buttonStyle(ScaleButtonStyle())
                
                Button(action: onExit) {
                    Text("Exit")
                        .fillWidth()
                        .padding(.vertical, 16)
                }
                .secondaryButtonStyle()
                .buttonStyle(ScaleButtonStyle())
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(AppTheme.cardBackground)
        )
        .floatingCardStyle()
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}

struct AccuracyRingView: View {
    let correctAnswers: Int
    let totalQuestions: Int
    
    private var accuracy: Double {
        guard totalQuestions > 0 else { return 0 }
        return Double(correctAnswers) / Double(totalQuestions)
    }
    
    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(lineWidth: 15)
                .opacity(0.3)
                .foregroundColor(AppTheme.tertiary)
            
            // Progress circle
            Circle()
                .trim(from: 0.0, to: CGFloat(min(accuracy, 1.0)))
                .stroke(
                    AngularGradient(
                        colors: [AppTheme.correct, AppTheme.secondary, AppTheme.primary],
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(360 * accuracy)
                    ),
                    style: StrokeStyle(lineWidth: 15, lineCap: .round)
                )
                .rotationEffect(Angle(degrees: 270))
                .animation(.easeOut(duration: 1.0), value: accuracy)
            
            // Percentage text
            VStack(spacing: 2) {
                Text("\(Int(accuracy * 100))")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.textPrimary)
                
                Text("%")
                    .font(AppTheme.caption())
                    .foregroundColor(AppTheme.textSecondary)
            }
        }
    }
}

// MARK: - No Lives Overlay View
struct NoLivesOverlayView: View {
    let timeUntilNextLife: TimeInterval?
    let onWatchAd: () -> Void
    let onExit: () -> Void
    @State private var timeRemaining: TimeInterval = 0
    @State private var timer: Timer? = nil
    
    var body: some View {
        ZStack {
            // Blurred background
            Color.black.opacity(0.7)
                .ignoresSafeArea()
            
            // Content
            VStack(spacing: 20) {
                // Icon
                Image(systemName: "heart.slash.fill")
                    .font(.system(size: 50))
                    .foregroundColor(AppTheme.error)
                    .padding(.bottom, 5)
                
                // Title
                Text("Out of Lives!")
                    .font(AppTheme.title())
                    .foregroundColor(AppTheme.textPrimary)
                
                // Countdown timer
                if let timeUntilNextLife = timeUntilNextLife, timeUntilNextLife > 0 {
                    VStack(spacing: 5) {
                        Text("Next life in:")
                            .font(AppTheme.subheading())
                            .foregroundColor(AppTheme.textSecondary)
                        
                        Text(formatTime(timeRemaining))
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(AppTheme.primary)
                    }
                    .padding(.vertical, 10)
                }
                
                // Watch Ad button
                Button(action: onWatchAd) {
                    HStack {
                        Image(systemName: "play.circle.fill")
                        Text("Watch Ad for Lives")
                    }
                    .fillWidth()
                    .padding(.vertical, 14)
                }
                .primaryButtonStyle()
                .buttonStyle(ScaleButtonStyle())
                .padding(.horizontal, 20)
                .padding(.top, 5)
            }
            .padding(25)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(AppTheme.cardBackground)
            )
            .floatingCardStyle()
            .padding(.horizontal, 30)
            .frame(maxWidth: 320)
        }
        .onAppear {
            if let timeUntilNextLife = timeUntilNextLife {
                timeRemaining = timeUntilNextLife
                
                // Set up timer to update countdown
                timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                    if timeRemaining > 0 {
                        timeRemaining -= 1
                    } else {
                        timer?.invalidate()
                    }
                }
            }
        }
        .onDisappear {
            timer?.invalidate()
        }
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = Int(timeInterval) / 60 % 60
        let seconds = Int(timeInterval) % 60
        
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
}

// MARK: - Rewarded Ad View
struct RewardedAdView: View {
    let completion: (Bool) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.9)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Text("Loading Ad...")
                    .font(AppTheme.title())
                    .foregroundColor(AppTheme.textPrimary)
                
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(AppTheme.primary)
                
                Text("Please wait while we load the ad")
                    .font(AppTheme.body())
                    .foregroundColor(AppTheme.textSecondary)
            }
        }
        .onAppear {
            // Get the root view controller
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootViewController = windowScene.windows.first?.rootViewController {
                
                // Show the rewarded ad
                AdMobManager.shared.showRewardedAd(from: rootViewController) { success in
                    completion(success)
                    dismiss()
                }
            } else {
                // Fallback if we can't get the root view controller
                completion(false)
                dismiss()
            }
        }
    }
}

#Preview {
    GameView()
        .environmentObject(GameManager())
        .environmentObject(AuthenticationService())
} 
