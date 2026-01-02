//
//  Toast.swift
//  TrollToll
//
//  Created by Cagatay on 2.01.2026.
//

import SwiftUI

struct Toast: Equatable {
    let message: LocalizedStringKey
    let type: ToastType
    let alignment: ToastAlignment
    let duration: ToastDuration
    let action: ToastAction?

    init(
        message: LocalizedStringKey,
        type: ToastType = .error,
        alignment: ToastAlignment = .bottom,
        duration: ToastDuration = .medium,
        action: ToastAction? = nil
    ) {
        self.message = message
        self.type = type
        self.alignment = alignment
        self.duration = duration
        self.action = action
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.message == rhs.message
        && lhs.type == rhs.type
        && lhs.alignment == rhs.alignment
        && lhs.duration == rhs.duration
        && (lhs.action == nil) == (rhs.action == nil)
    }
}

@Observable
class GlobalToast {
    var toast: Toast?
}

enum ToastType {
    case error, warning, success, info

    var color: Color {
        switch self {
        case .error:
            .toastError
        case .warning:
            .toastWarning
        case .success:
            .toastSuccess
        case .info:
            .toastInfo
        }
    }

    var icon: String {
        switch self {
        case .error:
            "x.circle.fill"
        case .warning:
            "exclamationmark.triangle.fill"
        case .success:
            "checkmark.circle.fill"
        case .info:
            "info.circle.fill"
        }
    }
}

enum ToastDuration {
    case short, medium, long

    var value: Double {
        switch self {
        case .short:
            1
        case .medium:
            2
        case .long:
            4
        }
    }
}

enum ToastAlignment {
    case bottom, top

    var edge: Edge {
        switch self {
        case .bottom:
            return .bottom
        case .top:
            return .top
        }
    }

    var coreAlignment: Alignment {
        switch self {
        case .bottom:
            return .bottom
        case .top:
            return .top
        }
    }
}

struct ToastAction {
    let image: String
    let action: () -> Void
}
