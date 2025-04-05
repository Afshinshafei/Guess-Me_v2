import SwiftUI

// MARK: - Color Theme
struct AppTheme {
    // Primary color palette - fun and playful
    static let primary = Color("PrimaryColor") // Bright purple (#7B2CBF)
    static let secondary = Color("SecondaryColor") // Vibrant orange (#FF9F1C)
    static let tertiary = Color("TertiaryColor") // Teal (#2EC4B6)
    static let accent = Color("AccentColor") // Bright pink (#FF3366)
    
    // Background colors
    static let background = Color("BackgroundColor") // Off-white (#F9F9F9)
    static let cardBackground = Color("CardBackground") // White with slight tint (#FFFFFF)
    
    // Text colors
    static let textPrimary = Color("TextPrimary") // Dark gray (#333333)
    static let textSecondary = Color("TextSecondary") // Medium gray (#666666)
    static let textOnDark = Color("TextOnDark") // White (#FFFFFF)
    
    // Game-specific colors
    static let correct = Color("CorrectColor") // Green (#4CAF50)
    static let incorrect = Color("IncorrectColor") // Red (#F44336)
    static let lives = Color("LivesColor") // Heart red (#E91E63)
    static let error = Color("IncorrectColor") // Using incorrect color for error
    
    // MARK: - Font Styles
    static func title() -> Font {
        return Font.system(.largeTitle, design: .rounded, weight: .bold)
    }
    
    static func heading() -> Font {
        return Font.system(.title, design: .rounded, weight: .bold)
    }
    
    static func subheading() -> Font {
        return Font.system(.title3, design: .rounded, weight: .semibold)
    }
    
    static func body() -> Font {
        return Font.system(.body, design: .rounded)
    }
    
    static func caption() -> Font {
        return Font.system(.caption, design: .rounded, weight: .medium)
    }
    
