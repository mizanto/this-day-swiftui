//
//  SnackbarModifier.swift
//  this-day
//
//  Created by Sergey Bendak on 27.09.2024.
//

import SwiftUI

struct SnackbarModifier: ViewModifier {
    @Binding var isPresented: Bool
    var message: String
    var type: Snackbar.SnackbarType
    var duration: TimeInterval

    func body(content: Content) -> some View {
        ZStack {
            content

            if isPresented {
                VStack {
                    Spacer()
                    Snackbar(message: message, type: type)
                        .transition(.move(edge: .bottom))
                        .padding(.bottom, 16)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.clear)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                        withAnimation {
                            isPresented = false
                        }
                    }
                }
            }
        }
    }
}

extension View {
    func snackbar(isPresented: Binding<Bool>,
                  message: String,
                  type: Snackbar.SnackbarType = .message,
                  duration: TimeInterval = 2) -> some View {
        self.modifier(
            SnackbarModifier(
                isPresented: isPresented,
                message: message,
                type: type,
                duration: duration
            )
        )
    }
}
