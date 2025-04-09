import SwiftUI
import PhotosUI
import Combine
import FirebaseAuth
import GoogleMobileAds

@MainActor
class ProfileViewModel: ObservableObject, Sendable {
    @Published var isEditing = false
    @Published var showImagePicker = false
    @Published var selectedPhotoItem: PhotosPickerItem?
    @Published var selectedImage: UIImage?
    @Published var isLoading = false
    @Published var showSuccessToast = false
    @Published var errorMessage: String?
    @Published var showError = false
    
    // Form fields
    @Published var username = ""
    @Published var age: String = ""
    @Published var occupation = ""
    @Published var education = ""
    @Published var height: String = ""
    @Published var weight: String = ""
    @Published var smoker = false
    
    nonisolated let authService: AuthenticationService
    private var cancellables = Set<AnyCancellable>()
    
    init(authService: AuthenticationService) {
        self.authService = authService
    }
    
    func loadUserData() {
        guard let user = authService.user else { 
            print("Cannot load user data - no user available")
            return 
        }
        
        print("Loading user data for: \(user.username)")
        username = user.username
        age = user.age != nil ? "\(user.age!)" : ""
        occupation = user.occupation ?? ""
        education = user.education ?? ""
        height = user.height != nil ? "\(Int(user.height!))" : ""
        weight = user.weight != nil ? "\(Int(user.weight!))" : ""
        smoker = user.smoker ?? false
    }
    
    func saveProfile() {
        guard var user = authService.user else { 
            errorMessage = "Cannot save profile - no user available"
            showError = true
            return 
        }
        
        print("Saving profile for user: \(user.username)")
        isLoading = true
        
        // Update user data
        user.username = username
        user.age = Int(age)
        user.occupation = occupation.isEmpty ? nil : occupation
        user.education = education.isEmpty ? nil : education
        user.height = Double(height)
        user.weight = Double(weight)
        user.smoker = smoker
        
        var publisher: AnyPublisher<Void, Error> = Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
        
        // Upload image if selected
        if let selectedImage = selectedImage, let userId = user.id {
            print("Uploading profile image for user: \(userId)")
            publisher = StorageService.shared.uploadProfileImage(selectedImage, userId: userId)
                .flatMap { url -> AnyPublisher<Void, Error> in
                    print("Image uploaded successfully, URL: \(url)")
                    user.profileImageURL = url.absoluteString
                    return UserService.shared.updateUser(user)
                }
                .eraseToAnyPublisher()
        } else {
            print("No image selected, just updating user data")
            publisher = UserService.shared.updateUser(user)
        }
        
        publisher
            .receive(on: DispatchQueue.main)
            .sink { completion in
                self.isLoading = false
                
                if case .failure(let error) = completion {
                    print("Error saving profile: \(error)")
                    self.errorMessage = "Failed to save: \(error.localizedDescription)"
                    self.showError = true
                } else {
                    // Success
                    print("Profile saved successfully")
                    self.showSuccessToast = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        self.showSuccessToast = false
                    }
                    self.isEditing = false
                }
            } receiveValue: { _ in
                // Refresh user data
                if let userId = user.id {
                    print("Refreshing user data after save")
                    UserService.shared.fetchUser(withUID: userId)
                        .receive(on: DispatchQueue.main)
                        .sink(receiveCompletion: { completion in
                            if case .failure(let error) = completion {
                                print("Error refreshing user data: \(error)")
                                self.errorMessage = "Failed to refresh data: \(error.localizedDescription)"
                                self.showError = true
                            }
                        }, receiveValue: { user in
                            print("User data refreshed: \(user.username)")
                            self.authService.user = user
                        })
                        .store(in: &self.cancellables)
                }
            }
            .store(in: &cancellables)
    }
    
    func signOut() {
        print("DEBUG: Starting sign out process")
        isLoading = true
        
        // We'll use the NavigationCoordinator for sign out instead
        // This method is kept for backward compatibility
        authService.signOut()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                guard let self = self else { return }
                self.isLoading = false
                if case .failure(let error) = completion {
                    print("ERROR: Sign out failed: \(error)")
                    self.errorMessage = "Failed to sign out: \(error.localizedDescription)"
                    self.showError = true
                    NotificationCenter.default.post(name: NSNotification.Name("SignOutComplete"), object: nil)
                } else {
                    // Successfully signed out
                    print("DEBUG: Sign out successful")
                    NotificationCenter.default.post(name: NSNotification.Name("SignOutComplete"), object: nil)
                }
            } receiveValue: { _ in
                // Successfully signed out - the auth state change will handle navigation
                print("DEBUG: Sign out received success value")
            }
            .store(in: &cancellables)
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
}

