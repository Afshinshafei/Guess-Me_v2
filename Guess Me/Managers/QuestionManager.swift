import Foundation

class QuestionManager {
    
    static func generateQuestion(for user: User) -> Question? {
        var availableQuestionTypes: [Question.QuestionType] = []
        
        // Check which data points are available for this user
        if user.age != nil {
            availableQuestionTypes.append(.age)
        }
        
        if user.occupation != nil {
            availableQuestionTypes.append(.occupation)
        }
        
        if user.education != nil {
            availableQuestionTypes.append(.education)
        }
        
        if user.height != nil {
            availableQuestionTypes.append(.height)
        }
        
        if user.weight != nil {
            availableQuestionTypes.append(.weight)
        }
        
        if user.smoker != nil {
            availableQuestionTypes.append(.smoker)
        }
        
        if user.favoriteColor != nil {
            availableQuestionTypes.append(.favoriteColor)
        }
        
        if user.favoriteMovie != nil {
            availableQuestionTypes.append(.favoriteMovie)
        }
        
        if user.favoriteFood != nil {
            availableQuestionTypes.append(.favoriteFood)
        }
        
        if user.favoriteFlower != nil {
            availableQuestionTypes.append(.favoriteFlower)
        }
        
        if user.favoriteSport != nil {
            availableQuestionTypes.append(.favoriteSport)
        }
        
        if user.favoriteHobby != nil {
            availableQuestionTypes.append(.favoriteHobby)
        }
        
        guard !availableQuestionTypes.isEmpty else {
            return nil
        }
        
        // Randomly select a question type
        let randomQuestionType = availableQuestionTypes.randomElement()!
        
        return createQuestion(type: randomQuestionType, for: user)
    }
    
    private static func createQuestion(type: Question.QuestionType, for user: User) -> Question {
        var question: Question
        
        switch type {
        case .age:
            question = createAgeQuestion(for: user)
        case .occupation:
            question = createOccupationQuestion(for: user)
        case .education:
            question = createEducationQuestion(for: user)
        case .height:
            question = createHeightQuestion(for: user)
        case .weight:
            question = createWeightQuestion(for: user)
        case .smoker:
            question = createSmokerQuestion(for: user)
        case .favoriteColor:
            question = createFavoriteColorQuestion(for: user)
        case .favoriteMovie:
            question = createFavoriteMovieQuestion(for: user)
        case .favoriteFood:
            question = createFavoriteFoodQuestion(for: user)
        case .favoriteFlower:
            question = createFavoriteFlowerQuestion(for: user)
        case .favoriteSport:
            question = createFavoriteSportQuestion(for: user)
        case .favoriteHobby:
            question = createFavoriteHobbyQuestion(for: user)
        }
        
        // Add the user's profile image URL to the question
        question.userProfileImageURL = user.profileImageURL
        
        return question
    }
    
    private static func createAgeQuestion(for user: User) -> Question {
        guard let actualAge = user.age else {
            fatalError("User age should not be nil when creating age question")
        }
        
        let questionText = "How old do you think this person is?"
        
        // Generate plausible age options
        var ageOptions = [actualAge]
        while ageOptions.count < 4 {
            // Generate ages within +/- 10 years
            let randomOffset = Int.random(in: -10...10)
            let potentialAge = max(18, actualAge + randomOffset) // Ensure no ages below 18
            
            if !ageOptions.contains(potentialAge) {
                ageOptions.append(potentialAge)
            }
        }
        
        ageOptions.shuffle()
        
        return Question(
            type: .age,
            text: questionText,
            choices: ageOptions.map { String($0) },
            correctAnswer: String(actualAge)
        )
    }
    
    private static func createOccupationQuestion(for user: User) -> Question {
        guard let actualOccupation = user.occupation else {
            fatalError("User occupation should not be nil when creating occupation question")
        }
        
        let questionText = "What do you think this person does for a living?"
        
        // Common occupations to use as alternative choices
        let commonOccupations = [
            "Teacher", "Doctor", "Engineer", "Lawyer", "Artist",
            "Designer", "Chef", "Accountant", "Scientist", "Writer",
            "Programmer", "Manager", "Entrepreneur", "Nurse", "Technician"
        ]
        
        var occupationOptions = [actualOccupation]
        while occupationOptions.count < 4 {
            if let randomOccupation = commonOccupations.randomElement(),
               !occupationOptions.contains(randomOccupation) {
                occupationOptions.append(randomOccupation)
            }
        }
        
        occupationOptions.shuffle()
        
        return Question(
            type: .occupation,
            text: questionText,
            choices: occupationOptions,
            correctAnswer: actualOccupation
        )
    }
    
