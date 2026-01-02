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
    @State private var server: MultiplayerServer
    @State private var toast: Toast?

    init(user: User) {
        _server = State(initialValue: FBMultiplayerServer(user: user))
    }

    var body: some View {
        VStack {
            if server.user.isHost {
                HostView(server: $server, toast: $toast)
            } else {
                JoiningPlayerView(server: $server, toast: $toast, matches: server.matches)
            }
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    Task {
                        do {
                            if server.user.isHost {
                                server.stopObservingMatch()
                                try await server.cancelMatch()
                            } else {
                                try await server.leaveMatch()
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
        .onChange(of: server.match) {
            if server.match?.status == .playing {
                router.navigateToRoot()
                router.navigate(to: .game(user: server.user, match: server.match!))
            }
        }
    }
}

private struct HostView: View {
    @Binding var server: MultiplayerServer
    @Binding var toast: Toast?

    var body: some View {
        VStack {
            Text("waitingForPlayers")
                .padding(.bottom)
            Button {
                Task {
                    do {
                        try await server.startMatch()
                    } catch {
                        toast = Toast(message: error.localizedDescription)
                    }
                }
            } label: {
                Text("startGame")
            }
            .disabled(!server.readyToStart)
            if let match = server.match {
                PlayerListView(match: match)
            }
        }
        .task {
            do {
                try await server.hostMatch()
                try await server.observeMatch()
            } catch {
                toast = Toast(message: error.localizedDescription)
            }
        }
    }
}

private struct JoiningPlayerView: View {
    @Binding var server: MultiplayerServer
    @Binding var toast: Toast?
    let matches: [Match]

    var body: some View {
        if let match = server.match {
            PlayerListView(match: match)
        } else {
            Section {
                List {
                    ForEach(matches) { match in
                        Text(match.createdAt, format: .dateTime)
                            .onTapGesture {
                                Task {
                                    do {
                                        try await server.joinMatch(match)
                                        try await server.observeMatch()
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
                do {
                    try await server.findMatches()
                } catch {
                    toast = Toast(message: error.localizedDescription)
                }
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
