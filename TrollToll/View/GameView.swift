//
//  GameView.swift
//  TrollToll
//
//  Created by Cagatay on 30.12.2025.
//

import SwiftUI

struct GameView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var server: MultiplayerServer
    @State private var showLeaveAlert = false
    @State private var toast: Toast?

    init(user: User, match: Match) {
        _server = State(initialValue: FBMultiplayerServer(user: user, match: match))
    }

    var body: some View {
        Text("user: \(server.user.name), turn: \(server.match?.state.turn ?? 0)")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay(alignment: .bottomTrailing) {
                Button {
                    Task {
                        do {
                            try await server.endPlayerTurn()
                        } catch {
                            toast = Toast(message: error.localizedDescription)
                        }
                    }
                } label: {
                    Text("endTurn")
                }
                .disabled(server.match?.state.currentPlayerId != server.user.id)
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
                            if server.user.isHost {
                                try await server.cancelMatch()
                            } else {
                                try await server.leaveMatch()
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
                    try await server.observeMatch()
                } catch {
                    toast = Toast(message: error.localizedDescription)
                }
            }
    }
}
