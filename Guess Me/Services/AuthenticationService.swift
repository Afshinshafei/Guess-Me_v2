import Foundation
import FirebaseAuth
import Combine
import GoogleSignIn
import FirebaseCore
import AuthenticationServices
import CryptoKit

class AuthenticationService: ObservableObject {
    @Published var user: User?
    @Published var isAuthenticated = false
    @Published var errorMessage: String?
    
    internal var cancellables = Set<AnyCancellable>()
    private var handle: AuthStateDidChangeListenerHandle?
    private var currentNonce: String?
    
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
    
    func signInWithApple(credential: ASAuthorizationAppleIDCredential) -> AnyPublisher<Void, Error> {
        return Future<Void, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "AuthenticationService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Service unavailable"])))
                return
            }
            
            print("DEBUG: Starting Apple Sign In with credential: \(credential.user)")
            
            // Validate the nonce
            guard let nonce = self.currentNonce else {
                let error = NSError(domain: "AuthenticationService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid state: A login callback was received, but no login request was sent."])
                print("DEBUG: Apple Sign In Error - Missing nonce: \(error.localizedDescription)")
                self.errorMessage = error.localizedDescription
                promise(.failure(error))
                return
            }
            
            // Get the identity token
            guard let appleIDToken = credential.identityToken else {
                let error = NSError(domain: "AuthenticationService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unable to fetch identity token"])
                print("DEBUG: Apple Sign In Error - Missing identity token: \(error.localizedDescription)")
                self.errorMessage = error.localizedDescription
                promise(.failure(error))
                return
            }
            
            // Convert the token to a string
            guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                let error = NSError(domain: "AuthenticationService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unable to serialize token string from data"])
                print("DEBUG: Apple Sign In Error - Could not convert token to string: \(error.localizedDescription)")
                self.errorMessage = error.localizedDescription
                promise(.failure(error))
                return
            }
            
            print("DEBUG: Successfully obtained Apple ID token")
            
            // Create a Firebase credential using the Apple ID token
            let firebaseCredential = OAuthProvider.credential(
                withProviderID: "apple.com",
                idToken: idTokenString,
                rawNonce: nonce
            )
            
            // Sign in with Firebase using the Apple credential
            Auth.auth().signIn(with: firebaseCredential) { [weak self] (authResult, error) in
                if let error = error {
                    print("DEBUG: Error signing in with Apple: \(error.localizedDescription)")
                    self?.errorMessage = error.localizedDescription
                    promise(.failure(error))
                    return
                }
                
                print("DEBUG: Successfully signed in with Apple")
                
                // Check if this is a new user
                let isNewUser = authResult?.additionalUserInfo?.isNewUser ?? false
                
                if isNewUser {
                    // Create new user in Firestore for Apple sign in
                    guard let firebaseUser = authResult?.user else {
                        print("DEBUG: Firebase user is nil after successful sign in")
                        promise(.success(()))
                        return
                    }
                    
                    print("DEBUG: Creating new user in Firestore for Apple Sign In user: \(firebaseUser.uid)")
                    
                    // Extract user information (Apple might provide a limited set)
                    var displayName = credential.fullName?.givenName ?? ""
                    if let familyName = credential.fullName?.familyName {
                        displayName += displayName.isEmpty ? familyName : " \(familyName)"
                    }
                    
                    // Use display name or email prefix as fallback for username
                    let username = displayName.isEmpty 
                        ? (credential.email?.components(separatedBy: "@").first ?? "User")
                        : displayName
                    
                    let email = credential.email ?? firebaseUser.email ?? ""
                    
                    // Create new user model
                    let newUser = User(
                        id: firebaseUser.uid,
                        username: username,
                        email: email,
                        appleUserIdentifier: credential.user
                    )
                    
                    // Store in Firestore
                    UserService.shared.createUser(newUser)
                        .sink(receiveCompletion: { completion in
                            if case .failure(let error) = completion {
                                print("DEBUG: Error creating Apple user in Firestore: \(error)")
                            } else {
                                print("DEBUG: Apple user successfully created in Firestore")
                            }
                            promise(.success(()))
                        }, receiveValue: { _ in })
                        .store(in: &self!.cancellables)
                } else {
                    print("DEBUG: Existing user signed in with Apple")
                    promise(.success(()))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    // MARK: - Apple Sign In Helpers
    
    // Generate a random nonce string for Apple authentication
    func generateNonce(length: Int = 32) -> String {
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        
        while remainingLength > 0 {
            let randoms: [UInt8] = (0 ..< 16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
                }
                return random
            }
            
            for random in randoms {
                if remainingLength == 0 {
                    break
                }
                
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        
        return result
    }
    
    // Hash a string using SHA256
    func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            return String(format: "%02x", $0)
        }.joined()
        
        return hashString
    }
    
    // Prepare Apple sign in request by setting the nonce
    func startSignInWithAppleFlow() -> ASAuthorizationAppleIDRequest {
        print("DEBUG: Starting Apple Sign In flow")
        let nonce = generateNonce()
        currentNonce = nonce
        print("DEBUG: Generated nonce for Apple Sign In: \(nonce.prefix(5))...")
        
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        
        // Request full name and email - essential for new account creation
        request.requestedScopes = [.fullName, .email]
        
        // Set the nonce for security validation
        let hashedNonce = sha256(nonce)
        print("DEBUG: Set hashed nonce on request: \(hashedNonce.prefix(10))...")
        request.nonce = hashedNonce
        
        return request
    }
    
    // Delete account functionality
    func deleteAccount() -> AnyPublisher<Void, Error> {
        return Future<Void, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "AuthenticationService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Service unavailable"])))
                return
            }
            
            guard let currentUser = Auth.auth().currentUser, let userId = currentUser.uid as String? else {
                promise(.failure(NSError(domain: "AuthenticationService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No user is currently signed in"])))
                return
            }
            
            print("DEBUG: AuthService - Starting complete account deletion process for user \(userId)")
            
            // Try to delete profile image but don't let it stop the account deletion process if it fails
            StorageService.shared.deleteProfileImage(userId: userId)
                .catch { error -> AnyPublisher<Void, Error> in
                    // If there's a permission error with storage, log it and continue with the deletion process
                    print("WARNING: AuthService - Could not delete profile image due to permissions: \(error.localizedDescription)")
                    print("WARNING: AuthService - Continuing with account deletion anyway")
                    
                    // Return a publisher that immediately completes successfully
                    return Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
                }
                .flatMap { _ -> AnyPublisher<Void, Error> in
                    print("DEBUG: AuthService - Now deleting user data from Firestore")
                    // Delete user data from Firestore
                    return UserService.shared.deleteUser(userId: userId)
                }
                .flatMap { _ -> AnyPublisher<Void, Error> in
                    // Finally delete the Firebase Auth account
                    return Future<Void, Error> { promise in
                        print("DEBUG: AuthService - User data deleted, now deleting Auth account")
                        
                        // The Firebase "Delete User Data" extension is triggered automatically 
                        // when the user is deleted from Firebase Auth - it will clean up any
                        // remaining data based on the extension's configuration
                        currentUser.delete { error in
                            if let error = error {
                                // Check for re-authentication requirement
                                if (error as NSError).code == AuthErrorCode.requiresRecentLogin.rawValue {
                                    print("ERROR: AuthService - Re-authentication required: \(error.localizedDescription)")
                                    // Specific error for re-authentication
                                    let reAuthError = NSError(
                                        domain: "AuthenticationService",
                                        code: 9999, // Custom code for re-authentication
                                        userInfo: [NSLocalizedDescriptionKey: "Please sign in again to confirm your identity before deleting your account."]
                                    )
                                    promise(.failure(reAuthError))
                                    return
                                }
                                
                                print("ERROR: AuthService - Failed to delete Auth account: \(error)")
                                promise(.failure(error))
                                return
                            }
                            
                            print("DEBUG: AuthService - Auth account deleted successfully")
                            promise(.success(()))
                        }
                    }
                    .eraseToAnyPublisher()
                }
                .sink(receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("ERROR: AuthService - Account deletion failed: \(error)")
                        promise(.failure(error))
                    } else {
                        // Set local state to logged out
                        DispatchQueue.main.async {
                            print("DEBUG: AuthService - Account deletion completed successfully")
                            self.user = nil
                            self.isAuthenticated = false
                            // Post notification of account deletion
                            NotificationCenter.default.post(name: NSNotification.Name("AccountDeleted"), object: nil)
                            promise(.success(()))
                        }
                    }
                }, receiveValue: { _ in })
                .store(in: &self.cancellables)
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