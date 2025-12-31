//
//  GameLobbyView.swift
//  TrollToll
//
//  Created by Cagatay on 30.12.2025.
//

import SwiftUI

struct GameLobbyView: View {
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
            case .failed:
                Text("FailedAuthMessage")
            }
            Text(verbatim: "is host: \(isHost)")
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

#Preview {
    GameLobbyView(isHost: true)
}
