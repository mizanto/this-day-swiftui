//
//  PrivacyPolicyView.swift
//  this-day
//
//  Created by Sergey Bendak on 10.10.2024.
//

import SwiftUI

struct PrivacyPolicyView: View {
    let language: String

    var body: some View {
        RTFTextView(fileName: "privacy_policy_\(language)")
            .padding(.horizontal)
    }
}

#Preview {
    PrivacyPolicyView(language: "en")
}
