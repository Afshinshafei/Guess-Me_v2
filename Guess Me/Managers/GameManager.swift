import Foundation
import Combine
import SwiftUI

class GameManager: ObservableObject {
    @Published var lives: Int = 5
    @Published var lastLifeRegenTime: Date?
    @Published var currentStreak: Int = 0
    public let maxLives = 5
    private let lifeRegenerationTimeInSeconds: TimeInterval = 3600 // 1 hour
    private var timer: Timer?
    private var cancellables = Set<AnyCancellable>()
    private var currentUserId: String?
    
    init() {
        setupTimer()
        loadUserData(nil)
    }
    
    func loadUserData(_ userId: String?) {
        // If this is a different user than before, reset data
        if currentUserId != userId {
            resetToDefault()
            currentUserId = userId
        } else if userId != nil {
            // Only load saved data if we have a user ID
            loadSavedData()
        }
    }
    
    private func loadSavedData() {
        if let userIdKey = currentUserId {
            print("Loading game data for user: \(userIdKey)")
            
            // User-specific keys
            let livesKey = "lives_\(userIdKey)"
            let streakKey = "currentStreak_\(userIdKey)"
            let regenTimeKey = "lastLifeRegenTime_\(userIdKey)"
            
            if let lastLifeRegenTimeData = UserDefaults.standard.object(forKey: regenTimeKey) as? Date {
                self.lastLifeRegenTime = lastLifeRegenTimeData
                checkLifeRegeneration()
            }
            
            if let lives = UserDefaults.standard.object(forKey: livesKey) as? Int {
                self.lives = lives
            }
            
            if let streak = UserDefaults.standard.object(forKey: streakKey) as? Int {
                self.currentStreak = streak
            }
            
            print("Loaded lives: \(lives), streak: \(currentStreak)")
        } else {
            // No user ID, use default values
            resetToDefault()
        }
    }
    
    private func resetToDefault() {
        print("Resetting game manager to default values")
        lives = maxLives
        currentStreak = 0
        lastLifeRegenTime = nil
    }
    
    func resetLives() {
        lives = maxLives
        lastLifeRegenTime = nil
        saveLivesData()
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
        guard let lastLifeRegenTime = lastLifeRegenTime, lives < maxLives else { return }
        
        let elapsedTime = Date().timeIntervalSince(lastLifeRegenTime)
        let livesToAdd = Int(elapsedTime / lifeRegenerationTimeInSeconds)
        
        if livesToAdd > 0 {
            lives = min(lives + livesToAdd, maxLives)
            
            // If we still haven't reached max lives, update the last regen time
            if lives < maxLives {
                let remainderTime = elapsedTime.truncatingRemainder(dividingBy: lifeRegenerationTimeInSeconds)
                self.lastLifeRegenTime = Date().addingTimeInterval(-remainderTime)
            } else {
                // We're at max lives, no need to track regen time
                self.lastLifeRegenTime = nil
            }
            
            saveLivesData()
        }
    }
    
    func updateLastLifeRegenTime() {
        if lastLifeRegenTime == nil {
            lastLifeRegenTime = Date()
            saveLivesData()
        }
    }
    
    func useLife() -> Bool {
        guard lives > 0 else { return false }
        lives -= 1
        if lives <= 0 {
            updateLastLifeRegenTime()
        }
        saveLivesData()
        return true
    }
    
    func addLife() {
        if lives < maxLives {
            lives += 1
            if lives == maxLives {
                lastLifeRegenTime = nil
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
        return max(lifeRegenerationTimeInSeconds - elapsed.truncatingRemainder(dividingBy: lifeRegenerationTimeInSeconds), 0)
    }
    
    // New properties for game mechanics
    @Published var questions: [Question] = []
    @Published var currentQuestionIndex: Int = 0
    @Published var score: Int = 0
    @Published var correctAnswers: Int = 0
    @Published var isGameOver: Bool = false
    
    // Load questions for the game
    func loadQuestions() {
        // Reset game state
        currentQuestionIndex = 0
        score = 0
        correctAnswers = 0
        isGameOver = false
        
        // We'll fetch real users and generate questions in the GameViewModel
        // This method is now just a placeholder for game state reset
    }
    
    // Check if the game is over based on lives
    func checkGameOver() {
        if lives <= 0 {
            isGameOver = true
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
    }
    
    deinit {
        timer?.invalidate()
    }
} 