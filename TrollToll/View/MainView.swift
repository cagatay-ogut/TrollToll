//
//  MainView.swift
//  TrollToll
//
//  Created by Cagatay on 30.12.2025.
//

import SwiftUI

struct MainView: View {
    @State private var router = Router()
    @State private var authenticator: Authenticator = FBAuthenticator()
    @State private var userRepo: UserRepo = FBUserRepo()
    @State private var showUserNameField = false

    var body: some View {
        NavigationStack(path: $router.navPath) {
            VStack(spacing: 32) {
                switch authenticator.authState {
                case .unauthenticated:
                    ProgressView()
                case .authenticated(let userId):
                    AuthenticatedView(userRepo: $userRepo, router: router, userId: userId)
                case .failed:
                    FailedAuthView(authenticator: authenticator)
                }
            }
            .buttonStyle(.borderedProminent)
            .navigationDestination(for: Router.Destination.self) { destination in
                switch destination {
                case let .lobby(user):
                    LobbyView(user: user)
                case let .game(user, match):
                    GameView(user: user, match: match)
                }
            }
        }
        .task {
            await authenticator.authenticate()
            if case .authenticated(let userId) = authenticator.authState {
                do {
                    try await userRepo.getUser(with: userId)
                } catch {
                    print("error: \(error)")
                }
            }
        }
        .environment(router)
    }
}

private struct FailedAuthView: View {
    let authenticator: Authenticator

    var body: some View {
        Button {
            Task {
                await authenticator.authenticate()
            }
        } label: {
            Text("retryAuth")
        }
    }
}

private struct AuthenticatedView: View {
    @Binding var userRepo: UserRepo
    let router: Router
    let userId: String

    var body: some View {
        if userRepo.user == nil {
            UserNameField(userRepo: userRepo, userId: userId)
        }
        Button {
            userRepo.user?.isHost = true
            router.navigate(to: .lobby(user: userRepo.user!))
        } label: {
            Text("hostGame")
                .padding(4)
        }
        .disabled(userRepo.user == nil)
        Button {
            userRepo.user?.isHost = false
            router.navigate(to: .lobby(user: userRepo.user!))
        } label: {
            Text("joinGame")
                .padding(4)
        }
        .disabled(userRepo.user == nil)
    }
}

private struct UserNameField: View {
    @State private var name: String = ""
    let userRepo: UserRepo
    let userId: String

    var body: some View {
        VStack {
            TextField("name", text: $name)
                .frame(width: 200)
            Button {
                Task {
                    do {
                        try await userRepo.saveUser(with: userId, and: name)
                    } catch {
                        print("error: \(error)")
                    }
                }
            } label: {
                Text("setUserName")
            }
        }
    }
}

#Preview {
    MainView()
}
