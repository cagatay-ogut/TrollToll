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

    init(user: User, match: Match, gameState: GameState) {
        _viewModel = State(initialValue: GameViewModel(user: user, match: match, gameState: gameState))
    }

    var body: some View {
        VStack {
            Text("turn: \(viewModel.gameState.turn)")
            Text("current player: \(viewModel.currentPlayerName)")
            Text("middle card: \(viewModel.gameState.middleCards[0])")
            Text("token in middle: \(viewModel.gameState.tokenInMiddle)")
            Text("=========")
            HStack {
                ForEach(viewModel.gameState.players, id: \.id) { player in
                    VStack {
                        Text("\(player.name)")
                        Text("\(viewModel.gameState.playerTokens[player.id]!)")
                        Text(String(describing: viewModel.gameState.playerCards[player.id] ?? []))
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .bottom) {
            HStack {
                Button {
                    Task {
                        await viewModel.takeCard()
                    }
                } label: {
                    Text("takeCard")
                }
                .disabled(!viewModel.isPlayerTurn)
                Button {
                    Task {
                        await viewModel.putToken()
                    }
                } label: {
                    Text("putToken")
                }
                .disabled(!viewModel.isPlayerTurn || !viewModel.canPutToken)
            }
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
        .task {
            await viewModel.observeGame()
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
    let match = Match(id: "match_id", status: .playing, host: host, players: [player], createdAt: Date())
    GameView(
        user: host,
        match: match,
        gameState: GameState(from: match)
    )
}
