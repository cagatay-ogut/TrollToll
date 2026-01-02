//
//  GameView.swift
//  TrollToll
//
//  Created by Cagatay on 30.12.2025.
//

import SwiftUI

struct GameView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var lobby: LobbyService
    @State private var game: GameService
    @State private var showLeaveAlert = false
    @State private var toast: Toast?

    init(user: User, match: Match) {
        _lobby = State(initialValue: FBLobbyService(user: user, match: match))
        _game = State(initialValue: FBGameService(user: user, match: match))
    }

    var body: some View {
        Text("user: \(lobby.user.name), turn: \(lobby.match?.state.turn ?? 0)")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay(alignment: .bottomTrailing) {
                Button {
                    Task {
                        do {
                            try await game.endPlayerTurn()
                        } catch {
                            toast = Toast(message: error.localizedDescription)
                        }
                    }
                } label: {
                    Text("endTurn")
                }
                .padding()
                .disabled(lobby.match?.state.currentPlayerId != game.user.id)
            }
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showLeaveAlert = true
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                }
            }
            .alert("alertSureToLeave", isPresented: $showLeaveAlert) {
                Button("yes", role: .destructive) {
                    Task {
                        do {
                            if game.user.isHost {
                                try await lobby.cancelMatch()
                            } else {
                                try await lobby.leaveMatch()
                            }
                        } catch {
                            toast = Toast(message: error.localizedDescription)
                        }
                        dismiss()
                    }
                }
                Button("cancel", role: .cancel) { /* closes dialog */ }
            }
            .toast(toast: $toast)
            .sensoryFeedback(.error, trigger: toast) { _, newValue in
                newValue != nil
            }
            .task {
                do {
                    try await lobby.observeMatch()
                } catch {
                    toast = Toast(message: error.localizedDescription)
                }
            }
    }
}

#Preview {
    let host = User(id: "host_id", name: "host", isHost: true)
    let player = User(id: "player_id", name: "player", isHost: false)
    GameView(
        user: host,
        match: Match(id: "match_id", status: .playing, host: host, players: [player], createdAt: Date())
    )
}
