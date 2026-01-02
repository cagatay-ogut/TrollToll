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
    let user: User
    let match: Match

    init(user: User, match: Match) {
        self.user = user
        self.match = match
        _server = State(initialValue: FBMultiplayerServer(user: user, match: match))
    }

    var body: some View {
        Text("user: \(user.name), match: \(match.id)")
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
    }
}
