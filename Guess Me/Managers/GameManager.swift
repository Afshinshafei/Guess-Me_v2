import Foundation
import Combine
import SwiftUI

class GameManager: ObservableObject {
    @Published var lives: Int = 5
    @Published var lastLifeRegenTime: Date?
    @Published var currentStreak: Int = 0
    @Published var isRegeneratingLives: Bool = false
    @Published var isGameOver: Bool = false
    public let maxLives = 5
    private let lifeRegenerationTimeInSeconds: TimeInterval = 7200 // 2 hours
    private var timer: Timer?
    private var cancellables = Set<AnyCancellable>()
    private var currentUserId: String?
    
    // New properties for game mechanics
    @Published var questions: [Question] = []
    @Published var currentQuestionIndex: Int = 0
    @Published var score: Int = 0
    @Published var correctAnswers: Int = 0
    
    init() {
        // Initialize with default values, but don't reset lives yet
        currentStreak = 0
        score = 0
        correctAnswers = 0
        
        // Setup the timer for life regeneration check
        setupTimer()
    }
    
    func loadUserData(_ userId: String?) {
        // Store the user ID
        self.currentUserId = userId
        
        if let userIdKey = userId {
            print("Loading game data for user: \(userIdKey)")
            
            // User-specific keys
            let livesKey = "lives_\(userIdKey)"
            let streakKey = "currentStreak_\(userIdKey)"
            let regenTimeKey = "lastLifeRegenTime_\(userIdKey)"
            let isGameOverKey = "isGameOver_\(userIdKey)"
            
            // Load lives
            if UserDefaults.standard.object(forKey: livesKey) != nil {
                self.lives = UserDefaults.standard.integer(forKey: livesKey)
            } else {
                // Only set to max lives if we've never saved before
                self.lives = maxLives
            }
            
            // Load lastLifeRegenTime
            if let lastLifeRegenTimeData = UserDefaults.standard.object(forKey: regenTimeKey) as? Date {
                self.lastLifeRegenTime = lastLifeRegenTimeData
                // Set isRegeneratingLives based on lives and lastLifeRegenTime
                self.isRegeneratingLives = (self.lives < maxLives)
            } else {
                self.lastLifeRegenTime = nil
                self.isRegeneratingLives = false
            }
            
            // Load streak
            if let streak = UserDefaults.standard.object(forKey: streakKey) as? Int {
                self.currentStreak = streak
            }
            
            // Load game over state
            if let gameOver = UserDefaults.standard.object(forKey: isGameOverKey) as? Bool {
                self.isGameOver = gameOver
            }
            
            // Check for life regeneration immediately
            checkLifeRegeneration()
            
            print("Loaded lives: \(lives), streak: \(currentStreak), isGameOver: \(isGameOver)")
        } else {
            // No user ID, don't reset to default here
            // We'll wait until we have a user ID
            print("No user ID provided, waiting for user authentication")
        }
    }
    
    private func resetToDefault() {
        print("Resetting game manager to default values")
        lives = maxLives
        currentStreak = 0
        lastLifeRegenTime = nil
        isGameOver = false
        saveLivesData()
        saveGameState()
    }
    
    func resetLives() {
        lives = maxLives
        lastLifeRegenTime = nil
        isRegeneratingLives = false
        isGameOver = false
        saveLivesData()
        saveGameState()
    }
    
    private func saveLivesData() {
        if let userIdKey = currentUserId {
            UserDefaults.standard.set(lives, forKey: "lives_\(userIdKey)")
            
            if let lastLifeRegenTime = lastLifeRegenTime {
                UserDefaults.standard.set(lastLifeRegenTime, forKey: "lastLifeRegenTime_\(userIdKey)")
            } else {
                UserDefaults.standard.removeObject(forKey: "lastLifeRegenTime_\(userIdKey)")
            }
        }
    }
    
    private func saveGameState() {
        if let userIdKey = currentUserId {
            UserDefaults.standard.set(isGameOver, forKey: "isGameOver_\(userIdKey)")
        }
    }
    
