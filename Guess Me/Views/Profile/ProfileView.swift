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
                        statsCard
                        achievementsPreview
                        settingsSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 15)
                }
                .navigationTitle("Profile")
                .navigationBarTitleDisplayMode(.large)
                
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
                                .profileImageStyle(size: 120)
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .profileImageStyle(size: 120, borderWidth: 4)
                        case .failure:
                            Image(systemName: "person.fill")
                                .font(.system(size: 60))
                                .foregroundColor(AppTheme.textSecondary)
                                .profileImageStyle(size: 120)
                        @unknown default:
                            EmptyView()
                        }
                    }
                } else {
                    Image(systemName: "person.fill")
                        .font(.system(size: 60))
                        .foregroundColor(AppTheme.textSecondary)
                        .profileImageStyle(size: 120)
                }
                
                Button(action: {
                    showingImagePicker = true
                }) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 36, height: 36)
                        .background(
                            Circle()
                                .fill(AppTheme.primary)
                                .shadow(color: AppTheme.primary.opacity(0.3), radius: 4, x: 0, y: 2)
                        )
                }
                .buttonStyle(ScaleButtonStyle())
            }
            .padding(.bottom, 8)
            
            // Username with edit option
            if isEditing {
                HStack {
                    TextField("Username", text: $editedUsername)
                        .font(AppTheme.heading())
                        .foregroundColor(AppTheme.textPrimary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(AppTheme.cardBackground)
                                .shadow(color: Color.black.opacity(0.05), radius: 2)
                        )
                    
                    Button(action: {
                        // Update username locally instead of using the service
                        isLoading = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            // In a real app, this would call your auth service
                            isLoading = false
                            isEditing = false
                        }
                    }) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                            .background(
                                Circle()
                                    .fill(AppTheme.correct)
                                    .shadow(color: AppTheme.correct.opacity(0.3), radius: 3)
                            )
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .disabled(editedUsername.isEmpty || editedUsername == authService.user?.username)
                }
            } else {
                HStack {
                    Text(authService.user?.username ?? "User")
                        .font(AppTheme.heading())
                        .foregroundColor(AppTheme.textPrimary)
                    
                    Button(action: {
                        editedUsername = authService.user?.username ?? ""
                        isEditing = true
                    }) {
                        Image(systemName: "pencil")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(AppTheme.textSecondary)
                            .frame(width: 26, height: 26)
                            .background(
                                Circle()
                                    .fill(AppTheme.textSecondary.opacity(0.15))
                            )
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
            
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
    
    private var statsCard: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Game Stats")
                .font(AppTheme.subheading())
                .foregroundColor(AppTheme.textPrimary)
            
            HStack(spacing: 12) {
                StatItem(
                    label: "Score",
                    value: "\(authService.user?.score ?? 0)",
                    icon: "trophy.fill",
                    color: AppTheme.secondary
                )
                
                StatItem(
                    label: "Streak",
                    value: "\(authService.user?.highestStreak ?? 0)",
                    icon: "flame.fill",
                    color: AppTheme.accent
                )
                
                StatItem(
                    label: "Accuracy",
                    value: calculateAccuracyString(),
                    icon: "target",
                    color: AppTheme.tertiary
                )
            }
            
            Divider()
                .padding(.vertical, 5)
            
            // Game stats
            VStack(spacing: 16) {
                StatRow(
                    label: "Correct Guesses",
                    value: "\(authService.user?.correctGuesses ?? 0)",
                    icon: "checkmark.circle.fill",
                    color: AppTheme.correct
                )
                
                StatRow(
                    label: "Total Guesses",
                    value: "\(authService.user?.totalGuesses ?? 0)",
                    icon: "number.circle",
                    color: AppTheme.primary
                )
                
                StatRow(
                    label: "Games Played",
                    value: "\(authService.user?.totalGuesses ?? 0 / 5)", // Approximate games played as total guesses divided by 5
                    icon: "gamecontroller.fill",
                    color: AppTheme.secondary
                )
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
    
    private var achievementsPreview: some View {
        VStack(alignment: .leading, spacing: 15) {
            // Header row
            HStack {
                Text("Achievements")
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
            
            // Achievement items
            ScrollView(.horizontal, showsIndicators: false) {
                achievementItems
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(AppTheme.cardBackground)
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
        )
    }
    
    // Break out the achievement items to reduce complexity
    private var achievementItems: some View {
        HStack(spacing: 16) {
            // Show last 3 earned achievements or placeholders if none
            let achievements = Array(authService.user?.achievements ?? [])
            
            if achievements.isEmpty {
                ForEach(0..<3, id: \.self) { _ in
                    AchievementPreviewItem(
                        title: "Locked",
                        icon: "lock.fill",
                        color: AppTheme.textSecondary.opacity(0.3),
                        isLocked: true
                    )
                }
            } else {
                // Only show up to 3 achievements
                let displayAchievements = Array(achievements.prefix(3))
                ForEach(Array(displayAchievements.enumerated()), id: \.offset) { index, achievementId in
                    if let achievement = Achievement.allAchievements.first(where: { $0.id == achievementId }) {
                        AchievementPreviewItem(
                            title: achievement.name,
                            icon: achievement.imageName,
                            color: getColorForAchievement(type: achievement.type),
                            isLocked: false
                        )
                    }
                }
            }
        }
        .padding(.vertical, 10)
    }
    
    private func getColorForAchievement(type: Achievement.AchievementType) -> Color {
        switch type {
        case .correctGuesses:
            return AppTheme.correct
        case .streak:
            return AppTheme.accent
        case .totalGuesses:
            return AppTheme.primary
        }
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