//
//  GameView.swift
//  TrollToll
//
//  Created by Cagatay on 30.12.2025.
//

import SpriteKit
import SwiftUI

struct GameView: View {
    @Environment(\.dismiss) private var dismiss
    @AlertState private var alert: AlertType?
    @State private var viewModel: GameViewModel
    @State private var toast: Toast?
    private let scene: GameScene

    init(user: User, match: Match, gameState: GameState) {
        _viewModel = State(initialValue: GameViewModel(user: user, match: match, gameState: gameState))
        scene = GameScene()
        scene.scaleMode = .resizeFill
    }

    var body: some View {
        ZStack {
            SpriteView(scene: scene, debugOptions: [.showsFPS, .showsNodeCount])
            HStack {
                Text("current player: \(viewModel.currentPlayerName)")
                Text("turn: \(viewModel.gameState.turn)")
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            .foregroundStyle(Color.white)
        }
        .overlay(alignment: .bottomTrailing) {
            HStack {
                Button {
                    Task {
                        await viewModel.takeCard()
                    }
                } label: {
                    Text("takeCard")
                }
                .disabled(!viewModel.canTakeCard)
                Button {
                    Task {
                        await viewModel.putToken()
                    }
                } label: {
                    Text("putToken")
                }
                .disabled(!viewModel.canPutToken)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    alert = .confirmLeave
                } label: {
                    Image(systemName: "chevron.left")
                }
            }
        }
        .alert(alert?.title ?? "", isPresented: $alert, presenting: alert) { alertType in
            switch alertType {
            case .confirmLeave:
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
            case .hostLeft:
                Button("ok", role: .cancel) {
                    dismiss()
                }
            }
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
        .onAppear {
            scene.viewModel = viewModel
        }
        .onChange(of: viewModel.gameState) {
            scene.onStateChange()
        }
        .onChange(of: viewModel.errorMessage) {
            if let message = viewModel.errorMessage {
                toast = Toast(message: message)
            }
        }
        .onChange(of: viewModel.gameState.progress) {
            if case .finished(let victor) = viewModel.gameState.progress {
                toast = Toast(message: "Victor is: \(viewModel.name(for: victor))", type: .info, duration: .long)
            }
        }
        .onChange(of: viewModel.hostLeft) {
            alert = .hostLeft
        }
    }
}

private enum AlertType {
    case confirmLeave
    case hostLeft

    var title: LocalizedStringKey {
        switch self {
        case .confirmLeave:
            "alertSureToLeave"
        case .hostLeft:
            "hostLeft"
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
