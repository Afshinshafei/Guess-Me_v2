import SwiftUI

/// DesignSystem provides documentation and examples for using the Guess Me app design system.
/// This file serves as a reference guide for developers to maintain consistent design across the app.
struct DesignSystem {
    
    // MARK: - Design Principles
    
    /// The Guess Me app follows these key design principles:
    /// 1. Playful and engaging - Using vibrant colors and animations to create a fun experience
    /// 2. Clear hierarchy - Important elements stand out through size, color, and positioning
    /// 3. Consistent styling - Reusing the same components and styles throughout the app
    /// 4. Responsive feedback - Animations and visual cues provide feedback for user actions
    /// 5. Accessibility - Ensuring text is readable and interactive elements are easily tappable
    
    // MARK: - Color Usage
    
    /// Primary color (purple) - Use for main actions, navigation, and key UI elements
    /// Example: Main buttons, navigation bars, and primary interactive elements
    static let primaryColorExample = Color("PrimaryColor")
    
    /// Secondary color (orange) - Use for secondary actions and highlights
    /// Example: Secondary buttons, highlights, and accent elements
    static let secondaryColorExample = Color("SecondaryColor")
    
    /// Tertiary color (teal) - Use for tertiary actions and subtle highlights
    /// Example: Tertiary buttons, subtle highlights, and supporting elements
    static let tertiaryColorExample = Color("TertiaryColor")
    
    /// Accent color (pink) - Use for special actions and attention-grabbing elements
    /// Example: Special buttons, notifications, and attention-grabbing elements
    static let accentColorExample = Color("AccentColor")
    
    // MARK: - Typography
    
    /// Title font - Use for main titles and large headings
    /// Example: App name, main section titles
    static let titleFontExample = AppTheme.title()
    
    /// Heading font - Use for section headings and important text
    /// Example: Section headings, important information
    static let headingFontExample = AppTheme.heading()
    
    /// Subheading font - Use for subsections and secondary headings
    /// Example: Subsection headings, secondary information
    static let subheadingFontExample = AppTheme.subheading()
    
    /// Body font - Use for main content and regular text
    /// Example: Paragraphs, descriptions, and regular content
    static let bodyFontExample = AppTheme.body()
    
    /// Caption font - Use for small text, labels, and supplementary information
    /// Example: Labels, captions, and supplementary information
    static let captionFontExample = AppTheme.caption()
    
    // MARK: - Component Examples
    
    /// Example of a primary button
    struct PrimaryButtonExample: View {
        var body: some View {
            Button("Primary Button") {}
                .primaryButtonStyle()
        }
    }
    
    /// Example of a secondary button
    struct SecondaryButtonExample: View {
        var body: some View {
            Button("Secondary Button") {}
                .secondaryButtonStyle()
        }
    }
    
    /// Example of a tertiary button
    struct TertiaryButtonExample: View {
        var body: some View {
            Button("Tertiary Button") {}
                .tertiaryButtonStyle()
        }
    }
    
    /// Example of an accent button
    struct AccentButtonExample: View {
        var body: some View {
            Button("Accent Button") {}
                .accentButtonStyle()
        }
    }
    
    /// Example of a large button
    struct LargeButtonExample: View {
        var body: some View {
            Button("Large Button") {}
                .largeButtonStyle()
        }
    }
    
    /// Example of a disabled button
    struct DisabledButtonExample: View {
        var body: some View {
            Button("Disabled Button") {}
                .primaryButtonStyle(isDisabled: true)
        }
    }
    
    /// Example of a card
    struct CardExample: View {
        var body: some View {
            VStack {
                Text("Card Content")
                    .font(AppTheme.body())
            }
            .cardStyle()
        }
    }
    
    /// Example of a floating card
    struct FloatingCardExample: View {
        var body: some View {
            VStack {
                Text("Floating Card Content")
                    .font(AppTheme.body())
            }
            .floatingCardStyle()
        }
    }
    
    /// Example of a rotating card
    struct RotatingCardExample: View {
        var body: some View {
            VStack {
                Text("Rotating Card Content")
                    .font(AppTheme.body())
            }
            .rotatingCardStyle()
        }
    }
    
    /// Example of a text field
    struct TextFieldExample: View {
        @State private var text = ""
        
        var body: some View {
            TextField("Enter text", text: $text)
                .textFieldStyle(icon: "person.fill")
        }
    }
    
    /// Example of a profile image
    struct ProfileImageExample: View {
        var body: some View {
            Image(systemName: "person.circle.fill")
                .font(.system(size: 50))
                .foregroundColor(AppTheme.secondary)
                .profileImageStyle()
        }
    }
    
    /// Example of a badge
    struct BadgeExample: View {
        var body: some View {
            Label("Badge", systemImage: "star.fill")
                .badgeStyle()
        }
    }
    
