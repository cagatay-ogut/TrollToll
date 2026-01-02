// swiftlint:disable:this file_name
//
//  AppColors.swift
//  TrollToll
//
//  Created by Cagatay on 2.01.2026.
//

import SwiftUI

extension Color {
    static let toastError = Color.red
    static let toastWarning = Color.yellow.shade(by: 0.1)
    static let toastSuccess = Color.green.shade(by: 0.1)
    static let toastInfo = Color.cyan.shade(by: 0.1)

    // MARK: - FUNCTIONS
    static func adaptive(light: Color, dark: Color) -> Color {
        Color(uiColor: UIColor { trait in
            trait.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
        })
    }

    func shade(by: Double) -> Color {
        self.mix(with: .black, by: by, in: .device)
    }

    func tint(by: Double) -> Color {
        self.mix(with: .white, by: by, in: .device)
    }
}
