import SwiftUI
import PhotosUI
import Combine

@MainActor
final class ProfileSetupViewModel: ObservableObject, Sendable {
    @Published var username = ""
    @Published var age: String = ""
    @Published var occupation = ""
    @Published var selectedEducationIndex = 0
    @Published var selectedHeightIndex = 0
    @Published var selectedWeightIndex = 0
    @Published var smoker = false
    @Published var favoriteColor = ""
    @Published var favoriteMovie = ""
    @Published var favoriteFood = ""
    @Published var favoriteFlower = ""
    @Published var favoriteSport = ""
    @Published var favoriteHobby = ""
    @Published var selectedPhotoItem: PhotosPickerItem?
    @Published var selectedImage: UIImage?
    @Published var originalImage: UIImage?
    @Published var showImageCropView = false
    @Published var isLoading = false
    @Published var loadingMessage = "Saving your profile..."
    @Published var currentStep = 0
    @Published var setupComplete = false
    @Published var errorMessage: String?
    @Published var showError = false
    
    // Picker options
    let educationLevels = [
        "High School",
        "Some College",
        "Associate's Degree",
        "Bachelor's Degree",
        "Master's Degree",
        "Doctorate",
        "Trade School",
        "Other"
    ]
    
    let heightOptions: [Int] = {
        var heights: [Int] = []
        for height in 140...220 {
            heights.append(height)
        }
        return heights
    }()
    
    let weightOptions: [Int] = {
        var weights: [Int] = []
        for weight in 40...150 {
            weights.append(weight)
        }
        return weights
    }()
    
    var authService: AuthenticationService
    private var cancellables = Set<AnyCancellable>()
    
    init(authService: AuthenticationService) {
        self.authService = authService
        loadUserDataFromService()
    }
    
    func loadUserDataFromService() {
        if let user = authService.user {
            username = user.username
            if let age = user.age {
                self.age = "\(age)"
            }
            occupation = user.occupation ?? ""
            
            // Set education index
            if let education = user.education,
               let index = educationLevels.firstIndex(of: education) {
                selectedEducationIndex = index
            }
            
            // Set height index
            if let height = user.height,
               let index = heightOptions.firstIndex(of: Int(height)) {
                selectedHeightIndex = index
            }
            
            // Set weight index
            if let weight = user.weight,
               let index = weightOptions.firstIndex(of: Int(weight)) {
                selectedWeightIndex = index
            }
            
            smoker = user.smoker ?? false
            favoriteColor = user.favoriteColor ?? ""
            favoriteMovie = user.favoriteMovie ?? ""
            favoriteFood = user.favoriteFood ?? ""
            favoriteFlower = user.favoriteFlower ?? ""
            favoriteSport = user.favoriteSport ?? ""
            favoriteHobby = user.favoriteHobby ?? ""
        }
    }
    
    func processSelectedPhoto() {
        Task {
            if let selectedPhotoItem = selectedPhotoItem,
               let data = try? await selectedPhotoItem.loadTransferable(type: Data.self),
               let uiImage = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.originalImage = uiImage
                    self.showImageCropView = true
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
            return true // No need to validate height and weight as they're always valid with pickers
        case 2: // Photo
            return selectedImage != nil
        case 3: // Review
            return true
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
            Task {
                do {
                    try await saveProfile()
                } catch {
                    print("Error saving profile: \(error)")
                    errorMessage = "Failed to save profile: \(error.localizedDescription)"
                    showError = true
                }
            }
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
            message = "Please select valid height and weight"
        case 2:
            message = "Please select a profile photo"
        default:
            message = "Please complete all required fields"
        }
        
        errorMessage = message
        showError = true
    }
    