    private static func createEducationQuestion(for user: User) -> Question {
        guard let actualEducation = user.education else {
            fatalError("User education should not be nil when creating education question")
        }
        
        let questionText = "What is this person's education level?"
        
        // Common education levels
        let educationLevels = [
            "High School", "Associate's Degree", "Bachelor's Degree",
            "Master's Degree", "PhD", "Trade School", "Self-taught"
        ]
        
        var educationOptions = [actualEducation]
        while educationOptions.count < 4 {
            if let randomEducation = educationLevels.randomElement(),
               !educationOptions.contains(randomEducation) {
                educationOptions.append(randomEducation)
            }
        }
        
        educationOptions.shuffle()
        
        return Question(
            type: .education,
            text: questionText,
            choices: educationOptions,
            correctAnswer: actualEducation
        )
    }
    
    private static func createHeightQuestion(for user: User) -> Question {
        guard let actualHeight = user.height else {
            fatalError("User height should not be nil when creating height question")
        }
        
        let questionText = "How tall do you think this person is (in cm)?"
        
        // Generate plausible height options
        var heightOptions = [actualHeight]
        while heightOptions.count < 4 {
            // Generate heights within +/- 15 cm
            let randomOffset = Double.random(in: -15...15)
            let potentialHeight = round(actualHeight + randomOffset)
            
            if !heightOptions.contains(potentialHeight) {
                heightOptions.append(potentialHeight)
            }
        }
        
        heightOptions.shuffle()
        
        return Question(
            type: .height,
            text: questionText,
            choices: heightOptions.map { String(Int($0)) },
            correctAnswer: String(Int(actualHeight))
        )
    }
    
    private static func createWeightQuestion(for user: User) -> Question {
        guard let actualWeight = user.weight else {
            fatalError("User weight should not be nil when creating weight question")
        }
        
        let questionText = "What do you think this person weighs (in kg)?"
        
        // Generate plausible weight options
        var weightOptions = [actualWeight]
        while weightOptions.count < 4 {
            // Generate weights within +/- 15 kg
            let randomOffset = Double.random(in: -15...15)
            let potentialWeight = max(45, round(actualWeight + randomOffset)) // Ensure reasonable minimum weight
            
            if !weightOptions.contains(potentialWeight) {
                weightOptions.append(potentialWeight)
            }
        }
        
        weightOptions.shuffle()
        
        return Question(
            type: .weight,
            text: questionText,
            choices: weightOptions.map { String(Int($0)) },
            correctAnswer: String(Int(actualWeight))
        )
    }
    
    private static func createSmokerQuestion(for user: User) -> Question {
        guard let isSmoker = user.smoker else {
            fatalError("User smoker status should not be nil when creating smoker question")
        }
        
        let questionText = "Do you think this person is a smoker?"
        let choices = ["Yes", "No"]
        let correctAnswer = isSmoker ? "Yes" : "No"
        
        return Question(
            type: .smoker,
            text: questionText,
            choices: choices,
            correctAnswer: correctAnswer
        )
    }
    
    private static func createFavoriteColorQuestion(for user: User) -> Question {
        guard let actualColor = user.favoriteColor else {
            fatalError("User favorite color should not be nil when creating favorite color question")
        }
        
        let questionText = "What is this person's favorite color?"
        
        let commonColors = [
            "Red", "Blue", "Green", "Yellow", "Purple", "Orange",
            "Pink", "Black", "White", "Brown", "Gray", "Teal"
        ]
        
        var colorOptions = [actualColor]
        while colorOptions.count < 4 {
            if let randomColor = commonColors.randomElement(),
               !colorOptions.contains(randomColor) {
                colorOptions.append(randomColor)
            }
        }
        
        colorOptions.shuffle()
        
        return Question(
            type: .favoriteColor,
            text: questionText,
            choices: colorOptions,
            correctAnswer: actualColor
        )
    }
    