    // MARK: - UI Elements
    struct ButtonStyle: SwiftUI.ButtonStyle {
        var backgroundColor: Color
        var foregroundColor: Color
        var isLarge: Bool = false
        var isDisabled: Bool = false
        
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .font(isLarge ? .system(.title3, design: .rounded, weight: .bold) : .system(.body, design: .rounded, weight: .semibold))
                .padding(.vertical, isLarge ? 16 : 12)
                .padding(.horizontal, isLarge ? 32 : 24)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isDisabled ? backgroundColor.opacity(0.5) : backgroundColor)
                        .shadow(color: backgroundColor.opacity(isDisabled ? 0.2 : 0.4), radius: 8, x: 0, y: 4)
                )
                .foregroundColor(foregroundColor)
                .scaleEffect(configuration.isPressed ? 0.96 : 1)
                .animation(.spring(response: 0.3), value: configuration.isPressed)
        }
    }
    
    struct CardStyle: ViewModifier {
        var cornerRadius: CGFloat = 24
        var shadowRadius: CGFloat = 10
        var shadowOpacity: Double = 0.05
        var padding: EdgeInsets = EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
        
        func body(content: Content) -> some View {
            content
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(AppTheme.cardBackground)
                        .shadow(color: Color.black.opacity(shadowOpacity), radius: shadowRadius, x: 0, y: 5)
                )
                .padding(padding)
        }
    }
    
    struct AnimatedGradientBackground: ViewModifier {
        @State private var animateGradient = false
        var duration: Double = 5
        var colors: [Color] = [
            AppTheme.primary.opacity(0.8),
            AppTheme.tertiary.opacity(0.6),
            AppTheme.secondary.opacity(0.7)
        ]
        
        func body(content: Content) -> some View {
            content
                .background(
                    LinearGradient(
                        colors: colors,
                        startPoint: animateGradient ? .topLeading : .bottomLeading,
                        endPoint: animateGradient ? .bottomTrailing : .topTrailing
                    )
                    .hueRotation(.degrees(animateGradient ? 45 : 0))
                    .ignoresSafeArea()
                    .onAppear {
                        withAnimation(.linear(duration: duration).repeatForever(autoreverses: true)) {
                            animateGradient.toggle()
                        }
                    }
                )
        }
    }
    
    struct TextFieldStyle: ViewModifier {
        var icon: String
        var iconColor: Color = AppTheme.primary
        
        func body(content: Content) -> some View {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                
                content
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(iconColor.opacity(0.3), lineWidth: 1)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(AppTheme.cardBackground)
                    )
            )
        }
    }
    
    struct ProfileImageStyle: ViewModifier {
        var size: CGFloat = 100
        var borderWidth: CGFloat = 3
        
        func body(content: Content) -> some View {
            content
                .frame(width: size, height: size)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [AppTheme.primary, AppTheme.secondary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: borderWidth
                        )
                )
                .shadow(color: AppTheme.primary.opacity(0.3), radius: 8)
        }
    }
    
    struct BadgeStyle: ViewModifier {
        var backgroundColor: Color = AppTheme.primary.opacity(0.15)
        
        func body(content: Content) -> some View {
            content
                .font(AppTheme.caption())
                .foregroundColor(AppTheme.textSecondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(backgroundColor)
                )
        }
    }
    
    struct FloatingCardStyle: ViewModifier {
        var cornerRadius: CGFloat = 25
        var shadowRadius: CGFloat = 20
        var shadowOpacity: Double = 0.1
        var shadowY: CGFloat = 10
        
        func body(content: Content) -> some View {
            content
                .clipShape(
                    RoundedRectangle(cornerRadius: cornerRadius)
                )
                .shadow(color: Color.black.opacity(shadowOpacity), radius: shadowRadius, y: shadowY)
                .padding(.horizontal, 20)
        }
    }
    
    struct RotatingCardStyle: ViewModifier {
        @State private var isRotated = false
        var rotationAmount: Double = 2
        var duration: Double = 3
        
        func body(content: Content) -> some View {
            content
                .rotation3DEffect(
                    .degrees(isRotated ? rotationAmount : -rotationAmount),
                    axis: (x: 0.0, y: 1.0, z: 0.0)
                )
                .onAppear {
                    withAnimation(.easeInOut(duration: duration).repeatForever(autoreverses: true)) {
                        isRotated.toggle()
                    }
                }
        }
    }
    
    struct ScaleButtonStyle: SwiftUI.ButtonStyle {
        var scale: CGFloat = 0.96
        var animationDuration: Double = 0.2
        
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .scaleEffect(configuration.isPressed ? scale : 1)
                .animation(.spring(response: animationDuration), value: configuration.isPressed)
        }
    }
    
    struct SuccessAnimationStyle: ViewModifier {
        @State private var isAnimating = false
        
        func body(content: Content) -> some View {
            content
                .scaleEffect(isAnimating ? 1.1 : 1.0)
                .opacity(isAnimating ? 1.0 : 0.8)
                .animation(
                    Animation.easeInOut(duration: 1.0)
                        .repeatForever(autoreverses: true),
                    value: isAnimating
                )
                .onAppear {
                    isAnimating = true
                }
        }
    }
}

// MARK: - View Extensions
extension View {
    // Button styles
    func primaryButtonStyle(isDisabled: Bool = false) -> some View {
        self.buttonStyle(AppTheme.ButtonStyle(backgroundColor: AppTheme.primary, foregroundColor: AppTheme.textOnDark, isDisabled: isDisabled))
    }
    
    func secondaryButtonStyle(isDisabled: Bool = false) -> some View {
        self.buttonStyle(AppTheme.ButtonStyle(backgroundColor: AppTheme.secondary, foregroundColor: AppTheme.textOnDark, isDisabled: isDisabled))
    }
    
    func tertiaryButtonStyle(isDisabled: Bool = false) -> some View {
        self.buttonStyle(AppTheme.ButtonStyle(backgroundColor: AppTheme.tertiary, foregroundColor: AppTheme.textOnDark, isDisabled: isDisabled))
    }
    
