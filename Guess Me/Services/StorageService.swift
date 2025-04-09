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
                print("ERROR: StorageService - Service unavailable (self is nil)")
                promise(.failure(NSError(domain: "StorageService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Service unavailable"])))
                return
            }
            
            guard let imageData = image.jpegData(compressionQuality: 0.5) else {
                print("ERROR: StorageService - Could not convert image to JPEG data")
                promise(.failure(NSError(domain: "StorageService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not convert image to data"])))
                return
            }
            
            print("DEBUG: StorageService - Image converted to JPEG data, size: \(imageData.count) bytes")
            
            let metadata = StorageMetadata()
            metadata.contentType = "image/jpeg"
            
            let imagePath = "\(self.profileImagesPath)/\(userId)/profile.jpg"
            let imageRef = self.storage.child(imagePath)
            print("DEBUG: StorageService - Uploading to path: \(imagePath)")
            
            imageRef.putData(imageData, metadata: metadata) { metadata, error in
                if let error = error {
                    print("ERROR: StorageService - Failed to upload image: \(error.localizedDescription)")
                    promise(.failure(error))
                    return
                }
                
                print("DEBUG: StorageService - Image uploaded successfully, metadata: \(String(describing: metadata))")
                
                imageRef.downloadURL { url, error in
                    if let error = error {
                        print("ERROR: StorageService - Failed to get download URL: \(error.localizedDescription)")
                        promise(.failure(error))
                        return
                    }
                    
                    guard let downloadURL = url else {
                        print("ERROR: StorageService - Download URL is nil")
                        promise(.failure(NSError(domain: "StorageService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to get download URL"])))
                        return
                    }
                    
                    print("DEBUG: StorageService - Got download URL: \(downloadURL)")
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