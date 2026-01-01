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
    @State private var server: MultiplayerInterface
    let isHost: Bool

    init(isHost: Bool) {
        self.isHost = isHost
        self._server = State(initialValue: MultiplayerServer(isHost: isHost))
    }

    var body: some View {
        VStack {
            if isHost {
                HostView()
                Button {
                    Task {
                        await server.startMatch()
                    }
                } label: {
                    Text("startGame")
                }
                .disabled(!server.readyToStart)
            } else {
                PlayerView(server: $server, matches: server.matches)
            }
            PlayerListView(match: server.match)
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    Task {
                        if isHost {
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
    var body: some View {
        Text("waitingForPlayers")
            .padding(.bottom)
    }
}

private struct PlayerView: View {
    @Binding var server: MultiplayerInterface
    let matches: [Match]

    var body: some View {
        if let joinedMatchId = server.joinedMatchId {
            Text("joined: \(joinedMatchId)")
        } else {
            Section {
                List {
                    ForEach(matches) { match in
                        Text(match.createdAt, format: .dateTime)
                            .onTapGesture {
                                Task {
                                    await server.joinMatch(with: match.id)
                                    await server.observeMatch()
                                }
                            }
                    }
                }
            } footer: {
                if matches.isEmpty {
                    Text("noMatchFound")
                }
            }
        }
    }
}

private struct PlayerListView: View {
    let match: Match?

    var body: some View {
        if let match {
            Section {
                List {
                    Text(match.hostId + " (host)")
                    ForEach(match.playerIds, id: \.self) { playerId in
                        Text(playerId)
                    }
                }
            } header: {
                Text("players")
            }
        } else {
            ProgressView()
        }
    }
}

#Preview("Player") {
    LobbyView(isHost: false)
        .environment(Router())
}

// #Preview("Host) {
//     LobbyView(isHost: true)
//         .environment(Router())
// }