    func accentButtonStyle(isDisabled: Bool = false) -> some View {
        self.buttonStyle(AppTheme.ButtonStyle(backgroundColor: AppTheme.accent, foregroundColor: AppTheme.textOnDark, isDisabled: isDisabled))
    }
    
    func largeButtonStyle(isDisabled: Bool = false) -> some View {
        self.buttonStyle(AppTheme.ButtonStyle(backgroundColor: AppTheme.primary, foregroundColor: AppTheme.textOnDark, isLarge: true, isDisabled: isDisabled))
    }
    
    // Card styles
    func cardStyle(cornerRadius: CGFloat = 24, shadowRadius: CGFloat = 10, shadowOpacity: Double = 0.05) -> some View {
        self.modifier(AppTheme.CardStyle(cornerRadius: cornerRadius, shadowRadius: shadowRadius, shadowOpacity: shadowOpacity))
    }
    
    func floatingCardStyle(cornerRadius: CGFloat = 25, shadowRadius: CGFloat = 20, shadowOpacity: Double = 0.1, shadowY: CGFloat = 10) -> some View {
        self.modifier(AppTheme.FloatingCardStyle(cornerRadius: cornerRadius, shadowRadius: shadowRadius, shadowOpacity: shadowOpacity, shadowY: shadowY))
    }
    
    func rotatingCardStyle(rotationAmount: Double = 2, duration: Double = 3) -> some View {
        self.modifier(AppTheme.RotatingCardStyle(rotationAmount: rotationAmount, duration: duration))
    }
    
    // Background styles
    func gradientBackground(duration: Double = 5, colors: [Color]? = nil) -> some View {
        self.modifier(AppTheme.AnimatedGradientBackground(duration: duration, colors: colors ?? [
            AppTheme.primary.opacity(0.8),
            AppTheme.tertiary.opacity(0.6),
            AppTheme.secondary.opacity(0.7)
        ]))
    }
    
    // Form styles
    func textFieldStyle(icon: String, iconColor: Color = AppTheme.primary) -> some View {
        self.modifier(AppTheme.TextFieldStyle(icon: icon, iconColor: iconColor))
    }
    
    // Profile styles
    func profileImageStyle(size: CGFloat = 100, borderWidth: CGFloat = 3) -> some View {
        self.modifier(AppTheme.ProfileImageStyle(size: size, borderWidth: borderWidth))
    }
    
    // Badge styles
    func badgeStyle(backgroundColor: Color = AppTheme.primary.opacity(0.15)) -> some View {
        self.modifier(AppTheme.BadgeStyle(backgroundColor: backgroundColor))
    }
    
    // Animation styles
    func successAnimationStyle() -> some View {
        self.modifier(AppTheme.SuccessAnimationStyle())
    }
    
    // Button style
    func scaleButtonStyle(scale: CGFloat = 0.96, animationDuration: Double = 0.2) -> some View {
        self.buttonStyle(AppTheme.ScaleButtonStyle(scale: scale, animationDuration: animationDuration))
    }
}

// MARK: - Animation Extensions
extension Animation {
    static var springy: Animation {
        Animation.spring(response: 0.3, dampingFraction: 0.6, blendDuration: 0.5)
    }
    
    static var bouncy: Animation {
        Animation.spring(response: 0.5, dampingFraction: 0.5, blendDuration: 0.5)
    }
    
    static var gentle: Animation {
        Animation.easeInOut(duration: 0.4)
    }
}

// MARK: - Layout Extensions
extension View {
    func centerInParent() -> some View {
        self.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }
    
    func fillWidth() -> some View {
        self.frame(maxWidth: .infinity)
    }
    
    func fillHeight() -> some View {
        self.frame(maxHeight: .infinity)
    }
    
    func fillParent() -> some View {
        self.frame(maxWidth: .infinity, maxHeight: .infinity)
    }
} 