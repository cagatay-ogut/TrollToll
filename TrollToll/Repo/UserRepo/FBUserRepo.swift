//
//  FBUserRepo.swift
//  TrollToll
//
//  Created by Cagatay on 1.01.2026.
//

import FirebaseDatabase
import OSLog

@Observable
class FBUserRepo: UserRepo {
    private let dbRef: DatabaseReference
    private let usersRef: DatabaseReference

    init() {
        dbRef = Database
            .database(url: "https://trolltoll-ee309-default-rtdb.europe-west1.firebasedatabase.app")
            .reference()
        usersRef = dbRef.child("users")
    }

    func getUser(with id: String) async throws -> User {
        let userRef = usersRef.child(id)

        let snapshot: DataSnapshot = try await withCheckedThrowingContinuation { continuation in
            userRef.observeSingleEvent(of: .value) { snapshot in
                continuation.resume(returning: snapshot)
            } withCancel: { error in
                continuation.resume(throwing: ServerError.serverCancel(underlyingError: error))
            }
        }

        return try FBDecoder.decode(User.self, from: snapshot)
    }

    func saveUser(with id: String, and name: String) async throws -> User {
        let userRef = usersRef.child(id)

        let user = User(id: id, name: name)
        let dictionary = try FBEncoder.encode(user)

        do {
            try await userRef.setValue(dictionary)
            Logger.multiplayer.debug("Saved user: \(id)")
            return user
        } catch {
            Logger.multiplayer.error("Could not save user: \(id), error: \(error)")
            throw ServerError.serverError(underlyingError: error)
        }
    }
}
