//
//  MainViewModel.swift
//  TrollToll
//
//  Created by Cagatay on 4.01.2026.
//

import SwiftUI

@Observable
class MainViewModel {
    let authenticator: Authenticator = FBAuthenticator()
    let userRepo: UserRepo = FBUserRepo()
    var user: User?
    var authState: AuthenticationState = .unauthenticated
    var errorMessage: String?

    func authenticate() async {
        authState = await authenticator.authenticate()
        if case .authenticated(let userId) = authState {
            await getUser(with: userId)
        }
    }

    func getUser(with id: String) async {
        do {
            user = try await userRepo.getUser(with: id)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func saveUser(with id: String, and name: String) async {
        do {
            user = try await userRepo.saveUser(with: id, and: name)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