struct ProfileView: View {
    @EnvironmentObject var authService: AuthenticationService
    @EnvironmentObject var gameManager: GameManager
    @State private var isEditing = false
    @State private var showingImagePicker = false
    @State private var showingLogoutAlert = false
    @State private var editedUsername = ""
    @State private var selectedImage: UIImage?
    @State private var isLoading = false
    @State private var isShowingAchievements = false
    @State private var animateBackground = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var showAllAchievements = false
    @State private var showingEditProfile = false
    
    private var earnedCount: Int {
        authService.user?.achievements.count ?? 0
    }
    
    private var totalCount: Int {
        Achievement.allAchievements.count
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Animated gradient background (consistent with AuthView)
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
                    VStack(spacing: 25) {
                        profileHeader
                        achievementsPreview
                        userInfoCard
                        settingsSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 15)
                }
                .navigationTitle("Profile")
                .navigationBarTitleDisplayMode(.large)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            showingEditProfile = true
                        }) {
                            Text("Edit Profile")
                                .font(AppTheme.body())
                                .foregroundColor(AppTheme.primary)
                        }
                    }
                }
                
                // Loading overlay
                if isLoading {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                        .overlay(
                            VStack(spacing: 16) {
                                ProgressView()
                                    .scaleEffect(1.5)
                                    .tint(AppTheme.primary)
                                
                                Text("Updating Profile...")
                                    .font(AppTheme.body())
                                    .foregroundColor(.white)
                            }
                        )
                }
            }
            .sheet(isPresented: $showingImagePicker) {
                PhotosPicker("Select Photo", selection: $selectedPhotoItem, matching: .images)
                    .onChange(of: selectedPhotoItem) { oldValue, newValue in
                        if let newValue {
                            Task {
                                if let data = try? await newValue.loadTransferable(type: Data.self),
                                   let image = UIImage(data: data) {
                                    DispatchQueue.main.async {
                                        self.selectedImage = image
                                    }
                                }
                            }
                        }
                    }
            }
            .sheet(isPresented: $isShowingAchievements) {
                AchievementsView()
            }
            .sheet(isPresented: $showingEditProfile) {
                ProfileEditView()
                    .environmentObject(authService)
            }
            .alert(isPresented: $showingLogoutAlert) {
                Alert(
                    title: Text("Logout"),
                    message: Text("Are you sure you want to logout?"),
                    primaryButton: .destructive(Text("Logout")) {
                        _ = authService.signOut()
                    },
                    secondaryButton: .cancel()
                )
            }
        }
    }
    
    private var profileHeader: some View {
        VStack(spacing: 20) {
            // Profile image with edit button
            ZStack(alignment: .bottomTrailing) {
                if let profileImageURL = authService.user?.profileImageURL, !profileImageURL.isEmpty {
                    AsyncImage(url: URL(string: profileImageURL)) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .profileImageStyle(size: 160)
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .profileImageStyle(size: 160, borderWidth: 4)
                        case .failure:
                            Image(systemName: "person.fill")
                                .font(.system(size: 80))
                                .foregroundColor(AppTheme.textSecondary)
                                .profileImageStyle(size: 160)
                        @unknown default:
                            EmptyView()
                        }
                    }
                } else {
                    Image(systemName: "person.fill")
                        .font(.system(size: 80))
                        .foregroundColor(AppTheme.textSecondary)
                        .profileImageStyle(size: 160)
                }
                
                Button(action: {
                    showingImagePicker = true
                }) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(AppTheme.primary)
                                .shadow(color: AppTheme.primary.opacity(0.3), radius: 4, x: 0, y: 2)
                        )
                }
                .buttonStyle(ScaleButtonStyle())
            }
            .padding(.bottom, 8)
            
            // Username display (removed edit functionality)
            Text(authService.user?.username ?? "User")
                .font(AppTheme.heading())
                .foregroundColor(AppTheme.textPrimary)
            
            // User email
            Text(authService.user?.email ?? "")
                .font(AppTheme.body())
                .foregroundColor(AppTheme.textSecondary)
        }
        .padding(25)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(AppTheme.cardBackground)
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
        )
        .floatingCardStyle()
    }
    
    private var achievementsPreview: some View {
        VStack(alignment: .leading, spacing: 15) {
            // Header row
            HStack {
                Text("Awards")
                    .font(AppTheme.subheading())
                    .foregroundColor(AppTheme.textPrimary)
                
                Spacer()
                
                Button(action: {
                    isShowingAchievements = true
                }) {
                    Text("See All")
                        .font(AppTheme.caption())
                        .foregroundColor(AppTheme.primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(AppTheme.primary.opacity(0.1))
                        )
                }
                .buttonStyle(ScaleButtonStyle())
            }
            
            // Awards summary
            HStack(spacing: 20) {
                // Progress circle
                ZStack {
                    Circle()
                        .stroke(AppTheme.textSecondary.opacity(0.2), lineWidth: 10)
                        .frame(width: 80, height: 80)
                    
                    Circle()
                        .trim(from: 0, to: earnedCount == 0 ? 0.001 : CGFloat(earnedCount) / CGFloat(totalCount))
                        .stroke(
                            LinearGradient(
                                colors: [AppTheme.primary, AppTheme.secondary],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            style: StrokeStyle(lineWidth: 10, lineCap: .round)
                        )
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(-90))
                    
                    VStack(spacing: 2) {
                        Text("\(earnedCount)")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(AppTheme.primary)
                        
                        Text("of \(totalCount)")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(AppTheme.textSecondary)
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Awards Earned")
                        .font(AppTheme.body())
                        .foregroundColor(AppTheme.textPrimary)
                    
                    Text("Complete challenges to earn more awards")
                        .font(AppTheme.caption())
                        .foregroundColor(AppTheme.textSecondary)
                        .lineLimit(2)
                    
                    Button(action: {
                        isShowingAchievements = true
                    }) {
                        Text("View All Awards")
                            .font(AppTheme.caption())
                            .foregroundColor(AppTheme.primary)
                            .padding(.vertical, 6)
                            .padding(.horizontal, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(AppTheme.primary.opacity(0.1))
                            )
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
            .padding(.vertical, 10)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(AppTheme.cardBackground)
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
        )
    }
    
    private var userInfoCard: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Your Information")
                .font(AppTheme.subheading())
                .foregroundColor(AppTheme.textPrimary)
            
            VStack(spacing: 16) {
                if let user = authService.user {
                    // Basic Info
                    InfoRow(
                        label: "Username",
                        value: user.username,
                        icon: "person.fill",
                        color: AppTheme.primary
                    )
                    
                    if let age = user.age {
                        InfoRow(
                            label: "Age",
                            value: "\(age)",
                            icon: "calendar",
                            color: AppTheme.primary
                        )
                    }
                    
                    if let occupation = user.occupation, !occupation.isEmpty {
                        InfoRow(
                            label: "Occupation",
                            value: occupation,
                            icon: "briefcase.fill",
                            color: AppTheme.tertiary
                        )
                    }
                    
                    if let education = user.education, !education.isEmpty {
                        InfoRow(
                            label: "Education",
                            value: education,
                            icon: "book.fill",
                            color: AppTheme.tertiary
                        )
                    }
                    
                    if let height = user.height {
                        InfoRow(
                            label: "Height",
                            value: "\(Int(height)) cm",
                            icon: "ruler",
                            color: AppTheme.tertiary
                        )
                    }
                    
                    if let weight = user.weight {
                        InfoRow(
                            label: "Weight",
                            value: "\(Int(weight)) kg",
                            icon: "scalemass",
                            color: AppTheme.tertiary
                        )
                    }
                    
                    InfoRow(
                        label: "Smoker",
                        value: user.smoker ?? false ? "Yes" : "No",
                        icon: user.smoker ?? false ? "smoke.fill" : "smoke",
                        color: AppTheme.tertiary
                    )
                    
                    Divider()
                        .padding(.vertical, 5)
                    
                    // Preferences
                    Text("Your Preferences")
                        .font(AppTheme.body())
                        .foregroundColor(AppTheme.textPrimary)
                        .padding(.top, 5)
                    
                    if let favoriteColor = user.favoriteColor, !favoriteColor.isEmpty {
                        InfoRow(
                            label: "Favorite Color",
                            value: favoriteColor,
                            icon: "paintpalette.fill",
                            color: Color.purple
                        )
                    }
                    
                    if let favoriteMovie = user.favoriteMovie, !favoriteMovie.isEmpty {
                        InfoRow(
                            label: "Favorite Movie",
                            value: favoriteMovie,
                            icon: "film.fill",
                            color: Color.indigo
                        )
                    }
                    
                    if let favoriteFood = user.favoriteFood, !favoriteFood.isEmpty {
                        InfoRow(
                            label: "Favorite Food",
                            value: favoriteFood,
                            icon: "fork.knife",
                            color: Color.orange
                        )
                    }
                    
                    if let favoriteFlower = user.favoriteFlower, !favoriteFlower.isEmpty {
                        InfoRow(
                            label: "Favorite Flower",
                            value: favoriteFlower,
                            icon: "leaf.fill",
                            color: Color.pink
                        )
                    }
                    
                    if let favoriteSport = user.favoriteSport, !favoriteSport.isEmpty {
                        InfoRow(
                            label: "Favorite Sport",
                            value: favoriteSport,
                            icon: "sportscourt.fill",
                            color: Color.green
                        )
                    }
                    
                    if let favoriteHobby = user.favoriteHobby, !favoriteHobby.isEmpty {
                        InfoRow(
                            label: "Favorite Hobby",
                            value: favoriteHobby,
                            icon: "heart.fill",
                            color: Color.red
                        )
                    }
                } else {
                    Text("No user information available")
                        .font(AppTheme.body())
                        .foregroundColor(AppTheme.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                }
            }
            .padding(.vertical, 8)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(AppTheme.cardBackground)
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
        )
    }
    
    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Settings")
                .font(AppTheme.subheading())
                .foregroundColor(AppTheme.textPrimary)
            
            VStack(spacing: 5) {
                SettingsRow(
                    icon: "bell.fill",
                    iconColor: AppTheme.tertiary,
                    title: "Notifications",
                    action: {
                        // Open notifications settings
                    }
                )
                
                SettingsRow(
                    icon: "lock.fill",
                    iconColor: AppTheme.secondary,
                    title: "Privacy",
                    action: {
                        // Open privacy settings
                    }
                )
                
                SettingsRow(
                    icon: "questionmark.circle.fill",
                    iconColor: AppTheme.primary,
                    title: "Help & Support",
                    action: {
                        // Open help
                    }
                )
                
                SettingsRow(
                    icon: "arrow.right.square.fill",
                    iconColor: Color.red,
                    title: "Logout",
                    action: {
                        showingLogoutAlert = true
                    }
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(AppTheme.cardBackground)
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
        )
    }
    
    private func calculateAccuracyString() -> String {
        guard let user = authService.user else { return "0%" }
        guard user.totalGuesses > 0 else { return "0%" }
        
        let accuracy = Double(user.correctGuesses) / Double(user.totalGuesses) * 100
        return String(format: "%.1f%%", accuracy)
    }
    
    private func uploadProfileImage(_ image: UIImage) {
        isLoading = true
        
        // In a real app, this would call the appropriate service to upload the image
        // For now, simulate a delay and success
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isLoading = false
            // In a real implementation, you'd update the user profile with the new image URL
        }
    }
}

struct StatItem: View {
    let label: String
    let value: String
    let icon: String
    let color: Color
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
                .scaleEffect(isAnimating ? 1.2 : 1.0)
                .animation(
                    Animation.spring(response: 0.5, dampingFraction: 0.6)
                        .repeatCount(1),
                    value: isAnimating
                )
            
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(AppTheme.textPrimary)
            
            Text(label)
                .font(AppTheme.caption())
                .foregroundColor(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(AppTheme.cardBackground)
                .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 2)
        )
        .onAppear {
            // Add a slight delay before animating
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isAnimating = true
            }
        }
    }
}