    private static func createFavoriteMovieQuestion(for user: User) -> Question {
        guard let actualMovie = user.favoriteMovie else {
            fatalError("User favorite movie should not be nil when creating favorite movie question")
        }
        
        let questionText = "What is this person's favorite movie?"
        
        let popularMovies = [
            "The Shawshank Redemption", "The Godfather", "The Dark Knight",
            "Pulp Fiction", "Forrest Gump", "Inception", "The Matrix",
            "Goodfellas", "The Lord of the Rings", "Star Wars"
        ]
        
        var movieOptions = [actualMovie]
        while movieOptions.count < 4 {
            if let randomMovie = popularMovies.randomElement(),
               !movieOptions.contains(randomMovie) {
                movieOptions.append(randomMovie)
            }
        }
        
        movieOptions.shuffle()
        
        return Question(
            type: .favoriteMovie,
            text: questionText,
            choices: movieOptions,
            correctAnswer: actualMovie
        )
    }
    
    private static func createFavoriteFoodQuestion(for user: User) -> Question {
        guard let actualFood = user.favoriteFood else {
            fatalError("User favorite food should not be nil when creating favorite food question")
        }
        
        let questionText = "What is this person's favorite food?"
        
        let commonFoods = [
            "Pizza", "Sushi", "Burger", "Pasta", "Tacos",
            "Salad", "Steak", "Curry", "Ramen", "Sandwich"
        ]
        
        var foodOptions = [actualFood]
        while foodOptions.count < 4 {
            if let randomFood = commonFoods.randomElement(),
               !foodOptions.contains(randomFood) {
                foodOptions.append(randomFood)
            }
        }
        
        foodOptions.shuffle()
        
        return Question(
            type: .favoriteFood,
            text: questionText,
            choices: foodOptions,
            correctAnswer: actualFood
        )
    }
    
    private static func createFavoriteFlowerQuestion(for user: User) -> Question {
        guard let actualFlower = user.favoriteFlower else {
            fatalError("User favorite flower should not be nil when creating favorite flower question")
        }
        
        let questionText = "What is this person's favorite flower?"
        
        let commonFlowers = [
            "Rose", "Tulip", "Sunflower", "Lily", "Orchid",
            "Daisy", "Daffodil", "Iris", "Chrysanthemum", "Peony"
        ]
        
        var flowerOptions = [actualFlower]
        while flowerOptions.count < 4 {
            if let randomFlower = commonFlowers.randomElement(),
               !flowerOptions.contains(randomFlower) {
                flowerOptions.append(randomFlower)
            }
        }
        
        flowerOptions.shuffle()
        
        return Question(
            type: .favoriteFlower,
            text: questionText,
            choices: flowerOptions,
            correctAnswer: actualFlower
        )
    }
    
    private static func createFavoriteSportQuestion(for user: User) -> Question {
        guard let actualSport = user.favoriteSport else {
            fatalError("User favorite sport should not be nil when creating favorite sport question")
        }
        
        let questionText = "What is this person's favorite sport?"
        
        let commonSports = [
            "Football", "Basketball", "Tennis", "Soccer", "Baseball",
            "Golf", "Swimming", "Volleyball", "Cricket", "Rugby"
        ]
        
        var sportOptions = [actualSport]
        while sportOptions.count < 4 {
            if let randomSport = commonSports.randomElement(),
               !sportOptions.contains(randomSport) {
                sportOptions.append(randomSport)
            }
        }
        
        sportOptions.shuffle()
        
        return Question(
            type: .favoriteSport,
            text: questionText,
            choices: sportOptions,
            correctAnswer: actualSport
        )
    }
    
    private static func createFavoriteHobbyQuestion(for user: User) -> Question {
        guard let actualHobby = user.favoriteHobby else {
            fatalError("User favorite hobby should not be nil when creating favorite hobby question")
        }
        
        let questionText = "What is this person's favorite hobby?"
        
        let commonHobbies = [
            "Reading", "Gaming", "Photography", "Painting", "Gardening",
            "Cooking", "Traveling", "Music", "Writing", "Hiking"
        ]
        
        var hobbyOptions = [actualHobby]
        while hobbyOptions.count < 4 {
            if let randomHobby = commonHobbies.randomElement(),
               !hobbyOptions.contains(randomHobby) {
                hobbyOptions.append(randomHobby)
            }
        }
        
        hobbyOptions.shuffle()
        
        return Question(
            type: .favoriteHobby,
            text: questionText,
            choices: hobbyOptions,
            correctAnswer: actualHobby
        )
    }
} 