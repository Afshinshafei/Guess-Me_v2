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
        Achievement(id: "people_reader", name: "People Reader", description: "Get 10 correct guesses", imageName: "person.fill.badge.plus", requirement: 10, type: .correctGuesses),
        Achievement(id: "hot_streak", name: "Hot Streak", description: "Guess correctly 5 times in a row", imageName: "flame.fill", requirement: 5, type: .streak),
        Achievement(id: "mind_reader", name: "Mind Reader", description: "Guess correctly 10 times in a row", imageName: "brain.head.profile", requirement: 10, type: .streak),
        Achievement(id: "guessing_machine", name: "Guessing Machine", description: "Make 50 guesses", imageName: "speedometer", requirement: 50, type: .totalGuesses),
        Achievement(id: "expert_reader", name: "Expert Reader", description: "Get 50 correct guesses", imageName: "star.fill", requirement: 50, type: .correctGuesses),
        Achievement(id: "legendary", name: "Legendary", description: "Guess correctly 20 times in a row", imageName: "crown.fill", requirement: 20, type: .streak)
    ]
} 