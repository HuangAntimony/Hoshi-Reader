//
//  ReaderWindow.swift
//  Hoshi Reader
//
//  Copyright © 2026 Manhhao.
//  SPDX-License-Identifier: GPL-3.0-or-later
//

import SwiftUI

private struct DismissReaderKey: EnvironmentKey {
    static let defaultValue: (() -> Void)? = nil
}

extension EnvironmentValues {
    var dismissReader: (() -> Void)? {
        get { self[DismissReaderKey.self] }
        set { self[DismissReaderKey.self] = newValue }
    }
}

@MainActor
final class ReaderWindow {
    private var window: UIWindow?
    
    func present<Content: View>(@ViewBuilder content: () -> Content, onDismiss: @escaping () -> Void) {
        guard window == nil,
              let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
        
        let dismiss: () -> Void = { [weak self] in self?.dismiss(onDismiss: onDismiss) }
        let host = UIHostingController(rootView: AnyView(content().environment(\.dismissReader, dismiss)))
        
        let window = UIWindow(windowScene: scene)
        window.rootViewController = host
        window.windowLevel = .normal + 1
        window.alpha = 0
        window.makeKeyAndVisible()
        self.window = window
        
        UIView.animate(withDuration: 0.2) { window.alpha = 1 }
    }
    
    func dismiss(onDismiss: (() -> Void)? = nil) {
        guard let window else { return }
        self.window = nil
        UIView.animate(withDuration: 0.2, animations: {
            window.alpha = 0
        }) { _ in
            window.isHidden = true
            onDismiss?()
        }
    }
}