struct StatRow: View {
    let label: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(color)
                .frame(width: 36, height: 36)
                .background(
                    Circle()
                        .fill(color.opacity(0.15))
                )
            
            Text(label)
                .font(AppTheme.body())
                .foregroundColor(AppTheme.textPrimary)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(AppTheme.textPrimary)
        }
    }
}

struct AchievementPreviewItem: View {
    let title: String
    let icon: String
    let color: Color
    let isLocked: Bool
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundColor(isLocked ? color : color)
                .frame(width: 60, height: 60)
                .background(
                    Circle()
                        .fill(color.opacity(isLocked ? 0.1 : 0.2))
                )
                .scaleEffect(isAnimating ? 1.1 : 1.0)
                .animation(
                    Animation.spring(response: 0.5, dampingFraction: 0.6)
                        .repeatCount(1),
                    value: isAnimating
                )
                .overlay(
                    isLocked ?
                    Circle()
                        .stroke(color.opacity(0.3), lineWidth: 2)
                        .blur(radius: 1)
                    : nil
                )
            
            Text(title)
                .font(AppTheme.caption())
                .foregroundColor(isLocked ? AppTheme.textSecondary.opacity(0.7) : AppTheme.textPrimary)
                .multilineTextAlignment(.center)
                .frame(width: 80)
                .lineLimit(2)
        }
        .frame(width: 100, height: 120)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isLocked ? AppTheme.cardBackground.opacity(0.5) : AppTheme.cardBackground)
                .shadow(color: Color.black.opacity(isLocked ? 0.02 : 0.05), radius: 5, x: 0, y: 3)
        )
        .overlay(
            isLocked ?
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppTheme.textSecondary.opacity(0.2), lineWidth: 1)
            : nil
        )
        .onAppear {
            if !isLocked {
                // Add a slight delay before animating
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    isAnimating = true
                }
            }
        }
    }
}

