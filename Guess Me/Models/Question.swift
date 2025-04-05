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
    }
} 