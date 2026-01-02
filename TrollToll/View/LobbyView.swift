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
    @State private var lobby: LobbyService
    @State private var toast: Toast?

    init(user: User) {
        _lobby = State(initialValue: FBLobbyService(user: user))
    }

    var body: some View {
        VStack {
            if lobby.user.isHost {
                HostView(lobby: $lobby, toast: $toast)
            } else {
                JoiningPlayerView(lobby: $lobby, toast: $toast, matches: lobby.matches)
            }
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    Task {
                        do {
                            if lobby.user.isHost {
                                try await lobby.cancelMatch()
                            } else {
                                try await lobby.leaveMatch()
                            }
                        } catch {
                            toast = Toast(message: error.localizedDescription)
                        }
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
        .onChange(of: lobby.match) {
            if lobby.match?.status == .playing {
                router.navigateToRoot()
                router.navigate(to: .game(user: lobby.user, match: lobby.match!))
            }
        }
    }
}

private struct HostView: View {
    @Binding var lobby: LobbyService
    @Binding var toast: Toast?

    var body: some View {
        VStack {
            Text("waitingForPlayers")
                .padding(.bottom)
            Button {
                Task {
                    do {
                        try await lobby.startMatch()
                    } catch {
                        toast = Toast(message: error.localizedDescription)
                    }
                }
            } label: {
                Text("startGame")
            }
            .disabled(!lobby.readyToStart)
            if let match = lobby.match {
                PlayerListView(match: match)
            }
        }
        .task {
            do {
                try await lobby.hostMatch()
                try await lobby.observeMatch()
            } catch {
                toast = Toast(message: error.localizedDescription)
            }
        }
    }
}

private struct JoiningPlayerView: View {
    @Binding var lobby: LobbyService
    @Binding var toast: Toast?
    let matches: [Match]

    var body: some View {
        if let match = lobby.match {
            PlayerListView(match: match)
                .task {
                    do {
                        try await lobby.observeMatch()
                    } catch {
                        toast = Toast(message: error.localizedDescription)
                    }
                }
        } else {
            Section {
                List {
                    ForEach(matches) { match in
                        Text(match.createdAt, format: .dateTime)
                            .onTapGesture {
                                Task {
                                    do {
                                        try await lobby.joinMatch(match)
                                    } catch {
                                        toast = Toast(message: error.localizedDescription)
                                    }
                                }
                            }
                    }
                }
            } header: {
                if matches.isEmpty {
                    Text("noMatchFound")
                }
            }
            .task {
                await lobby.observeLobbyMatches()
            }
        }
    }
}

private struct PlayerListView: View {
    let match: Match

    var body: some View {
        Section {
            List {
                Text(match.host.name + " (" + String(localized: "host") + ")")
                ForEach(match.players, id: \.self) { player in
                    Text(player.name)
                }
            }
        } header: {
            Text("players")
        }
    }
}

#Preview("Player") {
    LobbyView(user: User(id: "id", name: "name", isHost: false))
        .environment(Router())
}

// #Preview("Host) {
//     LobbyView(isHost: true)
//         .environment(Router())
// }
