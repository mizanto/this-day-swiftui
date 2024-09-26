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
    var string: String { self.rawValue }
    var color: Color {
        switch self {
        case .events: return .blue
        case .births: return .green
        case .deaths: return .black
        case .holidays: return .pink
        }
    }

    static func from(_ type: EventType) -> EventCategory {
        switch type {
        case .general: return .events
        case .birth: return .births
        case .death: return .deaths
        case .holiday: return .holidays
        }
    }
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
