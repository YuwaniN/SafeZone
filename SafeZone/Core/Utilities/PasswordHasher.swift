import CryptoKit
import Foundation
import Security

enum PasswordHasher {
    private static let iterations = 10_000

    static func makeSalt() -> String {
        var bytes = [UInt8](repeating: 0, count: 16)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return Data(bytes).base64EncodedString()
    }

    static func hash(password: String, salt: String) -> String {
        var digest = Data((salt + password).utf8)
        for _ in 0..<iterations {
            digest = Data(SHA256.hash(data: digest))
        }
        return digest.base64EncodedString()
    }

    static func verify(password: String, salt: String, expectedHash: String) -> Bool {
        hash(password: password, salt: salt) == expectedHash
    }
}
