//
//  GameLobbyView.swift
//  TrollToll
//
//  Created by Cagatay on 30.12.2025.
//

import GameKit
import SwiftUI

struct GameLobbyView: View {
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
            server.authenticate()
        }
    }
}

#Preview {
    GameLobbyView(isHost: true)
}
