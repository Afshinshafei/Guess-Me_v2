import SwiftUI
import UIKit

struct ImageCropView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastScale: CGFloat = 1.0
    @State private var lastOffset: CGSize = .zero
    @State private var viewSize: CGSize = .zero
    @State private var imageSize: CGSize = .zero
    
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
                                // Initialize image size and scale appropriately
                                setupInitialImageSize()
                            }
                            .onChange(of: geometry.size) { _, newSize in
                                viewSize = newSize
                                // Reset position if the container size changes
                                setupInitialImageSize()
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
    
    private func setupInitialImageSize() {
        // Calculate the initial size based on fitting the image within the view
        let sourceSize = sourceImage.size
        
        if sourceSize.width > 0 && sourceSize.height > 0 {
            let aspectRatio = sourceSize.width / sourceSize.height
            
            if viewSize.width / viewSize.height > aspectRatio {
                imageSize = CGSize(
                    width: viewSize.height * aspectRatio,
                    height: viewSize.height
                )
            } else {
                imageSize = CGSize(
                    width: viewSize.width,
                    height: viewSize.width / aspectRatio
                )
            }
            
            // Reset transformations
            scale = 1.0
            lastScale = 1.0
            offset = .zero
            lastOffset = .zero
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
                                scale = min(max(newScale, 1.0), 5.0) // Limit scale between 1.0 and 5.0
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
    
    // Improved crop function that correctly handles the visible portion of the image
    private func cropImage() -> UIImage {
        let sourceSize = sourceImage.size
        
        // Calculate actual displayed dimensions of the image (before scaling)
        let displayedImageSize: CGSize
        if viewSize.width / viewSize.height > sourceSize.width / sourceSize.height {
            // Image height matches the container height
            displayedImageSize = CGSize(
                width: viewSize.height * (sourceSize.width / sourceSize.height),
                height: viewSize.height
            )
        } else {
            // Image width matches the container width
            displayedImageSize = CGSize(
                width: viewSize.width,
                height: viewSize.width * (sourceSize.height / sourceSize.width)
            )
        }
        
        // Calculate center position of the view
        let viewCenter = CGPoint(x: viewSize.width / 2, y: viewSize.height / 2)
        
        // Calculate visible region center (accounting for offset and scale)
        let visibleCenter = CGPoint(
            x: viewCenter.x - offset.width,
            y: viewCenter.y - offset.height
        )
        
        // Calculate the crop circle position relative to the image
        let cropCircleOnImage = CGPoint(
            x: (visibleCenter.x - viewCenter.x) / (displayedImageSize.width * scale) * sourceSize.width + sourceSize.width / 2,
            y: (visibleCenter.y - viewCenter.y) / (displayedImageSize.height * scale) * sourceSize.height + sourceSize.height / 2
        )
        
        // Calculate the size of the crop circle in the original image coordinates
        let cropSizeInImageCoordinates = cropSize / scale * (sourceSize.width / displayedImageSize.width)
        
        // Create the crop rectangle in the original image coordinates
        let cropRectInImage = CGRect(
            x: cropCircleOnImage.x - cropSizeInImageCoordinates / 2,
            y: cropCircleOnImage.y - cropSizeInImageCoordinates / 2,
            width: cropSizeInImageCoordinates,
            height: cropSizeInImageCoordinates
        )
        
        // Ensure the crop rectangle is within the image bounds
        let safeCropRect = CGRect(
            x: max(0, min(sourceSize.width - cropRectInImage.width, cropRectInImage.minX)),
            y: max(0, min(sourceSize.height - cropRectInImage.height, cropRectInImage.minY)),
            width: min(cropRectInImage.width, sourceSize.width),
            height: min(cropRectInImage.height, sourceSize.height)
        )
        
        // Create a circular cropped image
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: cropSize, height: cropSize))
        return renderer.image { context in
            // Create a circular clipping path
            let circlePath = UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: cropSize, height: cropSize))
            circlePath.addClip()
            
            // Calculate the drawing rectangle to position the source image correctly
            let drawRect = CGRect(
                x: -safeCropRect.minX * (cropSize / safeCropRect.width),
                y: -safeCropRect.minY * (cropSize / safeCropRect.height),
                width: sourceSize.width * (cropSize / safeCropRect.width),
                height: sourceSize.height * (cropSize / safeCropRect.height)
            )
            
            // Draw the image
            sourceImage.draw(in: drawRect)
        }
    }
}

#Preview {
    let sampleImage = UIImage(systemName: "person.fill")!.withTintColor(.blue, renderingMode: .alwaysOriginal)
    
    return ImageCropView(sourceImage: sampleImage) { _ in }
} 