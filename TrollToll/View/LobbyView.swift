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

    init(user: User) {
        _server = State(initialValue: FBMultiplayerServer(user: user))
    }

    var body: some View {
        VStack {
            if server.user.isHost {
                HostView(server: $server)
            } else {
                JoiningPlayerView(server: $server, matches: server.matches)
            }
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    Task {
                        if server.user.isHost {
                            await server.cancelMatch()
                        } else {
                            await server.leaveMatch()
                        }
                    }
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                }
            }
        }
        .onChange(of: server.match) {
            if server.match?.status == .playing {
                router.navigateToRoot()
                router.navigate(to: .game)
            }
        }
    }
}

private struct HostView: View {
    @Binding var server: MultiplayerServer

    var body: some View {
        VStack {
            Text("waitingForPlayers")
                .padding(.bottom)
            Button {
                Task {
                    await server.startMatch()
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
            await server.hostMatch()
            await server.observeMatch()
        }
    }
}

private struct JoiningPlayerView: View {
    @Binding var server: MultiplayerServer
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
                                    await server.joinMatch(match)
                                    await server.observeMatch()
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
                await server.findMatch()
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
