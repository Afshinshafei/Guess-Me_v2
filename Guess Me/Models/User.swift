import Foundation
import FirebaseFirestore

struct User: Identifiable, Codable, Equatable {
    @DocumentID var id: String?
    var username: String
    var email: String
    var profileImageURL: String?
    var age: Int?
    var education: String?
    var occupation: String?
    var height: Double?
    var weight: Double?
    var smoker: Bool?
    var favoriteColor: String?
    var favoriteMovie: String?
    var favoriteFood: String?
    var favoriteFlower: String?
    var favoriteSport: String?
    var favoriteHobby: String?
    var score: Int = 0
    var achievements: [String] = []
    var streak: Int = 0
    var highestStreak: Int = 0
    var correctGuesses: Int = 0
    var totalGuesses: Int = 0
    var hasCompletedSetup: Bool = false
    
    // Apple Sign In
    var appleUserIdentifier: String?
    
    // Game stats
    var rankings: [String: Int] = [:]
    
    // Add explicit initializer
    init(id: String? = nil, 
         username: String, 
         email: String, 
         profileImageURL: String? = nil, 
         age: Int? = nil, 
         education: String? = nil, 
         occupation: String? = nil, 
         height: Double? = nil, 
         weight: Double? = nil, 
         smoker: Bool? = nil,
         favoriteColor: String? = nil,
         favoriteMovie: String? = nil,
         favoriteFood: String? = nil,
         favoriteFlower: String? = nil,
         favoriteSport: String? = nil,
         favoriteHobby: String? = nil,
         score: Int = 0, 
         achievements: [String] = [], 
         streak: Int = 0, 
         highestStreak: Int = 0, 
         correctGuesses: Int = 0, 
         totalGuesses: Int = 0,
         hasCompletedSetup: Bool = false,
         appleUserIdentifier: String? = nil) {
        
        self.id = id
        self.username = username
        self.email = email
        self.profileImageURL = profileImageURL
        self.age = age
        self.education = education
        self.occupation = occupation
        self.height = height
        self.weight = weight
        self.smoker = smoker
        self.favoriteColor = favoriteColor
        self.favoriteMovie = favoriteMovie
        self.favoriteFood = favoriteFood
        self.favoriteFlower = favoriteFlower
        self.favoriteSport = favoriteSport
        self.favoriteHobby = favoriteHobby
        self.score = score
        self.achievements = achievements
        self.streak = streak
        self.highestStreak = highestStreak
        self.correctGuesses = correctGuesses
        self.totalGuesses = totalGuesses
        self.hasCompletedSetup = hasCompletedSetup
        self.appleUserIdentifier = appleUserIdentifier
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case username
        case email
        case profileImageURL
        case age
        case education
        case occupation
        case height
        case weight
        case smoker
        case favoriteColor
        case favoriteMovie
        case favoriteFood
        case favoriteFlower
        case favoriteSport
        case favoriteHobby
        case score
        case achievements
        case streak
        case highestStreak
        case correctGuesses
        case totalGuesses
        case hasCompletedSetup
        case appleUserIdentifier
    }
    
    // Computed property to check if profile is complete
    var isProfileComplete: Bool {
        return !username.isEmpty && 
               !email.isEmpty && 
               (age != nil || height != nil || weight != nil || 
                occupation != nil || education != nil || 
                favoriteColor != nil || favoriteMovie != nil || 
                favoriteFood != nil || favoriteSport != nil || 
                favoriteHobby != nil)
    }
    
    static func == (lhs: User, rhs: User) -> Bool {
        return lhs.id == rhs.id
    }
} 