    func saveProfile() async throws {
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
        user.education = educationLevels[selectedEducationIndex]
        user.height = Double(heightOptions[selectedHeightIndex])
        user.weight = Double(weightOptions[selectedWeightIndex])
        user.smoker = smoker
        user.favoriteColor = favoriteColor.isEmpty ? nil : favoriteColor
        user.favoriteMovie = favoriteMovie.isEmpty ? nil : favoriteMovie
        user.favoriteFood = favoriteFood.isEmpty ? nil : favoriteFood
        user.favoriteFlower = favoriteFlower.isEmpty ? nil : favoriteFlower
        user.favoriteSport = favoriteSport.isEmpty ? nil : favoriteSport
        user.favoriteHobby = favoriteHobby.isEmpty ? nil : favoriteHobby
        
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
    
    // Sheet presentation state
    enum SheetType: Identifiable {
        case imageCrop
        
        var id: Int {
            switch self {
            case .imageCrop: return 0
            }
        }
    }
    
    @State private var activeSheet: SheetType?
    
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
                                Text("Welcome to MugMatch!")
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
            if newValue != nil {
                viewModel.processSelectedPhoto()
            }
        }
        .onChange(of: viewModel.showImageCropView) { oldValue, newValue in
            if newValue {
                activeSheet = .imageCrop
                viewModel.showImageCropView = false  // Reset the flag
            }
        }
        .sheet(item: $activeSheet) { sheetType in
            switch sheetType {
            case .imageCrop:
                if let originalImage = viewModel.originalImage {
                    ImageCropView(sourceImage: originalImage) { croppedImage in
                        viewModel.selectedImage = croppedImage
                        activeSheet = nil
                    }
                }
            }
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
            
            ScrollView {
                VStack(spacing: 20) {
                    // Basic Details Section
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
                        
                        Menu {
                            ForEach(0..<viewModel.educationLevels.count, id: \.self) { index in
                                Button(action: {
                                    withAnimation(.springy) {
                                        viewModel.selectedEducationIndex = index
                                    }
                                }) {
                                    HStack {
                                        Text(viewModel.educationLevels[index])
                                            .foregroundColor(AppTheme.textPrimary)
                                        
                                        if index == viewModel.selectedEducationIndex {
                                            Image(systemName: "checkmark")
                                                .foregroundColor(AppTheme.tertiary)
                                        }
                                    }
                                }
                            }
                        } label: {
                            HStack {
                                Image(systemName: "book.fill")
                                    .foregroundColor(AppTheme.tertiary)
                                
                                Text(viewModel.educationLevels[viewModel.selectedEducationIndex])
                                    .foregroundColor(AppTheme.textPrimary)
                                    .font(AppTheme.body())
                                
                                Spacer()
                                
                                Image(systemName: "chevron.down")
                                    .foregroundColor(AppTheme.tertiary)
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(AppTheme.cardBackground)
                                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(AppTheme.tertiary.opacity(0.3), lineWidth: 1)
                            )
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Height (cm)")
                            .font(AppTheme.caption())
                            .foregroundColor(AppTheme.textSecondary)
                        
                        Menu {
                            ForEach(0..<viewModel.heightOptions.count, id: \.self) { index in
                                Button(action: {
                                    withAnimation(.springy) {
                                        viewModel.selectedHeightIndex = index
                                    }
                                }) {
                                    HStack {
                                        Text("\(viewModel.heightOptions[index]) cm")
                                            .foregroundColor(AppTheme.textPrimary)
                                        
                                        if index == viewModel.selectedHeightIndex {
                                            Image(systemName: "checkmark")
                                                .foregroundColor(AppTheme.tertiary)
                                        }
                                    }
                                }
                            }
                        } label: {
                            HStack {
                                Image(systemName: "ruler")
                                    .foregroundColor(AppTheme.tertiary)
                                
                                Text("\(viewModel.heightOptions[viewModel.selectedHeightIndex]) cm")
                                    .foregroundColor(AppTheme.textPrimary)
                                    .font(AppTheme.body())
                                
                                Spacer()
                                
                                Image(systemName: "chevron.down")
                                    .foregroundColor(AppTheme.tertiary)
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(AppTheme.cardBackground)
                                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(AppTheme.tertiary.opacity(0.3), lineWidth: 1)
                            )
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Weight (kg)")
                            .font(AppTheme.caption())
                            .foregroundColor(AppTheme.textSecondary)
                        
                        Menu {
                            ForEach(0..<viewModel.weightOptions.count, id: \.self) { index in
                                Button(action: {
                                    withAnimation(.springy) {
                                        viewModel.selectedWeightIndex = index
                                    }
                                }) {
                                    HStack {
                                        Text("\(viewModel.weightOptions[index]) kg")
                                            .foregroundColor(AppTheme.textPrimary)
                                        
                                        if index == viewModel.selectedWeightIndex {
                                            Image(systemName: "checkmark")
                                                .foregroundColor(AppTheme.tertiary)
                                        }
                                    }
                                }
                            }
                        } label: {
                            HStack {
                                Image(systemName: "scalemass")
                                    .foregroundColor(AppTheme.tertiary)
                                
                                Text("\(viewModel.weightOptions[viewModel.selectedWeightIndex]) kg")
                                    .foregroundColor(AppTheme.textPrimary)
                                    .font(AppTheme.body())
                                
                                Spacer()
                                
                                Image(systemName: "chevron.down")
                                    .foregroundColor(AppTheme.tertiary)
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(AppTheme.cardBackground)
                                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(AppTheme.tertiary.opacity(0.3), lineWidth: 1)
                            )
                        }
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
                        RoundedRectangle(cornerRadius: 16)
                            .fill(AppTheme.cardBackground)
                            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(AppTheme.tertiary.opacity(0.3), lineWidth: 1)
                    )
                    
                    // Preferences Section
                    Text("Your Preferences")
                        .font(AppTheme.subheading())
                        .foregroundColor(AppTheme.textPrimary)
                        .padding(.top, 10)
                    
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Favorite Color")
                            .font(AppTheme.caption())
                            .foregroundColor(AppTheme.textSecondary)
                        
                        TextField("Favorite Color", text: $viewModel.favoriteColor)
                            .textFieldStyle(icon: "paintpalette.fill", iconColor: Color.purple)
                    }
                    
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Favorite Movie")
                            .font(AppTheme.caption())
                            .foregroundColor(AppTheme.textSecondary)
                        
                        TextField("Favorite Movie", text: $viewModel.favoriteMovie)
                            .textFieldStyle(icon: "film.fill", iconColor: Color.indigo)
                    }
                    
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Favorite Food")
                            .font(AppTheme.caption())
                            .foregroundColor(AppTheme.textSecondary)
                        
                        TextField("Favorite Food", text: $viewModel.favoriteFood)
                            .textFieldStyle(icon: "fork.knife", iconColor: Color.orange)
                    }
                    
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Favorite Flower")
                            .font(AppTheme.caption())
                            .foregroundColor(AppTheme.textSecondary)
                        
                        TextField("Favorite Flower", text: $viewModel.favoriteFlower)
                            .textFieldStyle(icon: "leaf.fill", iconColor: Color.pink)
                    }
                    
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Favorite Sport")
                            .font(AppTheme.caption())
                            .foregroundColor(AppTheme.textSecondary)
                        
