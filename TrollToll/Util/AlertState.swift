//
//  AlertState.swift
//  TrollToll
//
//  Created by Cagatay on 8.01.2026.
//

import SwiftUI

@MainActor
@propertyWrapper
struct AlertState<T>: DynamicProperty {
    @State private var value: T?

    var wrappedValue: T? {
        get { value }
        nonmutating set { value = newValue }
    }

    var projectedValue: Binding<Bool> {
        Binding<Bool>(
            get: { value != nil },
            set: { newValue in
                if !newValue { value = nil }
            }
        )
    }
}
