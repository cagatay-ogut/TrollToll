//
//  AppInfo.swift
//  TrollToll
//
//  Created by Cagatay on 15.01.2026.
//

import Foundation

enum AppInfo {
    static let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
}
