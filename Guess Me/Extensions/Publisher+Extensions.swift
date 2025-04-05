import Foundation
import Combine

extension Publisher {
    func `let`(_ transform: (AnyCancellable) -> Void) {
        transform(sink(receiveCompletion: { _ in }, receiveValue: { _ in }))
    }
} 