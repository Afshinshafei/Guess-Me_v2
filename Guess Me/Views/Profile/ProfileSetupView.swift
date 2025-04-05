import SwiftUI
import PhotosUI
import Combine

class ProfileSetupViewModel: ObservableObject {
    @Published var username = ""
    @Published var age: String = ""
    @Published var occupation = ""
    @Published var education = ""
    @Published var height: String = ""
    @Published var weight: String = ""
    @Published var smoker = false
    @Published var selectedPhotoItem: PhotosPickerItem?
    @Published var selectedImage: UIImage?
    @Published var isLoading = false
    @Published var loadingMessage = "Saving your profile..."
    @Published var currentStep = 0
    @Published var setupComplete = false
    @Published var errorMessage: String?
    @Published var showError = false
    
    var authService: AuthenticationService
    private var cancellables = Set<AnyCancellable>()
    
    init(authService: AuthenticationService) {
        self.authService = authService
        loadUserDataFromService()
    }
    
    func loadUserDataFromService() {
        if let user = authService.user {
            username = user.username
            // Load other data if available
            if let age = user.age {
                self.age = "\(age)"
            }
            occupation = user.occupation ?? ""
            education = user.education ?? ""
            if let height = user.height {
                self.height = "\(Int(height))"
            }
            if let weight = user.weight {
                self.weight = "\(Int(weight))"
            }
            smoker = user.smoker ?? false
        }
    }
    
    func processSelectedPhoto() {
        Task {
            if let selectedPhotoItem = selectedPhotoItem,
               let data = try? await selectedPhotoItem.loadTransferable(type: Data.self),
               let uiImage = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.selectedImage = uiImage
                }
            }
        }
    }
    
    // Form validation for each step
    func isStepValid() -> Bool {
        switch currentStep {
        case 0: // Basic info
            return !username.isEmpty && !age.isEmpty && Int(age) != nil
        case 1: // Details
            return !height.isEmpty && !weight.isEmpty && 
                   Double(height) != nil && Double(weight) != nil
        case 2: // Photo
            return selectedImage != nil
        case 3: // Review
            return true // Review step is always valid
        default:
            return false
        }
    }
    
    func nextStep() {
        if !isStepValid() {
            showValidationError()
            return
        }
        
        if currentStep < 3 {
            currentStep += 1
        } else {
            saveProfile()
        }
    }
    
    func previousStep() {
        if currentStep > 0 {
            currentStep -= 1
        }
    }
    
    private func showValidationError() {
        var message = "Please fill in all required fields:"
        
        switch currentStep {
        case 0:
            if username.isEmpty {
                message += "\n- Username"
            }
            if age.isEmpty || Int(age) == nil {
                message += "\n- Valid age"
            }
        case 1:
            if height.isEmpty || Double(height) == nil {
                message += "\n- Valid height"
            }
            if weight.isEmpty || Double(weight) == nil {
                message += "\n- Valid weight"
            }
        case 2:
            message = "Please select a profile photo"
        default:
            message = "Please complete all required fields"
        }
        
        errorMessage = message
        showError = true
    }
    
    func saveProfile() {
        guard var user = authService.user else { 
            errorMessage = "Error: No user available to save profile"
            showError = true
            return 
        }
        
        isLoading = true
        loadingMessage = "Saving your profile..."
        print("DEBUG: ProfileSetupView - Saving profile for user: \(user.username)")
        
        // Update user data
        user.username = username
        user.age = Int(age)
        user.occupation = occupation.isEmpty ? nil : occupation
        user.education = education.isEmpty ? nil : education
        user.height = Double(height)
        user.weight = Double(weight)
        user.smoker = smoker
        
        // Ensure hasCompletedSetup is set to true
        user.hasCompletedSetup = true
        print("DEBUG: ProfileSetupView - Setting hasCompletedSetup to true")
        
        var publisher: AnyPublisher<Void, Error> = Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
        
        // Upload image if selected
        if let selectedImage = selectedImage, let userId = user.id {
            print("DEBUG: ProfileSetupView - Uploading profile image for user: \(userId)")
            loadingMessage = "Uploading your profile photo..."
            
            publisher = StorageService.shared.uploadProfileImage(selectedImage, userId: userId)
                .flatMap { url -> AnyPublisher<Void, Error> in
                    print("DEBUG: ProfileSetupView - Image uploaded successfully, URL: \(url)")
                    user.profileImageURL = url.absoluteString
                    self.loadingMessage = "Saving your profile information..."
                    return UserService.shared.updateUser(user)
                }
                .eraseToAnyPublisher()
        } else {
            print("DEBUG: ProfileSetupView - No image selected, just updating user data")
            publisher = UserService.shared.updateUser(user)
        }
        
        publisher
            .receive(on: DispatchQueue.main)
            .sink { completion in
                self.isLoading = false
                
                if case .failure(let error) = completion {
                    print("ERROR: ProfileSetupView - Error saving profile: \(error)")
                    self.errorMessage = "Failed to save profile: \(error.localizedDescription)"
                    self.showError = true
                } else {
                    // Success
                    print("DEBUG: ProfileSetupView - Profile saved successfully with hasCompletedSetup=true")
                    self.setupComplete = true
                }
            } receiveValue: { _ in
                // Refresh user data
                if let userId = user.id {
                    print("DEBUG: ProfileSetupView - Refreshing user data after save")
                    UserService.shared.fetchUser(withUID: userId)
                        .receive(on: DispatchQueue.main)
                        .sink(receiveCompletion: { completion in
                            if case .failure(let error) = completion {
                                print("ERROR: ProfileSetupView - Error refreshing user data: \(error)")
                                self.errorMessage = "Profile saved but failed to refresh: \(error.localizedDescription)"
                                self.showError = true
                            }
                        }, receiveValue: { user in
                            print("DEBUG: ProfileSetupView - User data refreshed: \(user.username), hasCompletedSetup: \(user.hasCompletedSetup)")
                            self.authService.user = user
                        })
                        .store(in: &self.cancellables)
                }
            }
            .store(in: &cancellables)
    }
}

