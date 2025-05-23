import SwiftUI
import Combine
import FirebaseAuth
import GoogleSignIn
import UIKit
import AuthenticationServices

struct AuthView: View {
    @State private var isSigningUp = false
    @EnvironmentObject var authService: AuthenticationService
    @EnvironmentObject var navigationCoordinator: NavigationCoordinator
    @State private var animateBackground = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Animated background
                LinearGradient(
                    colors: [
                        AppTheme.primary.opacity(0.8),
                        AppTheme.tertiary.opacity(0.6),
                        AppTheme.secondary.opacity(0.7)
                    ],
                    startPoint: animateBackground ? .topLeading : .bottomLeading,
                    endPoint: animateBackground ? .bottomTrailing : .topTrailing
                )
                .hueRotation(.degrees(animateBackground ? 45 : 0))
                .ignoresSafeArea()
                .onAppear {
                    withAnimation(.linear(duration: 20).repeatForever(autoreverses: true)) {
                        animateBackground.toggle()
                    }
                }
                
                // Content
                ScrollView {
                    VStack(spacing: 20) {
                        // Logo and welcome text
                        VStack(spacing: 10) {
                            Image(systemName: "person.2.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 100, height: 100)
                                .foregroundColor(AppTheme.textOnDark)
                                .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
                            
                            Text("MugMatch")
                                .font(AppTheme.title())
                                .foregroundColor(AppTheme.textOnDark)
                                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                            
                            Text("The Social Guessing Game")
                                .font(AppTheme.subheading())
                                .foregroundColor(AppTheme.textOnDark.opacity(0.8))
                                .padding(.bottom, 10)
                        }
                        .padding(.top, 40)
                        
                        // Auth form container
                        VStack {
                            // Auth form
                            if isSigningUp {
                                SignUpView(isSigningUp: $isSigningUp)
                            } else {
                                SignInView(isSigningUp: $isSigningUp)
                            }
                            
                            // Error message display
                            if let errorMessage = authService.errorMessage {
                                Text(errorMessage)
                                    .font(AppTheme.caption())
                                    .foregroundColor(AppTheme.incorrect)
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(AppTheme.incorrect.opacity(0.1))
                                    )
                                    .padding(.top, 10)
                            }
                        }
                        .padding(24)
                        .background(
                            RoundedRectangle(cornerRadius: 30)
                                .fill(AppTheme.cardBackground)
                                .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: 10)
                        )
                        .padding(.horizontal)
                        .padding(.bottom, 40)
                    }
                    .padding(.vertical)
                }
                .navigationBarHidden(true)
            }
        }
        .scrollDismissesKeyboard(.interactively)
    }
}

