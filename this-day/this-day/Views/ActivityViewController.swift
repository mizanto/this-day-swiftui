//
//  ActivityViewController.swift
//  this-day
//
//  Created by Sergey Bendak on 25.09.2024.
//

import SwiftUI

struct ActivityViewController: UIViewControllerRepresentable {
    let activityItems: [Any]
    let applicationActivities: [UIActivity]? = nil
    var completion: VoidClosure?

    func makeUIViewController(
        context: UIViewControllerRepresentableContext<ActivityViewController>
    ) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems,
                                                  applicationActivities: applicationActivities)
        controller.completionWithItemsHandler = { _, _, _, _ in
            completion?()
        }
        return controller
    }

    func updateUIViewController(
        _ uiViewController: UIActivityViewController,
        context: UIViewControllerRepresentableContext<ActivityViewController>
    ) {
    }
}
