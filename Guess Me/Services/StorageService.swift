import Foundation
import FirebaseStorage
import UIKit
import Combine

class StorageService {
    static let shared = StorageService()
    
    private let storage = Storage.storage().reference()
    private let profileImagesPath = "profileImages"
    
    private init() {}
    
    func uploadProfileImage(_ image: UIImage, userId: String) -> AnyPublisher<URL, Error> {
        return Future<URL, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "StorageService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Service unavailable"])))
                return
            }
            
            guard let imageData = image.jpegData(compressionQuality: 0.5) else {
                promise(.failure(NSError(domain: "StorageService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not convert image to data"])))
                return
            }
            
            let metadata = StorageMetadata()
            metadata.contentType = "image/jpeg"
            
            let imageRef = self.storage.child(self.profileImagesPath).child(userId).child("profile.jpg")
            
            imageRef.putData(imageData, metadata: metadata) { _, error in
                if let error = error {
                    promise(.failure(error))
                    return
                }
                
                imageRef.downloadURL { url, error in
                    if let error = error {
                        promise(.failure(error))
                        return
                    }
                    
                    guard let downloadURL = url else {
                        promise(.failure(NSError(domain: "StorageService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to get download URL"])))
                        return
                    }
                    
                    promise(.success(downloadURL))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func getProfileImageURL(userId: String) -> AnyPublisher<URL, Error> {
        return Future<URL, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "StorageService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Service unavailable"])))
                return
            }
            
            let imageRef = self.storage.child(self.profileImagesPath).child(userId).child("profile.jpg")
            
            imageRef.downloadURL { url, error in
                if let error = error {
                    promise(.failure(error))
                    return
                }
                
                guard let downloadURL = url else {
                    promise(.failure(NSError(domain: "StorageService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to get download URL"])))
                    return
                }
                
                promise(.success(downloadURL))
            }
        }
        .eraseToAnyPublisher()
    }
} 