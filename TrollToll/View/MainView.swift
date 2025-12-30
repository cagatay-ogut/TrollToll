//
//  MainView.swift
//  TrollToll
//
//  Created by Cagatay on 30.12.2025.
//

import SwiftUI

struct MainView: View {
    @State private var router = Router()

    var body: some View {
        NavigationStack(path: $router.navPath) {
            VStack(spacing: 32) {
                Button {
                    router.navigate(to: .gameLobby(isHost: true))
                } label: {
                    Text("hostGame")
                        .padding(4)
                }
                Button {
                    router.navigate(to: .gameLobby(isHost: false))
                } label: {
                    Text("joinGame")
                        .padding(4)
                }
            }
            .buttonStyle(.glassProminent)
            .navigationDestination(for: Router.Destination.self) { destination in
                switch destination {
                case .gameLobby(let isHost):
                    GameLobbyView(isHost: isHost)
                }
            }
        }
    }
}

#Preview {
    MainView()
}