struct ProfileSetupView: View {
    @EnvironmentObject var authService: AuthenticationService
    @EnvironmentObject var navigationCoordinator: NavigationCoordinator
    @StateObject private var viewModel: ProfileSetupViewModel
    @State private var animateBackground = false
    
    // Add a dismiss environment key
    @Environment(\.dismiss) private var dismiss
    
    init() {
        // Use a temporary AuthenticationService for preview
        _viewModel = StateObject(wrappedValue: ProfileSetupViewModel(authService: AuthenticationService()))
    }
    
    var body: some View {
        ZStack {
            // Animated gradient background
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
            
            VStack(spacing: 20) {
                // Custom progress bar
                VStack(spacing: 8) {
                    HStack(spacing: 3) {
                        ForEach(0..<4) { index in
                            RoundedRectangle(cornerRadius: 3)
                                .fill(index <= viewModel.currentStep ? 
                                      AppTheme.secondary : 
                                      AppTheme.textOnDark.opacity(0.3))
                                .frame(height: 6)
                                .animation(.springy, value: viewModel.currentStep)
                        }
                    }
                    
                    // Step labels
                    HStack {
                        Text("Basics")
                            .font(AppTheme.caption())
                            .foregroundColor(0 == viewModel.currentStep ? 
                                            AppTheme.textOnDark : 
                                            AppTheme.textOnDark.opacity(0.7))
                        
                        Spacer()
                        
                        Text("Details")
                            .font(AppTheme.caption())
                            .foregroundColor(1 == viewModel.currentStep ? 
                                            AppTheme.textOnDark : 
                                            AppTheme.textOnDark.opacity(0.7))
                        
                        Spacer()
                        
                        Text("Photo")
                            .font(AppTheme.caption())
                            .foregroundColor(2 == viewModel.currentStep ? 
                                            AppTheme.textOnDark : 
                                            AppTheme.textOnDark.opacity(0.7))
                        
                        Spacer()
                        
                        Text("Review")
                            .font(AppTheme.caption())
                            .foregroundColor(3 == viewModel.currentStep ? 
                                            AppTheme.textOnDark : 
                                            AppTheme.textOnDark.opacity(0.7))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                if viewModel.isLoading {
                    VStack(spacing: 20) {
                        LottieView(name: "loading_animation")
                            .frame(width: 120, height: 120)
                        
                        Text(viewModel.loadingMessage)
                            .font(AppTheme.heading())
                            .foregroundColor(AppTheme.textPrimary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(width: 280)
                    .padding(30)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(AppTheme.cardBackground)
                            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                    )
                    .transition(.opacity)
                    .zIndex(100)
                } else {
                    ScrollView {
                        VStack(spacing: 25) {
                            // Header
                            VStack(spacing: 8) {
                                Text("Welcome to GuessMe!")
                                    .font(AppTheme.title())
                                    .foregroundColor(AppTheme.textOnDark)
                                    .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)
                                
                                Text("Let's set up your profile")
                                    .font(AppTheme.body())
                                    .foregroundColor(AppTheme.textOnDark.opacity(0.9))
                                    .padding(.bottom, 5)
                            }
                            .padding(.top, 10)
                            
                            // Content container
                            VStack(spacing: 25) {
                                Group {
                                    switch viewModel.currentStep {
                                    case 0:
                                        basicInfoStep
                                    case 1:
                                        detailsStep
                                    case 2:
                                        photoStep
                                    case 3:
                                        reviewStep
                                    default:
                                        EmptyView()
                                    }
                                }
                                .transition(.opacity)
                                .animation(.gentle, value: viewModel.currentStep)
                                
                                // Navigation buttons
                                HStack(spacing: 15) {
                                    if viewModel.currentStep > 0 {
                                        Button("Back") {
                                            withAnimation(.springy) {
                                                viewModel.previousStep()
                                            }
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(
                                            RoundedRectangle(cornerRadius: 16)
                                                .fill(AppTheme.textOnDark.opacity(0.2))
                                        )
                                        .foregroundColor(AppTheme.textOnDark)
                                        .font(.system(.body, design: .rounded, weight: .semibold))
                                        .buttonStyle(ScaleButtonStyle())
                                    }
                                    
                                    Button(viewModel.currentStep == 3 ? "Finish" : "Next") {
                                        withAnimation(.springy) {
                                            viewModel.nextStep()
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(viewModel.isStepValid() ? AppTheme.secondary : AppTheme.secondary.opacity(0.5))
                                            .shadow(color: AppTheme.secondary.opacity(0.3), radius: 8, x: 0, y: 4)
                                    )
                                    .foregroundColor(AppTheme.textOnDark)
                                    .font(.system(.body, design: .rounded, weight: .bold))
                                    .disabled(!viewModel.isStepValid())
                                    .buttonStyle(ScaleButtonStyle())
                                }
                                .padding(.top, 10)
                            }
                            .padding(25)
                            .background(
                                RoundedRectangle(cornerRadius: 30)
                                    .fill(AppTheme.cardBackground.opacity(0.8))
                                    .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: 10)
                            )
                            .padding(.horizontal, 20)
                        }
                        .padding(.bottom, 30)
                    }
                }
            }
        }
        .navigationTitle("")
        .navigationBarHidden(true)
        .onAppear {
            // Replace the viewModel with one that uses the environment object
            viewModel.authService = authService
            viewModel.loadUserDataFromService()
            print("DEBUG: ProfileSetupView appeared, user from auth service: \(authService.user?.username ?? "none")")
        }
        .onReceive(authService.$user) { user in
            // Update if user changes
            if let user = user {
                print("DEBUG: ProfileSetupView - user changed: \(user.username)")
                viewModel.loadUserDataFromService()
            }
        }
        // Use navigationCoordinator for navigation
        .onChange(of: viewModel.setupComplete) { oldValue, newValue in
            if newValue {
                print("DEBUG: Profile setup complete, navigating to main screen")
                // Short delay to allow Firebase to update
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    navigationCoordinator.completeProfileSetup()
                }
            }
        }
        .onChange(of: viewModel.selectedPhotoItem) { oldValue, newValue in
            viewModel.processSelectedPhoto()
        }
        .alert(isPresented: $viewModel.showError) {
            Alert(
                title: Text("Error"),
                message: Text(viewModel.errorMessage ?? "An unknown error occurred"),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    private var basicInfoStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Basic Information")
                .font(AppTheme.heading())
                .foregroundColor(AppTheme.textPrimary)
                .padding(.bottom, 5)
            
            VStack(alignment: .leading, spacing: 5) {
                Text("Username")
                    .font(AppTheme.caption())
                    .foregroundColor(AppTheme.textSecondary)
                
                TextField("Username", text: $viewModel.username)
                    .textFieldStyle(icon: "person.fill", iconColor: AppTheme.primary)
            }
            
            VStack(alignment: .leading, spacing: 5) {
                Text("Age")
                    .font(AppTheme.caption())
                    .foregroundColor(AppTheme.textSecondary)
                
                TextField("Age", text: $viewModel.age)
                    .textFieldStyle(icon: "calendar", iconColor: AppTheme.primary)
                    .keyboardType(.numberPad)
            }
        }
    }
    
    private var detailsStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("More About You")
                .font(AppTheme.heading())
                .foregroundColor(AppTheme.textPrimary)
                .padding(.bottom, 5)
            
            VStack(alignment: .leading, spacing: 5) {
                Text("Occupation")
                    .font(AppTheme.caption())
                    .foregroundColor(AppTheme.textSecondary)
                
                TextField("Occupation", text: $viewModel.occupation)
                    .textFieldStyle(icon: "briefcase.fill", iconColor: AppTheme.tertiary)
            }
            
            VStack(alignment: .leading, spacing: 5) {
                Text("Education")
                    .font(AppTheme.caption())
                    .foregroundColor(AppTheme.textSecondary)
                
                TextField("Education", text: $viewModel.education)
                    .textFieldStyle(icon: "book.fill", iconColor: AppTheme.tertiary)
            }
            
            VStack(alignment: .leading, spacing: 5) {
                Text("Height (cm)")
                    .font(AppTheme.caption())
                    .foregroundColor(AppTheme.textSecondary)
                
                TextField("Height", text: $viewModel.height)
                    .textFieldStyle(icon: "ruler", iconColor: AppTheme.tertiary)
                    .keyboardType(.numberPad)
            }
            
            VStack(alignment: .leading, spacing: 5) {
                Text("Weight (kg)")
                    .font(AppTheme.caption())
                    .foregroundColor(AppTheme.textSecondary)
                
                TextField("Weight", text: $viewModel.weight)
                    .textFieldStyle(icon: "scalemass", iconColor: AppTheme.tertiary)
                    .keyboardType(.numberPad)
            }
            
            HStack {
                Text("Smoker")
                    .font(AppTheme.body())
                    .foregroundColor(AppTheme.textPrimary)
                
                Spacer()
                
                Toggle("", isOn: $viewModel.smoker)
                    .toggleStyle(SwitchToggleStyle(tint: AppTheme.tertiary))
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppTheme.cardBackground)
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            )
        }
    }
    
