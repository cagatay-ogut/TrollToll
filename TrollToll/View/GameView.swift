//
//  GameView.swift
//  TrollToll
//
//  Created by Cagatay on 30.12.2025.
//

import SwiftUI

struct GameView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: GameViewModel
    @State private var showLeaveAlert = false
    @State private var toast: Toast?

    init(user: User, match: Match) {
        _viewModel = State(initialValue: GameViewModel(user: user, match: match))
    }

    var body: some View {
        Text("user: \(viewModel.user.name), turn: \(viewModel.match.state.turn)")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay(alignment: .bottomTrailing) {
                Button {
                    Task {
                        await viewModel.endPlayerTurn()
                    }
                } label: {
                    Text("endTurn")
                }
                .padding()
                .disabled(!viewModel.isPlayerTurn)
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
                        if viewModel.user.isHost {
                            await viewModel.cancelMatch()
                        } else {
                            await viewModel.leaveMatch()
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
                await viewModel.observeMatch()
            }
            .onChange(of: viewModel.errorMessage) {
                if let message = viewModel.errorMessage {
                    toast = Toast(message: message)
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