struct SignInView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var isGoogleSignInLoading = false
    @State private var isAppleSignInLoading = false
    @Binding var isSigningUp: Bool
    @EnvironmentObject var authService: AuthenticationService
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Welcome Back!")
                .font(AppTheme.heading())
                .foregroundColor(AppTheme.textPrimary)
                .padding(.bottom, 5)
            
            // Email field
            VStack(alignment: .leading, spacing: 8) {
                Text("Email")
                    .font(AppTheme.caption())
                    .foregroundColor(AppTheme.textSecondary)
                
                HStack {
                    Image(systemName: "envelope.fill")
                        .foregroundColor(AppTheme.primary)
                    
                    TextField("your@email.com", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .textContentType(.username)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppTheme.primary.opacity(0.3), lineWidth: 1)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(AppTheme.cardBackground)
                        )
                )
            }
            
            // Password field
            VStack(alignment: .leading, spacing: 8) {
                Text("Password")
                    .font(AppTheme.caption())
                    .foregroundColor(AppTheme.textSecondary)
                
                HStack {
                    Image(systemName: "lock.fill")
                        .foregroundColor(AppTheme.primary)
                    
                    SecureField("••••••••", text: $password)
                        .textContentType(.password)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppTheme.primary.opacity(0.3), lineWidth: 1)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(AppTheme.cardBackground)
                        )
                )
            }
            
            Button(action: signIn) {
                HStack {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .tint(AppTheme.textOnDark)
                    } else {
                        Text("Sign In")
                            .font(.system(.body, design: .rounded, weight: .bold))
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(email.isEmpty || password.isEmpty || isLoading ? 
                              AppTheme.primary.opacity(0.5) : AppTheme.primary)
                        .shadow(color: AppTheme.primary.opacity(0.4), radius: 8, x: 0, y: 4)
                )
                .foregroundColor(AppTheme.textOnDark)
            }
            .disabled(email.isEmpty || password.isEmpty || isLoading)
            .padding(.top, 10)
            
            // Divider with "OR" text
            HStack {
                VStack { Divider().background(AppTheme.textSecondary.opacity(0.5)) }
                Text("OR")
                    .font(AppTheme.caption())
                    .foregroundColor(AppTheme.textSecondary)
                    .padding(.horizontal, 8)
                VStack { Divider().background(AppTheme.textSecondary.opacity(0.5)) }
            }
            .padding(.vertical, 8)
            
            // Sign in with Apple Button
            SignInWithAppleButton(
                .signIn,
                onRequest: { request in
                    let authRequest = authService.startSignInWithAppleFlow()
                    request.requestedScopes = authRequest.requestedScopes
                    request.nonce = authRequest.nonce
                },
                onCompletion: { result in
                    handleAppleSignInResult(result)
                }
            )
            .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
            .frame(height: 50)
            .padding(.bottom, 8)
            
            // Google Sign-In Button
            Button(action: signInWithGoogle) {
                HStack {
                    if isGoogleSignInLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .tint(AppTheme.textPrimary)
                    } else {
                        Image("google_logo") // Make sure to add this image to your assets
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                            .padding(.trailing, 8)
                        
                        Text("Sign in with Google")
                            .font(.system(.body, design: .rounded, weight: .medium))
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(AppTheme.textSecondary.opacity(0.3), lineWidth: 1)
                        .background(RoundedRectangle(cornerRadius: 16)
                            .fill(colorScheme == .dark ? Color(UIColor.systemGray6) : Color.white))
                )
                .foregroundColor(colorScheme == .dark ? Color.white : AppTheme.textPrimary)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            }
            .disabled(isGoogleSignInLoading)
            
            Button(action: {
                withAnimation {
                    isSigningUp = true
                }
            }) {
                Text("New to MugMatch? Sign Up")
                    .font(.system(.body, design: .rounded, weight: .medium))
                    .foregroundColor(AppTheme.secondary)
                    .padding(.top, 10)
            }
        }
    }
    
    private func signIn() {
        isLoading = true
        
        authService.signIn(email: email, password: password)
            .receive(on: DispatchQueue.main)
            .sink { completion in
                isLoading = false
                
                if case .failure(let error) = completion {
                    print("Error signing in: \(error)")
                }
            } receiveValue: { _ in
                // Successfully signed in, the auth state listener will handle the transition
            }
            .store(in: &authService.cancellables)
    }
    
    private func signInWithGoogle() {
        isGoogleSignInLoading = true
        
        // Get the root view controller
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            isGoogleSignInLoading = false
            return
        }
        
        authService.signInWithGoogle(presenting: rootViewController)
            .receive(on: DispatchQueue.main)
            .sink { completion in
                isGoogleSignInLoading = false
                
                if case .failure(let error) = completion {
                    print("Error signing in with Google: \(error)")
                }
            } receiveValue: { _ in
                // Successfully signed in, the auth state listener will handle the transition
            }
            .store(in: &authService.cancellables)
    }
    
    private func handleAppleSignInResult(_ result: Result<ASAuthorization, Error>) {
        isAppleSignInLoading = true
        
        switch result {
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                isAppleSignInLoading = false
                print("Error: Could not get Apple ID credential")
                return
            }
            
            authService.signInWithApple(credential: credential)
                .receive(on: DispatchQueue.main)
                .sink { completion in
                    isAppleSignInLoading = false
                    
                    if case .failure(let error) = completion {
                        print("Error signing in with Apple: \(error)")
                    }
                } receiveValue: { _ in
                    // Successfully signed in, the auth state listener will handle the transition
                }
                .store(in: &authService.cancellables)
            
        case .failure(let error):
            isAppleSignInLoading = false
            print("Apple sign in failed: \(error)")
        }
    }
}

