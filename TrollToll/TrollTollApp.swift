//
//  TrollTollApp.swift
//  TrollToll
//
//  Created by Cagatay on 30.12.2025.
//

import SwiftUI

@main
struct TrollTollApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            MainView()
        }
    }
}
