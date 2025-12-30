//
//  GameLobbyView.swift
//  TrollToll
//
//  Created by Cagatay on 30.12.2025.
//

import SwiftUI

struct GameLobbyView: View {
    let isHost: Bool

    var body: some View {
        Text(verbatim: "is host: \(isHost)")
    }
}

#Preview {
    GameLobbyView(isHost: true)
}