    private var photoStep: some View {
        VStack(spacing: 25) {
            Text("Profile Photo")
                .font(AppTheme.heading())
                .foregroundColor(AppTheme.textPrimary)
                .padding(.bottom, 5)
            
            Text("Add a photo of yourself for others to guess your traits")
                .font(AppTheme.body())
                .foregroundColor(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [AppTheme.primary.opacity(0.2), AppTheme.secondary.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 220, height: 220)
                
                if let selectedImage = viewModel.selectedImage {
                    Image(uiImage: selectedImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 200, height: 200)
                        .clipShape(Circle())
                        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
                        .overlay(
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        colors: [AppTheme.primary, AppTheme.secondary],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 3
                                )
                        )
                } else {
                    VStack(spacing: 15) {
                        Image(systemName: "person.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 70, height: 70)
                            .foregroundColor(AppTheme.textSecondary)
                        
                        Text("Tap to select photo")
                            .font(AppTheme.caption())
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    .frame(width: 200, height: 200)
                    .background(AppTheme.cardBackground.opacity(0.3))
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(
                                AppTheme.textSecondary.opacity(0.3), 
                                style: StrokeStyle(
                                    lineWidth: 1, 
                                    lineCap: .round, 
                                    lineJoin: .round, 
                                    dash: [5, 5], 
                                    dashPhase: 0
                                )
                            )
                    )
                }
            }
            
            PhotosPicker(selection: $viewModel.selectedPhotoItem, matching: .images) {
                HStack {
                    Image(systemName: "photo.fill")
                    Text(viewModel.selectedImage == nil ? "Select Photo" : "Change Photo")
                }
                .font(.system(.body, design: .rounded, weight: .semibold))
                .padding()
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(AppTheme.primary)
                        .shadow(color: AppTheme.primary.opacity(0.3), radius: 8, x: 0, y: 4)
                )
                .foregroundColor(AppTheme.textOnDark)
            }
            .buttonStyle(ScaleButtonStyle())
            .onChange(of: viewModel.selectedPhotoItem) { oldValue, newValue in
                viewModel.processSelectedPhoto()
            }
        }
    }
    
    private var reviewStep: some View {
        VStack(alignment: .leading, spacing: 25) {
            Text("Review Your Profile")
                .font(AppTheme.heading())
                .foregroundColor(AppTheme.textPrimary)
                .padding(.bottom, 5)
            
            HStack(alignment: .top, spacing: 20) {
                // Profile image
                if let selectedImage = viewModel.selectedImage {
                    Image(uiImage: selectedImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        colors: [AppTheme.primary, AppTheme.secondary],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 2
                                )
                        )
                        .shadow(color: AppTheme.primary.opacity(0.3), radius: 8)
                } else {
                    Image(systemName: "person.fill")
                        .font(.system(size: 40))
                        .foregroundColor(AppTheme.textSecondary)
                        .frame(width: 100, height: 100)
                        .background(AppTheme.cardBackground)
                        .clipShape(Circle())
                }
                
                // Basic info
                VStack(alignment: .leading, spacing: 8) {
                    Text(viewModel.username)
                        .font(AppTheme.subheading())
                        .foregroundColor(AppTheme.textPrimary)
                    
                    if !viewModel.age.isEmpty {
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundColor(AppTheme.primary)
                            Text("Age: \(viewModel.age)")
                                .font(AppTheme.body())
                                .foregroundColor(AppTheme.textSecondary)
                        }
                    }
                    
                    if !viewModel.occupation.isEmpty {
                        HStack {
                            Image(systemName: "briefcase.fill")
                                .foregroundColor(AppTheme.tertiary)
                            Text(viewModel.occupation)
                                .font(AppTheme.body())
                                .foregroundColor(AppTheme.textSecondary)
                        }
                    }
                    
                    if !viewModel.education.isEmpty {
                        HStack {
                            Image(systemName: "book.fill")
                                .foregroundColor(AppTheme.tertiary)
                            Text(viewModel.education)
                                .font(AppTheme.body())
                                .foregroundColor(AppTheme.textSecondary)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(AppTheme.cardBackground)
                    .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 3)
            )
            
            // Additional details
            VStack(alignment: .leading, spacing: 15) {
                if !viewModel.height.isEmpty {
                    HStack {
                        Image(systemName: "ruler")
                            .foregroundColor(AppTheme.tertiary)
                        Text("Height: \(viewModel.height) cm")
                            .font(AppTheme.body())
                            .foregroundColor(AppTheme.textSecondary)
                    }
                }
                
                if !viewModel.weight.isEmpty {
                    HStack {
                        Image(systemName: "scalemass")
                            .foregroundColor(AppTheme.tertiary)
                        Text("Weight: \(viewModel.weight) kg")
                            .font(AppTheme.body())
                            .foregroundColor(AppTheme.textSecondary)
                    }
                }
                
                HStack {
                    Image(systemName: viewModel.smoker ? "smoke.fill" : "smoke")
                        .foregroundColor(viewModel.smoker ? AppTheme.tertiary : AppTheme.textSecondary)
                    Text("Smoker: \(viewModel.smoker ? "Yes" : "No")")
                        .font(AppTheme.body())
                        .foregroundColor(AppTheme.textSecondary)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(AppTheme.cardBackground)
                    .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 3)
            )
            
            Text("This information will be used in the game for other players to guess about you.")
                .font(AppTheme.caption())
                .foregroundColor(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.top, 5)
        }
    }
}

// LottieView is now defined in Shared/LottieView.swift

#Preview {
    let authService = AuthenticationService() 
    return NavigationView {
        ProfileSetupView()
            .environmentObject(authService)
            .environmentObject(NavigationCoordinator(authService: authService))
    }
} 