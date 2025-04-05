import Foundation
import FirebaseFirestore
import Combine

class UserService {
    static let shared = UserService()
    
    private let db = Firestore.firestore()
    private let usersCollection = "users"
    
    private init() {}
    
    func fetchUser(withUID uid: String) -> AnyPublisher<User, Error> {
        return Future<User, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "UserService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Service unavailable"])))
                return
            }
            
            let docRef = self.db.collection(self.usersCollection).document(uid)
            
            docRef.getDocument { document, error in
                if let error = error {
                    promise(.failure(error))
                    return
                }
                
                guard let document = document, document.exists else {
                    promise(.failure(NSError(domain: "UserService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not found"])))
                    return
                }
                
                do {
                    let user = try document.data(as: User.self)
                    promise(.success(user))
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func createUser(_ user: User) -> AnyPublisher<Void, Error> {
        return Future<Void, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "UserService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Service unavailable"])))
                return
            }
            
            guard let uid = user.id else {
                promise(.failure(NSError(domain: "UserService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User ID is missing"])))
                return
            }
            
            do {
                try self.db.collection(self.usersCollection).document(uid).setData(from: user)
                promise(.success(()))
            } catch {
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func updateUser(_ user: User) -> AnyPublisher<Void, Error> {
        return Future<Void, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "UserService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Service unavailable"])))
                return
            }
            
            guard let uid = user.id else {
                promise(.failure(NSError(domain: "UserService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User ID is missing"])))
                return
            }
            
            do {
                try self.db.collection(self.usersCollection).document(uid).setData(from: user, merge: true)
                promise(.success(()))
            } catch {
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func fetchRandomUsers(excluding uid: String, limit: Int = 10) -> AnyPublisher<[User], Error> {
        return Future<[User], Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "UserService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Service unavailable"])))
                return
            }
            
            // Get all users and filter in memory
            self.db.collection(self.usersCollection)
                .limit(to: limit * 2) // Fetch more to account for filtering
                .getDocuments { snapshot, error in
                    if let error = error {
                        promise(.failure(error))
                        return
                    }
                    
                    guard let documents = snapshot?.documents, !documents.isEmpty else {
                        promise(.success([]))
                        return
                    }
                    
                    do {
                        let allUsers = try documents.compactMap { try $0.data(as: User.self) }
                        
                        // Filter users in memory
                        let filteredUsers = allUsers
                            .filter { $0.id != uid && $0.profileImageURL != nil }
                            .prefix(limit)
                        
                        promise(.success(Array(filteredUsers)))
                    } catch {
                        promise(.failure(error))
                    }
                }
        }
        .eraseToAnyPublisher()
    }
    
    func updateUserScore(uid: String, points: Int, isCorrect: Bool) -> AnyPublisher<Void, Error> {
        return fetchUser(withUID: uid)
            .flatMap { [weak self] user -> AnyPublisher<Void, Error> in
                guard let self = self else {
                    return Fail(error: NSError(domain: "UserService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Service unavailable"]))
                        .eraseToAnyPublisher()
                }
                
                var updatedUser = user
                updatedUser.score += points
                updatedUser.totalGuesses += 1
                
                if isCorrect {
                    updatedUser.correctGuesses += 1
                    updatedUser.streak += 1
                    
                    if updatedUser.streak > updatedUser.highestStreak {
                        updatedUser.highestStreak = updatedUser.streak
                    }
                    
                    // Check for new achievements
                    let newAchievements = self.checkAchievements(for: updatedUser)
                    if !newAchievements.isEmpty {
                        updatedUser.achievements.append(contentsOf: newAchievements)
                    }
                } else {
                    updatedUser.streak = 0
                }
                
                return self.updateUser(updatedUser)
            }
            .eraseToAnyPublisher()
    }
    
    private func checkAchievements(for user: User) -> [String] {
        var newAchievements: [String] = []
        
        for achievement in Achievement.allAchievements {
            // Skip if user already has this achievement
            if user.achievements.contains(achievement.id) {
                continue
            }
            
            var requirementMet = false
            
            switch achievement.type {
            case .correctGuesses:
                requirementMet = user.correctGuesses >= achievement.requirement
            case .streak:
                requirementMet = user.streak >= achievement.requirement
            case .totalGuesses:
                requirementMet = user.totalGuesses >= achievement.requirement
            }
            
            if requirementMet {
                newAchievements.append(achievement.id)
            }
        }
        
        return newAchievements
    }
} 