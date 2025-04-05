# Guess Me App

A fun and engaging social guessing game where players try to guess information about other users.

## Design System

The Guess Me app uses a comprehensive design system to ensure a consistent, playful, and engaging user experience across all screens. This document provides guidelines for using the design system effectively.

### Core Design Principles

1. **Playful and Engaging**: The app uses vibrant colors and animations to create a fun experience.
2. **Clear Hierarchy**: Important elements stand out through size, color, and positioning.
3. **Consistent Styling**: The same components and styles are reused throughout the app.
4. **Responsive Feedback**: Animations and visual cues provide feedback for user actions.
5. **Accessibility**: Text is readable and interactive elements are easily tappable.

### Color Palette

The app uses a vibrant, playful color palette:

- **Primary (Purple)**: Used for main actions, navigation, and key UI elements.
- **Secondary (Orange)**: Used for secondary actions and highlights.
- **Tertiary (Teal)**: Used for tertiary actions and subtle highlights.
- **Accent (Pink)**: Used for special actions and attention-grabbing elements.

### Typography

The app uses a consistent typography system with rounded fonts for a friendly feel:

- **Title**: Used for main titles and large headings.
- **Heading**: Used for section headings and important text.
- **Subheading**: Used for subsections and secondary headings.
- **Body**: Used for main content and regular text.
- **Caption**: Used for small text, labels, and supplementary information.

### UI Components

The design system includes a variety of UI components that can be easily reused:

#### Buttons

```swift
// Primary button
Button("Primary Button") {}
    .primaryButtonStyle()

// Secondary button
Button("Secondary Button") {}
    .secondaryButtonStyle()

// Tertiary button
Button("Tertiary Button") {}
    .tertiaryButtonStyle()

// Accent button
Button("Accent Button") {}
    .accentButtonStyle()

// Large button
Button("Large Button") {}
    .largeButtonStyle()

// Disabled button
Button("Disabled Button") {}
    .primaryButtonStyle(isDisabled: true)
```

#### Cards

```swift
// Standard card
VStack {
    Text("Card Content")
        .font(AppTheme.body())
}
.cardStyle()

// Floating card
VStack {
    Text("Floating Card Content")
        .font(AppTheme.body())
}
.floatingCardStyle()

// Rotating card
VStack {
    Text("Rotating Card Content")
        .font(AppTheme.body())
}
.rotatingCardStyle()
```

#### Form Elements

```swift
// Text field with icon
TextField("Enter text", text: $text)
    .textFieldStyle(icon: "person.fill")
```

#### Profile Elements

```swift
// Profile image
Image(systemName: "person.circle.fill")
    .font(.system(size: 50))
    .foregroundColor(AppTheme.secondary)
    .profileImageStyle()

// Badge
Label("Badge", systemImage: "star.fill")
    .badgeStyle()
```

### Animations

The design system includes a variety of animations that can be used to enhance the user experience:

```swift
// Springy animation
withAnimation(.springy) {
    // Animation code
}

// Bouncy animation
withAnimation(.bouncy) {
    // Animation code
}

// Gentle animation
withAnimation(.gentle) {
    // Animation code
}
```

### Layout

The design system includes a variety of layout extensions that can be used to create consistent layouts:

```swift
// Centered view
Text("Centered Content")
    .centerInParent()

// Full-width view
Text("Full Width Content")
    .fillWidth()

// Full-height view
Text("Full Height Content")
    .fillHeight()

// Full-parent view
Text("Full Parent Content")
    .fillParent()
```

### Backgrounds

The design system includes a variety of background styles that can be used to create consistent backgrounds:

```swift
// Gradient background
VStack {
    // Content
}
.gradientBackground()

// Custom gradient background
VStack {
    // Content
}
.gradientBackground(
    duration: 10,
    colors: [
        AppTheme.primary.opacity(0.8),
        AppTheme.accent.opacity(0.6)
    ]
)
```

## Best Practices

1. **Always use the provided color constants** instead of hardcoding colors.
2. **Use the provided font styles** for consistent typography.
3. **Use the provided button styles** for consistent button appearance.
4. **Use the provided card styles** for consistent card appearance.
5. **Use the provided animation styles** for consistent animations.
6. **Use the provided layout extensions** for consistent layouts.
7. **Follow the design principles** for consistent design.
8. **Test your UI on different device sizes and orientations**.
9. **Ensure your UI is accessible to all users**.
10. **Keep your UI simple and focused on the task at hand**.

## Design System Reference

For a comprehensive reference of all available design system components, see the `DesignSystem.swift` file. This file includes examples of all available components and can be used as a reference when implementing new screens.

## Apple Design Guidelines

The Guess Me app follows Apple's Human Interface Guidelines for iOS, with a focus on:

- **Clarity**: Text is legible, icons are precise, and adornments are subtle.
- **Deference**: Content fills the screen, and translucent UI elements blur the content behind them.
- **Depth**: Visual layers and realistic motion convey hierarchy, impart vitality, and facilitate understanding.

For more information, see the [Apple Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/). 