import Foundation
import FirebaseAuth
import Combine
import GoogleSignIn
import FirebaseCore

class AuthenticationService: ObservableObject {
    @Published var user: User?
    @Published var isAuthenticated = false
    @Published var errorMessage: String?
    
    internal var cancellables = Set<AnyCancellable>()
    private var handle: AuthStateDidChangeListenerHandle?
    
    init() {
        setupAuthStateListener()
    }
    
    private func setupAuthStateListener() {
        handle = Auth.auth().addStateDidChangeListener { [weak self] _, auth in
            guard let self = self else { return }
            
            if let firebaseUser = auth {
                print("DEBUG: Auth state changed - User is authenticated with ID: \(firebaseUser.uid)")
                self.isAuthenticated = true
                self.errorMessage = nil
                
                // Fetch user data from Firestore
                self.fetchUserData(userId: firebaseUser.uid)
            } else {
                print("DEBUG: Auth state changed - User signed out")
                self.isAuthenticated = false
                self.user = nil
            }
        }
    }
    
    private func fetchUserData(userId: String) {
        print("DEBUG: Fetching user data for ID: \(userId)")
        
        UserService.shared.fetchUser(withUID: userId)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    print("DEBUG: Error fetching user: \(error)")
                    self.errorMessage = "Error fetching user profile"
                }
            }, receiveValue: { user in
                print("DEBUG: User data fetched successfully: \(user.username), hasCompletedSetup: \(user.hasCompletedSetup)")
                
                // Check if we need to update hasCompletedSetup based on profile completeness
                var updatedUser = user
                
                // If user has sufficient profile data but hasCompletedSetup is false,
                // update it in Firestore to avoid showing ProfileSetupView again
                if !user.hasCompletedSetup && user.isProfileComplete {
                    print("DEBUG: User has complete profile but hasCompletedSetup is false, updating flag")
                    updatedUser.hasCompletedSetup = true
                    
                    // Update in Firestore
                    UserService.shared.updateUser(updatedUser)
                        .sink(receiveCompletion: { completion in
                            if case .failure(let error) = completion {
                                print("DEBUG: Error updating hasCompletedSetup: \(error)")
                            } else {
                                print("DEBUG: Successfully updated hasCompletedSetup flag")
                            }
                        }, receiveValue: { _ in })
                        .store(in: &self.cancellables)
                    
                    self.user = updatedUser
                } else {
                    self.user = user
                }
            })
            .store(in: &self.cancellables)
    }
    
    func signUp(email: String, password: String, username: String) -> AnyPublisher<Void, Error> {
        return Future<Void, Error> { [weak self] promise in
            print("DEBUG: Creating new user with email: \(email), username: \(username)")
            
            Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
                if let error = error {
                    print("DEBUG: Firebase Auth error: \(error)")
                    promise(.failure(error))
                    self?.errorMessage = error.localizedDescription
                    return
                }
                
                guard let firebaseUser = authResult?.user else {
                    let error = NSError(domain: "AuthenticationService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unknown error"])
                    print("DEBUG: No Firebase user returned after creation")
                    promise(.failure(error))
                    return
                }
                
                print("DEBUG: User created successfully with ID: \(firebaseUser.uid)")
                
                // Create user in Firestore
                let newUser = User(id: firebaseUser.uid, username: username, email: email)
                
                UserService.shared.createUser(newUser)
                    .sink(receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            print("DEBUG: Error creating user in Firestore: \(error)")
                            promise(.failure(error))
                            self?.errorMessage = error.localizedDescription
                        } else {
                            print("DEBUG: User successfully created in Firestore")
                            promise(.success(()))
                        }
                    }, receiveValue: { _ in
                        // Success
                    })
                    .store(in: &self!.cancellables)
            }
        }
        .eraseToAnyPublisher()
    }
    
    func signIn(email: String, password: String) -> AnyPublisher<Void, Error> {
        return Future<Void, Error> { [weak self] promise in
            Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
                if let error = error {
                    promise(.failure(error))
                    self?.errorMessage = error.localizedDescription
                    return
                }
                
                promise(.success(()))
            }
        }
        .eraseToAnyPublisher()
    }
    
    /// Signs out the current user
    func signOut() -> AnyPublisher<Void, Error> {
        print("DEBUG: AuthService - SignOut method called")
        
        return Future<Void, Error> { [weak self] promise in
            guard let self = self else {
                print("ERROR: AuthService - Self is nil in signOut")
                promise(.failure(NSError(domain: "AuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Service unavailable"])))
                return
            }
            
            // Check if a user is currently signed in
            if let currentUser = Auth.auth().currentUser {
                print("DEBUG: AuthService - Current user exists: \(currentUser.uid)")
            } else {
                print("DEBUG: AuthService - No current user found in Auth")
            }
            
            do {
                print("DEBUG: AuthService - Attempting Firebase signOut")
                try Auth.auth().signOut()
                print("DEBUG: AuthService - Firebase signOut successful")
                
                // Manually update our local state
                DispatchQueue.main.async {
                    print("DEBUG: AuthService - Manually updating local state")
                    self.user = nil
                    self.isAuthenticated = false
                    promise(.success(()))
                }
            } catch let error {
                print("ERROR: AuthService - SignOut failed: \(error)")
                promise(.failure(error))
            }
        }.eraseToAnyPublisher()
    }
    
    func signInWithGoogle(presenting viewController: UIViewController) -> AnyPublisher<Void, Error> {
        return Future<Void, Error> { [weak self] promise in
            guard let clientID = FirebaseApp.app()?.options.clientID else {
                let error = NSError(domain: "AuthenticationService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Firebase configuration error"])
                promise(.failure(error))
                return
            }
            
            // Create Google Sign In configuration object
            let config = GIDConfiguration(clientID: clientID)
            GIDSignIn.sharedInstance.configuration = config
            
            // Start the sign in flow
            GIDSignIn.sharedInstance.signIn(withPresenting: viewController) { [weak self] result, error in
                if let error = error {
                    print("DEBUG: Google Sign-In error: \(error)")
                    promise(.failure(error))
                    self?.errorMessage = error.localizedDescription
                    return
                }
                
                guard let user = result?.user,
                      let idToken = user.idToken?.tokenString else {
                    let error = NSError(domain: "AuthenticationService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Google Sign-In missing token"])
                    promise(.failure(error))
                    self?.errorMessage = "Authentication failed"
                    return
                }
                
                // Create Google credential
                let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: user.accessToken.tokenString)
                
                // Sign in with Firebase
                Auth.auth().signIn(with: credential) { authResult, error in
                    if let error = error {
                        print("DEBUG: Firebase Auth with Google error: \(error)")
                        promise(.failure(error))
                        self?.errorMessage = error.localizedDescription
                        return
                    }
                    
                    // Check if this is a new user
                    let isNewUser = authResult?.additionalUserInfo?.isNewUser ?? false
                    
                    if isNewUser {
                        // Create new user in Firestore
                        guard let firebaseUser = authResult?.user else {
                            promise(.success(()))
                            return
                        }
                        
                        // Use display name from Google or email prefix as username
                        let username = firebaseUser.displayName ?? firebaseUser.email?.components(separatedBy: "@").first ?? "User"
                        let email = firebaseUser.email ?? ""
                        let photoURL = firebaseUser.photoURL?.absoluteString
                        
                        let newUser = User(id: firebaseUser.uid, 
                                          username: username, 
                                          email: email,
                                          profileImageURL: photoURL)
                        
                        UserService.shared.createUser(newUser)
                            .sink(receiveCompletion: { completion in
                                if case .failure(let error) = completion {
                                    print("DEBUG: Error creating Google user in Firestore: \(error)")
                                } else {
                                    print("DEBUG: Google user successfully created in Firestore")
                                }
                                promise(.success(()))
                            }, receiveValue: { _ in })
                            .store(in: &self!.cancellables)
                    } else {
                        promise(.success(()))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    deinit {
        if let handle = handle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
    
    // Add a public method to store cancellables
    func store(cancellable: AnyCancellable) {
        cancellable.store(in: &cancellables)
    }
} 