//
//  ContentView.swift
//  Guess Me
//
//  Created by Afshin on 04/04/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.2.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(AppTheme.primary)
            
            Text("Guess Me")
                .font(AppTheme.title())
                .foregroundColor(AppTheme.textPrimary)
            
            Text("The social guessing game!")
                .font(AppTheme.subheading())
                .foregroundColor(AppTheme.textSecondary)
            
            Button("Start Playing") {
                // Action
            }
            .largeButtonStyle()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .gradientBackground()
    }
}

#Preview {
    ContentView()
}
