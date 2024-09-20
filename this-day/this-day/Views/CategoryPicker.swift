//
//  CategoryPicker.swift
//  this-day
//
//  Created by Sergey Bendak on 20.09.2024.
//

import SwiftUI

enum EventCategory: String, CaseIterable, Identifiable {
    case events = "Events"
    case births = "Births"
    case deaths = "Deaths"
    case holidays = "Holidays"

    var id: String { self.rawValue }
}

struct CategoryPicker: View {
    @Binding var selectedCategory: EventCategory

    var body: some View {
        Picker("Select Category", selection: $selectedCategory) {
            ForEach(EventCategory.allCases) { category in
                Text(category.rawValue).tag(category)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
    }
}