struct SignUpView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var username = ""
    @State private var isLoading = false
    @State private var isGoogleSignInLoading = false
    @State private var isAppleSignInLoading = false
    @State private var signupSuccess = false
    @Binding var isSigningUp: Bool
    @EnvironmentObject var authService: AuthenticationService
    @EnvironmentObject var navigationCoordinator: NavigationCoordinator
    @Environment(\.colorScheme) var colorScheme
    
    var passwordsMatch: Bool {
        return password == confirmPassword
    }
    
    var isFormValid: Bool {
        return !email.isEmpty && !password.isEmpty && passwordsMatch && password.count >= 6 && !username.isEmpty
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Join the Fun!")
                .font(AppTheme.heading())
                .foregroundColor(AppTheme.textPrimary)
                .padding(.bottom, 5)
            
            if signupSuccess {
                // Show success message when signup is complete
                VStack(spacing: 20) {
                    LottieView(name: "success_animation")
                        .frame(width: 120, height: 120)
                    
                    Text("Woohoo! Account Created!")
                        .font(AppTheme.subheading())
                        .foregroundColor(AppTheme.textPrimary)
                    
                    Text("Get ready for some fun guessing games!")
                        .font(AppTheme.body())
                        .foregroundColor(AppTheme.textSecondary)
                        .multilineTextAlignment(.center)
                    
                    ProgressView()
                        .tint(AppTheme.primary)
                        .padding(.top)
                }
                .padding()
            } else {
                // Username field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Username")
                        .font(AppTheme.caption())
                        .foregroundColor(AppTheme.textSecondary)
                    
                    HStack {
                        Image(systemName: "person.fill")
                            .foregroundColor(AppTheme.tertiary)
                        
                        TextField("Choose a username", text: $username)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(AppTheme.tertiary.opacity(0.3), lineWidth: 1)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(AppTheme.cardBackground)
                            )
                    )
                }
                
                // Email field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Email")
                        .font(AppTheme.caption())
                        .foregroundColor(AppTheme.textSecondary)
                    
                    HStack {
                        Image(systemName: "envelope.fill")
                            .foregroundColor(AppTheme.tertiary)
                        
                        TextField("your@email.com", text: $email)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .textContentType(.emailAddress)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(AppTheme.tertiary.opacity(0.3), lineWidth: 1)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(AppTheme.cardBackground)
                            )
                    )
                }
                
                // Password field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Password")
                        .font(AppTheme.caption())
                        .foregroundColor(AppTheme.textSecondary)
                    
                    HStack {
                        Image(systemName: "lock.fill")
                            .foregroundColor(AppTheme.tertiary)
                        
                        SecureField("At least 6 characters", text: $password)
                            .textContentType(.newPassword)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(AppTheme.tertiary.opacity(0.3), lineWidth: 1)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(AppTheme.cardBackground)
                            )
                    )
                }
                
                // Confirm Password field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Confirm Password")
                        .font(AppTheme.caption())
                        .foregroundColor(AppTheme.textSecondary)
                    
                    HStack {
                        Image(systemName: "lock.shield.fill")
                            .foregroundColor(AppTheme.tertiary)
                        
                        SecureField("Confirm your password", text: $confirmPassword)
                            .textContentType(.newPassword)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(AppTheme.tertiary.opacity(0.3), lineWidth: 1)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(AppTheme.cardBackground)
                            )
                    )
                }
                
                if !passwordsMatch && !confirmPassword.isEmpty {
                    Text("Passwords do not match")
                        .font(AppTheme.caption())
                        .foregroundColor(AppTheme.incorrect)
                }
                
                Button(action: signUp) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .tint(AppTheme.textOnDark)
                        } else {
                            Text("Create Account")
                                .font(.system(.body, design: .rounded, weight: .bold))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(isFormValid && !isLoading ? AppTheme.secondary : AppTheme.secondary.opacity(0.5))
                            .shadow(color: AppTheme.secondary.opacity(0.4), radius: 8, x: 0, y: 4)
                    )
                    .foregroundColor(AppTheme.textOnDark)
                }
                .disabled(!isFormValid || isLoading)
                .padding(.top, 5)
                
                // Divider with "OR" text
                HStack {
                    VStack { Divider().background(AppTheme.textSecondary.opacity(0.5)) }
                    Text("OR")
                        .font(AppTheme.caption())
                        .foregroundColor(AppTheme.textSecondary)
                        .padding(.horizontal, 8)
                    VStack { Divider().background(AppTheme.textSecondary.opacity(0.5)) }
                }
                .padding(.vertical, 8)
                
                // Sign in with Apple Button
                SignInWithAppleButton(
                    .signUp,
                    onRequest: { request in
                        let authRequest = authService.startSignInWithAppleFlow()
                        request.requestedScopes = authRequest.requestedScopes
                        request.nonce = authRequest.nonce
                    },
                    onCompletion: { result in
                        handleAppleSignInResult(result)
                    }
                )
                .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
                .frame(height: 50)
                .padding(.bottom, 8)
                
                // Google Sign-Up Button
                Button(action: signUpWithGoogle) {
                    HStack {
                        if isGoogleSignInLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .tint(AppTheme.textPrimary)
                        } else {
                            Image("google_logo") // Make sure to add this image to your assets
                                .resizable()
                                .scaledToFit()
                                .frame(width: 20, height: 20)
                                .padding(.trailing, 8)
                            
                            Text("Continue with Google")
                                .font(.system(.body, design: .rounded, weight: .medium))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(AppTheme.textSecondary.opacity(0.3), lineWidth: 1)
                            .background(RoundedRectangle(cornerRadius: 16)
                                .fill(colorScheme == .dark ? Color(UIColor.systemGray6) : Color.white))
                    )
                    .foregroundColor(colorScheme == .dark ? Color.white : AppTheme.textPrimary)
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                }
                .disabled(isGoogleSignInLoading)
                
                Button(action: {
                    withAnimation {
                        isSigningUp = false
                    }
                }) {
                    Text("Already have an account? Sign In")
                        .font(.system(.body, design: .rounded, weight: .medium))
                        .foregroundColor(AppTheme.primary)
                        .padding(.top, 10)
                }
            }
        }
    }
    
    private func signUp() {
        isLoading = true
        print("DEBUG: Starting signup process for \(username)")
        
        authService.signUp(email: email, password: password, username: username)
            .receive(on: DispatchQueue.main)
            .sink { completion in
                if case .failure(let error) = completion {
                    isLoading = false
                    print("DEBUG: Error signing up: \(error)")
                } else {
                    print("DEBUG: Signup successful, show success message")
                    // Show success message before transitioning
                    withAnimation(.spring(response: 0.5)) {
                        signupSuccess = true
                    }
                    
                    // Let the NavigationCoordinator handle the routing
                    // The authService.$isAuthenticated publisher will trigger navigation to TutorialView
                }
            } receiveValue: { _ in
                // No additional action needed here, handled in completion
            }
            .store(in: &authService.cancellables)
    }
    
    private func signUpWithGoogle() {
        isGoogleSignInLoading = true
        
        // Get the root view controller
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            isGoogleSignInLoading = false
            return
        }
        
        authService.signInWithGoogle(presenting: rootViewController)
            .receive(on: DispatchQueue.main)
            .sink { completion in
                isGoogleSignInLoading = false
                
                if case .failure(let error) = completion {
                    print("Error signing up with Google: \(error)")
                }
            } receiveValue: { _ in
                // Successfully signed in with Google
                // The auth state listener will handle the transition
            }
            .store(in: &authService.cancellables)
    }
    
    private func handleAppleSignInResult(_ result: Result<ASAuthorization, Error>) {
        isAppleSignInLoading = true
        
        switch result {
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                isAppleSignInLoading = false
                print("Error: Could not get Apple ID credential")
                return
            }
            
            authService.signInWithApple(credential: credential)
                .receive(on: DispatchQueue.main)
                .sink { completion in
                    isAppleSignInLoading = false
                    
                    if case .failure(let error) = completion {
                        print("Error signing up with Apple: \(error)")
                    }
                } receiveValue: { _ in
                    // Successfully signed in, the auth state listener will handle the transition
                    print("DEBUG: Apple sign in successful, showing success message")
                    // Show success message before transitioning
                    withAnimation(.spring(response: 0.5)) {
                        signupSuccess = true
                    }
                }
                .store(in: &authService.cancellables)
            
        case .failure(let error):
            isAppleSignInLoading = false
            print("Apple sign up failed: \(error)")
        }
    }
}

// LottieView is now defined in Shared/LottieView.swift

#Preview {
    let authService = AuthenticationService()
    return AuthView()
        .environmentObject(authService)
        .environmentObject(NavigationCoordinator(authService: authService))
} 