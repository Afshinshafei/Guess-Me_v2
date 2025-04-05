import SwiftUI

/// A placeholder for an animation view that simulates the functionality of Lottie animations
/// In a real app, this would use the Lottie library to play animation files
struct LottieView: View {
    let name: String
    
    var body: some View {
        ZStack {
            // Loading animation
            if name == "loading_animation" {
                LoadingAnimationView()
            } else if name == "success_animation" || name == "correct_answer" {
                SuccessAnimationView()
            } else if name == "wrong_answer" {
                FailureAnimationView()
            } else {
                // Default placeholder
                PlaceholderAnimationView(name: name)
            }
        }
    }
}

/// Loading spinner animation
private struct LoadingAnimationView: View {
    @State private var animateSpinner = false
    
    var body: some View {
        ZStack {
            Circle()
                .trim(from: 0, to: 0.7)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [AppTheme.primary, AppTheme.secondary]),
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .frame(width: 80, height: 80)
                .rotationEffect(.degrees(animateSpinner ? 360 : 0))
                .animation(
                    Animation.linear(duration: 1)
                        .repeatForever(autoreverses: false),
                    value: animateSpinner
                )
                .onAppear {
                    animateSpinner = true
                }
            
            Circle()
                .fill(AppTheme.textOnDark.opacity(0.2))
                .frame(width: 20, height: 20)
        }
    }
}

/// Success animation view
private struct SuccessAnimationView: View {
    @State private var scale = 0.5
    @State private var opacity = 0.0
    
    var body: some View {
        ZStack {
            Circle()
                .fill(AppTheme.correct.opacity(0.2))
                .frame(width: 100, height: 100)
            
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 50))
                .foregroundColor(AppTheme.correct)
                .scaleEffect(scale)
                .opacity(opacity)
        }
        .onAppear {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                scale = 1.0
                opacity = 1.0
            }
        }
    }
}

/// Failure animation view
private struct FailureAnimationView: View {
    @State private var rotation = 0.0
    @State private var scale = 0.5
    @State private var opacity = 0.0
    
    var body: some View {
        ZStack {
            Circle()
                .fill(AppTheme.incorrect.opacity(0.2))
                .frame(width: 100, height: 100)
            
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 50))
                .foregroundColor(AppTheme.incorrect)
                .rotationEffect(.degrees(rotation))
                .scaleEffect(scale)
                .opacity(opacity)
        }
        .onAppear {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                rotation = 360
                scale = 1.0
                opacity = 1.0
            }
        }
    }
}

/// Generic placeholder for any other animation name
private struct PlaceholderAnimationView: View {
    let name: String
    
    var body: some View {
        ZStack {
            Circle()
                .fill(AppTheme.primary.opacity(0.2))
                .frame(width: 100, height: 100)
            
            Image(systemName: "questionmark.circle.fill")
                .font(.system(size: 50))
                .foregroundColor(AppTheme.primary)
            
            Text(name)
                .font(.caption)
                .foregroundColor(AppTheme.textSecondary)
                .position(x: 50, y: 120)
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        LottieView(name: "loading_animation")
            .frame(width: 120, height: 120)
        
        LottieView(name: "success_animation")
            .frame(width: 120, height: 120)
        
        LottieView(name: "wrong_answer")
            .frame(width: 120, height: 120)
        
        LottieView(name: "unknown_animation")
            .frame(width: 120, height: 120)
    }
    .padding()
    .background(AppTheme.background)
} 