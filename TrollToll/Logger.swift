//
//  Logger.swift
//  TrollToll
//
//  Created by Cagatay on 30.12.2025.
//

import OSLog

extension Logger {
    private static var bundleId = Bundle.main.bundleIdentifier!

    static let multiplayer = Logger(subsystem: bundleId, category: "Multiplayer")
}