    /// Example of a success animation
    struct SuccessAnimationExample: View {
        var body: some View {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 50))
                .foregroundColor(AppTheme.correct)
                .successAnimationStyle()
        }
    }
    
    // MARK: - Layout Examples
    
    /// Example of a centered view
    struct CenteredViewExample: View {
        var body: some View {
            Text("Centered Content")
                .centerInParent()
        }
    }
    
    /// Example of a full-width view
    struct FullWidthViewExample: View {
        var body: some View {
            Text("Full Width Content")
                .fillWidth()
                .background(Color.gray.opacity(0.2))
        }
    }
    
    /// Example of a full-height view
    struct FullHeightViewExample: View {
        var body: some View {
            Text("Full Height Content")
                .fillHeight()
                .background(Color.gray.opacity(0.2))
        }
    }
    
    /// Example of a full-parent view
    struct FullParentViewExample: View {
        var body: some View {
            Text("Full Parent Content")
                .fillParent()
                .background(Color.gray.opacity(0.2))
        }
    }
    
    // MARK: - Animation Examples
    
    /// Example of a springy animation
    struct SpringyAnimationExample: View {
        @State private var isAnimating = false
        
        var body: some View {
            Button("Springy Animation") {
                withAnimation(.springy) {
                    isAnimating.toggle()
                }
            }
            .scaleEffect(isAnimating ? 1.2 : 1.0)
        }
    }
    
    /// Example of a bouncy animation
    struct BouncyAnimationExample: View {
        @State private var isAnimating = false
        
        var body: some View {
            Button("Bouncy Animation") {
                withAnimation(.bouncy) {
                    isAnimating.toggle()
                }
            }
            .scaleEffect(isAnimating ? 1.2 : 1.0)
        }
    }
    
    /// Example of a gentle animation
    struct GentleAnimationExample: View {
        @State private var isAnimating = false
        
        var body: some View {
            Button("Gentle Animation") {
                withAnimation(.gentle) {
                    isAnimating.toggle()
                }
            }
            .opacity(isAnimating ? 0.5 : 1.0)
        }
    }
    
    // MARK: - Best Practices
    
    /// Best practices for using the design system:
    /// 1. Always use the provided color constants instead of hardcoding colors
    /// 2. Use the provided font styles for consistent typography
    /// 3. Use the provided button styles for consistent button appearance
    /// 4. Use the provided card styles for consistent card appearance
    /// 5. Use the provided animation styles for consistent animations
    /// 6. Use the provided layout extensions for consistent layouts
    /// 7. Follow the design principles for consistent design
    /// 8. Test your UI on different device sizes and orientations
    /// 9. Ensure your UI is accessible to all users
    /// 10. Keep your UI simple and focused on the task at hand
    
    // MARK: - Responsive Design
    
    /// Guidelines for building responsive interfaces that scale well across devices:
    /// 1. Use relative sizing with GeometryReader for components that need to scale
    /// 2. Use dynamic type for text to respect user's accessibility settings
    /// 3. Use safe area insets to avoid overlapping with system UI elements
    /// 4. Use adaptive layouts that respond to available space
    /// 5. Test on smallest and largest supported devices
    /// 6. Consider orientation changes in your layout
    /// 7. Use ScrollView for content that might not fit on smaller screens
    /// 8. Avoid hard-coded dimensions that might cause layout issues
    /// 9. Use appropriate padding that scales well across devices
    /// 10. Consider adding device-specific adjustments for edge cases
}

// MARK: - Preview
struct DesignSystem_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Design System Examples")
                    .font(AppTheme.title())
                    .padding()
                
                Group {
                    Text("Button Examples")
                        .font(AppTheme.heading())
                    
                    HStack {
                        DesignSystem.PrimaryButtonExample()
                        DesignSystem.SecondaryButtonExample()
                    }
                    
                    HStack {
                        DesignSystem.TertiaryButtonExample()
                        DesignSystem.AccentButtonExample()
                    }
                    
                    HStack {
                        DesignSystem.LargeButtonExample()
                        DesignSystem.DisabledButtonExample()
                    }
                }
                .padding()
                .cardStyle()
                
                Group {
                    Text("Card Examples")
                        .font(AppTheme.heading())
                    
                    DesignSystem.CardExample()
                    DesignSystem.FloatingCardExample()
                    DesignSystem.RotatingCardExample()
                }
                .padding()
                .cardStyle()
                
                Group {
                    Text("Form Examples")
                        .font(AppTheme.heading())
                    
                    DesignSystem.TextFieldExample()
                }
                .padding()
                .cardStyle()
                
                Group {
                    Text("Profile Examples")
                        .font(AppTheme.heading())
                    
                    DesignSystem.ProfileImageExample()
                    DesignSystem.BadgeExample()
                }
                .padding()
                .cardStyle()
                
                Group {
                    Text("Animation Examples")
                        .font(AppTheme.heading())
                    
                    HStack {
                        DesignSystem.SpringyAnimationExample()
                        DesignSystem.BouncyAnimationExample()
                        DesignSystem.GentleAnimationExample()
                    }
                }
                .padding()
                .cardStyle()
            }
            .padding()
        }
        .background(AppTheme.background)
    }
} 