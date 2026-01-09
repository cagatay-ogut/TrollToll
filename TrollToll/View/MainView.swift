//
//  MainView.swift
//  TrollToll
//
//  Created by Cagatay on 30.12.2025.
//

import SwiftUI

struct MainView: View {
    @State private var router = Router()
    @State private var viewModel = MainViewModel()

    var body: some View {
        NavigationStack(path: $router.navPath) {
            VStack(spacing: 32) {
                switch viewModel.authState {
                case .unauthenticated:
                    ProgressView()
                case .authenticated(let userId):
                    AuthenticatedView(viewModel: viewModel, router: router, userId: userId)
                case .failed:
                    FailedAuthView(viewModel: viewModel)
                }
            }
            .buttonStyle(.borderedProminent)
            .navigationDestination(for: Router.Destination.self) { destination in
                switch destination {
                case let .lobby(user):
                    LobbyView(user: user)
                case let .game(user, match, gameState):
                    GameView(user: user, match: match, gameState: gameState)
                }
            }
        }
        .task {
            await viewModel.authenticate()
        }
        .environment(router)
    }
}

private struct FailedAuthView: View {
    let viewModel: MainViewModel

    var body: some View {
        Button {
            Task {
                await viewModel.authenticate()
            }
        } label: {
            Text("retryAuth")
        }
    }
}

private struct AuthenticatedView: View {
    let viewModel: MainViewModel
    let router: Router
    let userId: String

    var body: some View {
        if viewModel.user == nil {
            UserNameField(viewModel: viewModel, userId: userId)
        }
        Button {
            viewModel.user?.isHost = true
            router.navigate(to: .lobby(user: viewModel.user!))
        } label: {
            Text("hostGame")
                .padding(4)
        }
        .disabled(viewModel.user == nil)
        Button {
            viewModel.user?.isHost = false
            router.navigate(to: .lobby(user: viewModel.user!))
        } label: {
            Text("joinGame")
                .padding(4)
        }
        .disabled(viewModel.user == nil)
    }
}

private struct UserNameField: View {
    @State private var name: String = ""
    let viewModel: MainViewModel
    let userId: String

    var body: some View {
        VStack {
            TextField("name", text: $name)
                .frame(width: 200)
            Button {
                Task {
                    await viewModel.saveUser(with: userId, and: name)
                }
            } label: {
                Text("setUserName")
            }
        }
    }
}

#if DEBUG
#Preview {
    MainView()
}
#endif
