//
//  ToastView.swift
//  TrollToll
//
//  Created by Cagatay on 2.01.2026.
//

import SwiftUI

struct ToastView: View {
    let toast: Toast
    let onAction: (() -> Void)?

    var body: some View {
        HStack {
            Image(systemName: toast.type.icon)
            Text(toast.message)
            if let action = toast.action {
                Button {
                    action.action()
                    onAction?()
                } label: {
                    Image(systemName: action.image)
                }
            }
        }
        .fontWeight(.semibold)
        .foregroundStyle(Color.primary)
        .padding(.vertical, 8)
        .padding(.horizontal)
        .background(toast.type.color, in: .rect(cornerRadius: 8))
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: toast.alignment.coreAlignment)
    }
}

struct ToastModifier: ViewModifier {
    private let animDuration = 0.5
    @Binding var toast: Toast?

    func body(content: Content) -> some View {
        content
            .overlay {
                if let toast {
                    ToastView(toast: toast) {
                        self.toast = nil
                    }
                    .transition(
                        .asymmetric(
                            insertion: .move(edge: toast.alignment.edge),
                            removal: .opacity
                        )
                    )
                }
            }
            .animation(toast == nil ? .linear(duration: animDuration) : .easeOut(duration: animDuration), value: toast)
            .onChange(of: toast) {
                guard let toast else { return }
                DispatchQueue.main.asyncAfter(deadline: .now() + animDuration + toast.duration.value) {
                    self.toast = nil
                }
            }
    }
}

extension View {
    func toast(toast: Binding<Toast?>) -> some View {
        self.modifier(ToastModifier(toast: toast))
    }
}

#if DEBUG
#Preview {
    VStack {
        ToastView(toast: Toast(
            message: "error message",
            type: .error,
            action: ToastAction(image: "chevron.right") {}
        )) {}
        ToastView(toast: Toast(
            message: "warning message",
            type: .warning,
            action: ToastAction(image: "chevron.right") {}
        )) {}
        ToastView(toast: Toast(
            message: "success message",
            type: .success,
            action: ToastAction(image: "chevron.right") {}
        )) {}
        ToastView(toast: Toast(
            message: "info message",
            type: .info,
            action: ToastAction(image: "chevron.right") {}
        )) {}
    }
}
#endif
