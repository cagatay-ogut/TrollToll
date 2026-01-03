//
//  LobbyView.swift
//  TrollToll
//
//  Created by Cagatay on 30.12.2025.
//

import SwiftUI

struct LobbyView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(Router.self) private var router
    @State private var viewModel: LobbyViewModel
    @State private var toast: Toast?

    init(user: User) {
        _viewModel = State(initialValue: LobbyViewModel(user: user))
    }

    var body: some View {
        VStack {
            if viewModel.user.isHost {
                HostView(viewModel: $viewModel, toast: $toast)
            } else {
                JoiningPlayerView(viewModel: $viewModel, toast: $toast, matches: viewModel.matches)
            }
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    Task {
                        await viewModel.leaveLobby()
                    }
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                }
            }
        }
        .toast(toast: $toast)
        .sensoryFeedback(.error, trigger: toast) { _, newValue in
            newValue != nil
        }
        .onChange(of: viewModel.match) {
            if viewModel.match?.status == .playing {
                router.navigateToRoot()
                router.navigate(to: .game(user: viewModel.user, match: viewModel.match!))
            }
        }
        .onChange(of: viewModel.errorMessage) {
            if let message = viewModel.errorMessage {
                toast = Toast(message: message)
            }
        }
    }
}

private struct HostView: View {
    @Binding var viewModel: LobbyViewModel
    @Binding var toast: Toast?

    var body: some View {
        VStack {
            Button {
                Task {
                    await viewModel.startMatch()
                }
            } label: {
                Text("startGame")
            }
            .disabled(!viewModel.readyToStart)
            if let match = viewModel.match {
                PlayerListView(match: match)
            }
        }
        .task {
            await viewModel.hostMatch()
            await viewModel.observeMatch()
        }
    }
}

private struct JoiningPlayerView: View {
    @Binding var viewModel: LobbyViewModel
    @Binding var toast: Toast?
    let matches: [Match]

    var body: some View {
        if let match = viewModel.match {
            PlayerListView(match: match)
                .task {
                    await viewModel.observeMatch()
                }
        } else {
            List {
                Section {
                    ForEach(matches) { match in
                        Button {
                            Task {
                                await viewModel.joinMatch(match)
                            }
                        } label: {
                            Text(match.createdAt, format: .dateTime)
                        }
                    }
                } header: {
                    Text("openMatches")
                } footer: {
                    if matches.isEmpty {
                        Text("noMatchFound")
                    }
                }
            }
            .task {
                await viewModel.observeLobbyMatches()
            }
        }
    }
}

private struct PlayerListView: View {
    let match: Match

    var body: some View {
        List {
            Section {
                Text(match.host.name + " (" + String(localized: "host") + ")")
                ForEach(match.players, id: \.self) { player in
                    Text(player.name)
                }
            }
            header: {
                Text("players")
            }
        }
    }
}

#Preview("Player") {
    LobbyView(user: User(id: "id", name: "player", isHost: false))
        .environment(Router())
}

// #Preview("Host") {
//      LobbyView(user: User(id: "id", name: "host", isHost: true))
//          .environment(Router())
// }
