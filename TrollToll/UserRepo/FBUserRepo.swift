//
//  FBUserRepo.swift
//  TrollToll
//
//  Created by Cagatay on 1.01.2026.
//

import FirebaseDatabase

@Observable
class FBUserRepo: UserRepo {
    private let dbRef: DatabaseReference
    private let usersRef: DatabaseReference
    var user: User?

    init() {
        dbRef = Database
            .database(url: "https://trolltoll-ee309-default-rtdb.europe-west1.firebasedatabase.app")
            .reference()
        usersRef = dbRef.child("users")
    }

    func getUser(with id: String) async throws {
        let userRef = usersRef.child(id)

        let snapshot: DataSnapshot = try await withCheckedThrowingContinuation { continuation in
            userRef.observeSingleEvent(of: .value) { snapshot in
                if snapshot.exists() {
                    continuation.resume(returning: snapshot)
                } else {
                    continuation.resume(throwing: FirebaseUserError.noUserDataFound(userID: id))
                }
            } withCancel: { error in
                continuation.resume(throwing: FirebaseUserError.firebaseDatabaseError(underlyingError: error))
            }
        }

        guard let value = snapshot.value,
              let jsonData = try? JSONSerialization.data(withJSONObject: value, options: []) else {
            throw FirebaseUserError.dataSerializationFailed
        }

        let decoder = JSONDecoder()
        do {
            user = try decoder.decode(User.self, from: jsonData)
        } catch {
            throw FirebaseUserError.dataDecodingFailed(underlyingError: error)
        }
    }

    func saveUser(with id: String, and name: String) async throws {
        let userRef = usersRef.child(id)
        let user = User(id: id, name: name)
        var userDataDictionary: [String: Any]

        do {
            let encoder = JSONEncoder()
            let jsonData = try encoder.encode(user)
            guard let dictionary = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
                throw FirebaseUserError.dataEncodingFailed(
                    underlyingError: NSError(
                        domain: "Conversion",
                        code: 0,
                        userInfo: [NSLocalizedDescriptionKey: "Failed to convert encoded JSON data to dictionary."]
                    )
                )
            }
            userDataDictionary = dictionary
        } catch {
            throw FirebaseUserError.dataEncodingFailed(underlyingError: error)
        }

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            userRef.setValue(userDataDictionary) { error, _ in
                if let error {
                    continuation.resume(throwing: FirebaseUserError.firebaseDatabaseError(underlyingError: error))
                } else {
                    self.user = user
                    continuation.resume(returning: ())
                }
            }
        }
    }
}

enum FirebaseUserError: LocalizedError {
    case noUserSignedIn
    case noUserDataFound(userID: String)
    case dataSerializationFailed
    case dataDecodingFailed(underlyingError: Error)
    case dataEncodingFailed(underlyingError: Error)
    case firebaseDatabaseError(underlyingError: Error)

    var errorDescription: String? {
        switch self {
        case .noUserSignedIn:
            return "No user is currently signed in to Firebase."
        case .noUserDataFound(let userID):
            return "No user data found in the database for ID: \(userID)."
        case .dataSerializationFailed:
            return "Failed to convert Firebase snapshot data into JSON format."
        case .dataDecodingFailed(let underlyingError):
            return "Failed to decode user data from JSON: \(underlyingError.localizedDescription)"
        case .dataEncodingFailed(let underlyingError):
            return "Failed to encode user data to JSON: \(underlyingError.localizedDescription)"
        case .firebaseDatabaseError(let underlyingError):
            return "Firebase Realtime Database error: \(underlyingError.localizedDescription)"
        }
    }
}
