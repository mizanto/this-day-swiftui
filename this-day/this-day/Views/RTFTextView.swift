//
//  RTFTextView.swift
//  this-day
//
//  Created by Sergey Bendak on 10.10.2024.
//

import SwiftUI
import UIKit

struct RTFTextView: UIViewRepresentable {
    let fileName: String

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.isEditable = false
        textView.backgroundColor = .clear
        textView.showsVerticalScrollIndicator = false
        
        if let url = Bundle.main.url(forResource: fileName, withExtension: "rtf") {
            do {
                let data = try Data(contentsOf: url)
                let attributedString = try NSAttributedString(
                    data: data,
                    options: [.documentType: NSAttributedString.DocumentType.rtf],
                    documentAttributes: nil
                )
                textView.attributedText = attributedString
            } catch {
                AppLogger.shared.error("Unable to load RTF file: \(fileName).")
            }
        }

        return textView
    }

    func updateUIView(_ uiView: UITextView, context: Context) {}
}