struct SettingsRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(iconColor)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(iconColor.opacity(0.15))
                    )
                
                Text(title)
                    .font(AppTheme.body())
                    .foregroundColor(AppTheme.textPrimary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppTheme.textSecondary)
            }
            .padding(.vertical, 12)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthenticationService())
        .environmentObject(GameManager())
}

// Helper for photo picker
extension Binding {
    func onChange(_ handler: @escaping (Value) -> Void) -> Binding<Value> {
        Binding(
            get: { self.wrappedValue },
            set: { newValue in
                self.wrappedValue = newValue
                handler(newValue)
            }
        )
    }
}

// New ProfileEditView for editing profile information
struct ProfileEditView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authService: AuthenticationService
    @StateObject private var viewModel: ProfileSetupViewModel
    @State private var animateBackground = false
    
    init() {
        // Initialize with the current auth service
        _viewModel = StateObject(wrappedValue: ProfileSetupViewModel(authService: AuthenticationService()))
    }
    
    var body: some View {
        NavigationView {
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
                
                ScrollView {
                    VStack(spacing: 25) {
                        // Header
                        VStack(spacing: 8) {
                            Text("Edit Your Profile")
                                .font(AppTheme.title())
                                .foregroundColor(AppTheme.textOnDark)
                                .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)
                            
                            Text("Update your information")
                                .font(AppTheme.body())
                                .foregroundColor(AppTheme.textOnDark.opacity(0.9))
                                .padding(.bottom, 5)
                        }
                        .padding(.top, 10)
                        
                        // Content container
                        VStack(spacing: 25) {
                            // Basic info section
                            basicInfoSection
                            
                            // Details section
                            detailsSection
                            
                            // Preferences section
                            preferencesSection
                            
                            // Save button
                            Button(action: {
                                Task {
                                    await saveProfile()
                                }
                            }) {
                                Text("Save Changes")
                                    .font(.system(.body, design: .rounded, weight: .bold))
                                    .foregroundColor(AppTheme.textOnDark)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(AppTheme.secondary)
                                            .shadow(color: AppTheme.secondary.opacity(0.3), radius: 8, x: 0, y: 4)
                                    )
                            }
                            .buttonStyle(ScaleButtonStyle())
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
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                // Replace the viewModel with one that uses the environment object
                viewModel.authService = authService
                viewModel.loadUserDataFromService()
            }
            .onReceive(authService.$user) { user in
                // Update if user changes
                if user != nil {
                    viewModel.loadUserDataFromService()
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
    }
    
    private var basicInfoSection: some View {
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
    
    private var detailsSection: some View {
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
        }
    }
    
    private var preferencesSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Your Preferences")
                .font(AppTheme.heading())
                .foregroundColor(AppTheme.textPrimary)
                .padding(.bottom, 5)
            
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
    }
    
    private func saveProfile() async {
        do {
            // Call the viewModel's saveProfile method
            try await viewModel.saveProfile()
            dismiss()
        } catch {
            print("Error saving profile: \(error)")
            viewModel.errorMessage = "Failed to save profile: \(error.localizedDescription)"
            viewModel.showError = true
        }
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(color)
                .frame(width: 36, height: 36)
                .background(
                    Circle()
                        .fill(color.opacity(0.15))
                )
            
            Text(label)
                .font(AppTheme.body())
                .foregroundColor(AppTheme.textPrimary)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(AppTheme.textPrimary)
        }
    }
} 