import Foundation

struct Question: Identifiable {
    var id = UUID()
    var type: QuestionType
    var text: String
    var choices: [String]
    var correctAnswer: String
    var userProfileImageURL: String?
    
    enum QuestionType: String, Codable {
        case age = "Age"
        case occupation = "Occupation"
        case education = "Education"
        case height = "Height"
        case weight = "Weight"
        case smoker = "Smoker"
        case favoriteColor = "Favorite Color"
        case favoriteMovie = "Favorite Movie"
        case favoriteFood = "Favorite Food"
        case favoriteFlower = "Favorite Flower"
        case favoriteSport = "Favorite Sport"
        case favoriteHobby = "Favorite Hobby"
    }
} 