                        TextField("Favorite Sport", text: $viewModel.favoriteSport)
                            .textFieldStyle(icon: "sportscourt.fill", iconColor: Color.green)
                    }
                    
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Favorite Hobby")
                            .font(AppTheme.caption())
                            .foregroundColor(AppTheme.textSecondary)
                        
                        TextField("Favorite Hobby", text: $viewModel.favoriteHobby)
                            .textFieldStyle(icon: "heart.fill", iconColor: Color.red)
                    }
                }
                .padding(.bottom, 20)
            }
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
                    
                    if !viewModel.educationLevels[viewModel.selectedEducationIndex].isEmpty {
                        HStack {
                            Image(systemName: "book.fill")
                                .foregroundColor(AppTheme.tertiary)
                            Text(viewModel.educationLevels[viewModel.selectedEducationIndex])
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
                if viewModel.selectedHeightIndex < viewModel.heightOptions.count {
                    HStack {
                        Image(systemName: "ruler")
                            .foregroundColor(AppTheme.tertiary)
                        Text("Height: \(viewModel.heightOptions[viewModel.selectedHeightIndex]) cm")
                            .font(AppTheme.body())
                            .foregroundColor(AppTheme.textSecondary)
                    }
                }
                
                if viewModel.selectedWeightIndex < viewModel.weightOptions.count {
                    HStack {
                        Image(systemName: "scalemass")
                            .foregroundColor(AppTheme.tertiary)
                        Text("Weight: \(viewModel.weightOptions[viewModel.selectedWeightIndex]) kg")
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
            
            // Preferences section
            VStack(alignment: .leading, spacing: 15) {
                Text("Your Preferences")
                    .font(AppTheme.subheading())
                    .foregroundColor(AppTheme.textPrimary)
                    .padding(.bottom, 5)
                
                if !viewModel.favoriteColor.isEmpty {
                    HStack {
                        Image(systemName: "paintpalette.fill")
                            .foregroundColor(Color.purple)
                        Text("Favorite Color: \(viewModel.favoriteColor)")
                            .font(AppTheme.body())
                            .foregroundColor(AppTheme.textSecondary)
                    }
                }
                
                if !viewModel.favoriteMovie.isEmpty {
                    HStack {
                        Image(systemName: "film.fill")
                            .foregroundColor(Color.indigo)
                        Text("Favorite Movie: \(viewModel.favoriteMovie)")
                            .font(AppTheme.body())
                            .foregroundColor(AppTheme.textSecondary)
                    }
                }
                
                if !viewModel.favoriteFood.isEmpty {
                    HStack {
                        Image(systemName: "fork.knife")
                            .foregroundColor(Color.orange)
                        Text("Favorite Food: \(viewModel.favoriteFood)")
                            .font(AppTheme.body())
                            .foregroundColor(AppTheme.textSecondary)
                    }
                }
                
                if !viewModel.favoriteFlower.isEmpty {
                    HStack {
                        Image(systemName: "leaf.fill")
                            .foregroundColor(Color.pink)
                        Text("Favorite Flower: \(viewModel.favoriteFlower)")
                            .font(AppTheme.body())
                            .foregroundColor(AppTheme.textSecondary)
                    }
                }
                
                if !viewModel.favoriteSport.isEmpty {
                    HStack {
                        Image(systemName: "sportscourt.fill")
                            .foregroundColor(Color.green)
                        Text("Favorite Sport: \(viewModel.favoriteSport)")
                            .font(AppTheme.body())
                            .foregroundColor(AppTheme.textSecondary)
                    }
                }
                
                if !viewModel.favoriteHobby.isEmpty {
                    HStack {
                        Image(systemName: "heart.fill")
                            .foregroundColor(Color.red)
                        Text("Favorite Hobby: \(viewModel.favoriteHobby)")
                            .font(AppTheme.body())
                            .foregroundColor(AppTheme.textSecondary)
                    }
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
