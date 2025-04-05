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
            choices: ageOptions.map { "\($0)" },
            correctAnswer: "\(actualAge)"
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
            choices: heightOptions.map { "\(Int($0)) cm" },
            correctAnswer: "\(Int(actualHeight)) cm"
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
            choices: weightOptions.map { "\(Int($0)) kg" },
            correctAnswer: "\(Int(actualWeight)) kg"
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
} 