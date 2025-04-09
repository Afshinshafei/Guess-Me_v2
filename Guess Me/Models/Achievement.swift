import Foundation

struct Achievement: Identifiable, Codable {
    var id: String
    var name: String
    var description: String
    var imageName: String
    var requirement: Int
    var type: AchievementType
    
    enum AchievementType: String, Codable {
        case correctGuesses = "CorrectGuesses"
        case streak = "Streak"
        case totalGuesses = "TotalGuesses"
    }
    
    static let allAchievements: [Achievement] = [
        // Easy Achievements
        Achievement(id: "first_steps", name: "First Steps", description: "Get 5 correct guesses", imageName: "figure.walk", requirement: 5, type: .correctGuesses),
        Achievement(id: "beginner_luck", name: "Beginner's Luck", description: "Get 3 correct guesses in a row", imageName: "leaf.fill", requirement: 3, type: .streak),
        
        // Medium Achievements
        Achievement(id: "people_reader", name: "People Reader", description: "Get 25 correct guesses", imageName: "person.fill.badge.plus", requirement: 25, type: .correctGuesses),
        Achievement(id: "hot_streak", name: "Hot Streak", description: "Get 10 correct guesses in a row", imageName: "flame.fill", requirement: 10, type: .streak),
        Achievement(id: "dedicated", name: "Dedicated", description: "Make 100 total guesses", imageName: "figure.mind.and.body", requirement: 100, type: .totalGuesses),
        Achievement(id: "sharp_eye", name: "Sharp Eye", description: "Get 50 correct guesses", imageName: "eye.fill", requirement: 50, type: .correctGuesses),
        
        // Hard Achievements
        Achievement(id: "mastermind", name: "Mastermind", description: "Get 20 correct guesses in a row", imageName: "brain.head.profile", requirement: 20, type: .streak),
        Achievement(id: "veteran", name: "Veteran", description: "Make 500 total guesses", imageName: "trophy.fill", requirement: 500, type: .totalGuesses),
        Achievement(id: "legendary", name: "Legendary", description: "Get 100 correct guesses", imageName: "crown.fill", requirement: 100, type: .correctGuesses),
        
        // Ultimate Achievement
        Achievement(id: "oracle", name: "The Oracle", description: "Get 50 correct guesses in a row", imageName: "sparkles.square.filled.on.square", requirement: 50, type: .streak)
    ]
} 