import SwiftUI
import UIKit

struct ImageCropView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastScale: CGFloat = 1.0
    @State private var lastOffset: CGSize = .zero
    @State private var viewSize: CGSize = .zero
    
    let sourceImage: UIImage
    let onCrop: (UIImage) -> Void
    
    // Size for the cropping circle
    let cropSize: CGFloat = 280
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Text("Position and Scale")
                        .font(AppTheme.heading())
                        .foregroundColor(.white)
                    
                    GeometryReader { geometry in
                        cropView
                            .onAppear {
                                viewSize = geometry.size
                            }
                            .onChange(of: geometry.size) { _, newSize in
                                viewSize = newSize
                            }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                    Text("Drag to position and pinch to zoom")
                        .font(AppTheme.caption())
                        .foregroundColor(.white.opacity(0.8))
                    
                    buttonRow
                }
                .padding()
            }
            .navigationBarHidden(true)
        }
    }
    
    private var cropView: some View {
        ZStack {
            // The image that can be moved and scaled
            Image(uiImage: sourceImage)
                .resizable()
                .scaledToFit()
                .scaleEffect(scale)
                .offset(offset)
                .gesture(
                    // Combine drag and pinch gestures
                    SimultaneousGesture(
                        DragGesture()
                            .onChanged { value in
                                offset = CGSize(
                                    width: lastOffset.width + value.translation.width,
                                    height: lastOffset.height + value.translation.height
                                )
                            }
                            .onEnded { value in
                                lastOffset = offset
                            },
                        MagnificationGesture()
                            .onChanged { value in
                                let newScale = lastScale * value
                                scale = min(max(newScale, 1.0), 3.0) // Limit scale between 1.0 and 3.0
                            }
                            .onEnded { value in
                                lastScale = scale
                            }
                    )
                )
            
            // Fixed dark overlay
            ZStack {
                Rectangle()
                    .fill(Color.black.opacity(0.7))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // Transparent circle in the middle
                Circle()
                    .frame(width: cropSize, height: cropSize)
                    .blendMode(.destinationOut)
            }
            .allowsHitTesting(false) // Allow interactions to pass through to the image underneath
            .compositingGroup()
            
            // Circle border
            Circle()
                .stroke(AppTheme.primary, lineWidth: 3)
                .frame(width: cropSize, height: cropSize)
                .allowsHitTesting(false) // Allow interactions to pass through
        }
    }
    
    private var buttonRow: some View {
        HStack(spacing: 20) {
            Button("Cancel") {
                dismiss()
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.2))
            )
            .foregroundColor(.white)
            
            Button("Choose") {
                let croppedImage = cropImage()
                onCrop(croppedImage)
                dismiss()
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppTheme.secondary)
            )
            .foregroundColor(.white)
        }
        .padding(.horizontal)
    }
    
    // Crop the image based on the current view state
    private func cropImage() -> UIImage {
        print("DEBUG: ImageCropView - Starting image crop")
        
        // Calculate visible region of the image
        let imageSize = sourceImage.size
        let aspectRatio = imageSize.width / imageSize.height
        
        print("DEBUG: ImageCropView - Source image size: \(imageSize), aspectRatio: \(aspectRatio)")
        print("DEBUG: ImageCropView - View size: \(viewSize), scale: \(scale), offset: \(offset)")
        
        // Calculate the size of the displayed image before scaling
        var displayWidth: CGFloat = 0
        var displayHeight: CGFloat = 0
        
        if viewSize.width / viewSize.height > aspectRatio {
            // Image fits height
            displayHeight = viewSize.height
            displayWidth = displayHeight * aspectRatio
        } else {
            // Image fits width
            displayWidth = viewSize.width
            displayHeight = displayWidth / aspectRatio
        }
        
        // Calculate the center of the image in the view
        let imageCenter = CGPoint(
            x: viewSize.width / 2 + offset.width,
            y: viewSize.height / 2 + offset.height
        )
        
        // Calculate the crop region in the original image coordinates
        let scaledCropSize = cropSize / scale
        
        // Convert to pixel coordinates in the original image
        let sourceRect = CGRect(
            x: imageSize.width/2 - (viewSize.width/2 - imageCenter.x + cropSize/2) * imageSize.width / (displayWidth * scale),
            y: imageSize.height/2 - (viewSize.height/2 - imageCenter.y + cropSize/2) * imageSize.height / (displayHeight * scale),
            width: scaledCropSize * imageSize.width / displayWidth,
            height: scaledCropSize * imageSize.height / displayHeight
        )
        
        // Ensure the crop region is within the image bounds
        let safeCropRect = CGRect(
            x: max(0, min(imageSize.width - sourceRect.width, sourceRect.minX)),
            y: max(0, min(imageSize.height - sourceRect.height, sourceRect.minY)),
            width: min(sourceRect.width, imageSize.width),
            height: min(sourceRect.height, imageSize.height)
        )
        
        print("DEBUG: ImageCropView - Calculated crop rect: \(safeCropRect)")
        
        // Create the cropped image
        if let cgImage = sourceImage.cgImage?.cropping(to: safeCropRect) {
            let croppedImage = UIImage(cgImage: cgImage, scale: sourceImage.scale, orientation: sourceImage.imageOrientation)
            print("DEBUG: ImageCropView - Successfully cropped image with CGImage.cropping")
            return croppedImage
        }
        
        print("DEBUG: ImageCropView - Falling back to renderer-based cropping")
        
        // Fallback if cropping fails
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: cropSize, height: cropSize))
        let croppedImage = renderer.image { context in
            // Draw a circle to create the circular crop
            let path = UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: cropSize, height: cropSize))
            path.addClip()
            
            // Calculate the correct position to draw the image
            let drawRect = CGRect(
                x: -safeCropRect.minX * displayWidth / imageSize.width * scale,
                y: -safeCropRect.minY * displayHeight / imageSize.height * scale,
                width: displayWidth * scale,
                height: displayHeight * scale
            )
            
            sourceImage.draw(in: drawRect)
        }
        
        print("DEBUG: ImageCropView - Created circular cropped image with renderer")
        return croppedImage
    }
}

#Preview {
    let sampleImage = UIImage(systemName: "person.fill")!.withTintColor(.blue, renderingMode: .alwaysOriginal)
    
    return ImageCropView(sourceImage: sampleImage) { _ in }
} 