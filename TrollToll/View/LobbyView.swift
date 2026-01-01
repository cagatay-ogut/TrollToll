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
            switch server.authState {
            case .unauthenticated:
                Text("Authenticating...")
            case .authenticated:
                Text("Authenticated")
                    .padding(.bottom)
                if isHost {
                    HostView()
                } else {
                    PlayerView(server: $server, matches: server.matches)
                }
            case .failed:
                Text("FailedAuthMessage")
            }
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
        .onAppear {
            Task {
                await server.authenticate()
            }
        }
        .onChange(of: server.authState) {
            if server.authState == .authenticated {
                Task {
                    if isHost {
                        await server.hostMatch()
                    } else {
                        await server.findMatch()
                    }
                }
            }
        }
        .onChange(of: server.match) {
            guard server.match != nil else { return }
            router.navigateToRoot()
            router.navigate(to: .game)
        }
    }
}

private struct HostView: View {
    var body: some View {
        Text("waitingForPlayers")
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

#Preview("Player") {
    LobbyView(isHost: false)
        .environment(Router())
}

// #Preview("Host) {
//     LobbyView(isHost: true)
//         .environment(Router())
// }