    private func saveStreakData() {
        if let userIdKey = currentUserId {
            UserDefaults.standard.set(currentStreak, forKey: "currentStreak_\(userIdKey)")
        }
    }
    
    private func setupTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.checkLifeRegeneration()
        }
    }
    
    func checkLifeRegeneration() {
        guard let lastLifeRegenTime = lastLifeRegenTime, lives < maxLives else { 
            isRegeneratingLives = false
            return 
        }
        
        isRegeneratingLives = true
        let elapsedTime = Date().timeIntervalSince(lastLifeRegenTime)
        
        // Check if at least one full regeneration period has passed
        if elapsedTime >= lifeRegenerationTimeInSeconds {
            // Restore all lives after waiting for the regeneration period
            lives = maxLives
            self.lastLifeRegenTime = nil
            isRegeneratingLives = false
            isGameOver = false
            saveGameState()
            saveLivesData()
        }
    }
    
    func updateLastLifeRegenTime() {
        if lastLifeRegenTime == nil {
            lastLifeRegenTime = Date()
            isRegeneratingLives = true
            saveLivesData()
        }
    }
    
    func useLife() -> Bool {
        guard lives > 0 else { return false }
        lives -= 1
        if lives <= 0 {
            updateLastLifeRegenTime()
            isGameOver = true
            saveGameState()
        }
        saveLivesData()
        return true
    }
    
    func addLife() {
        if lives < maxLives {
            lives += 1
            if lives == maxLives {
                lastLifeRegenTime = nil
                isRegeneratingLives = false
                isGameOver = false
                saveGameState()
            }
            saveLivesData()
        }
    }
    
    func resetStreak() {
        currentStreak = 0
        saveStreakData()
    }
    
    func incrementStreak() {
        currentStreak += 1
        saveStreakData()
    }
    
    func timeUntilNextLife() -> TimeInterval? {
        guard let lastLifeRegenTime = lastLifeRegenTime, lives < maxLives else { return nil }
        
        let elapsed = Date().timeIntervalSince(lastLifeRegenTime)
        let remaining = max(lifeRegenerationTimeInSeconds - elapsed.truncatingRemainder(dividingBy: lifeRegenerationTimeInSeconds), 0)
        return remaining
    }
    
    // Load questions for the game
    func loadQuestions() {
        // Reset game state
        currentQuestionIndex = 0
        score = 0
        correctAnswers = 0
        // Don't reset isGameOver here, as it should persist
    }
    
    // Check if the game is over based on lives
    func checkGameOver() {
        if lives <= 0 {
            isGameOver = true
            isRegeneratingLives = true
            saveGameState()
            
            // Make sure we start the life regeneration timer if not already started
            if lastLifeRegenTime == nil {
                updateLastLifeRegenTime()
            }
        }
    }
    
    // Process an answer submission
    func submitAnswer(choiceIndex: Int, points: Int) {
        guard currentQuestionIndex < questions.count else { return }
        
        let question = questions[currentQuestionIndex]
        let selectedAnswer = question.choices[choiceIndex]
        let isCorrect = selectedAnswer == question.correctAnswer
        
        if isCorrect {
            // Correct answer
            let bonusPoints = points * (currentStreak + 1) // Points increase with streak
            score += bonusPoints
            correctAnswers += 1
            incrementStreak()
            
            // Sync with user profile would happen here in a full implementation
        } else {
            // Wrong answer - use a life
            _ = useLife()
            resetStreak()
            
            // Check if game is over after using a life
            checkGameOver()
        }
        
        // Move to next question with a short delay to allow animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            self.advanceToNextQuestion()
        }
    }
    
    private func advanceToNextQuestion() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            currentQuestionIndex += 1
        }
        
        // Check if game is over
        checkGameOver()
    }
    
    func restartGame() {
        loadQuestions()
        
        // Only reset game over state, not lives
        isGameOver = false
        saveGameState()
    }
    
    deinit {
        timer?.invalidate()
    }
}
