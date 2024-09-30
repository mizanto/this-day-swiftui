//
//  CategoryPicker.swift
//  this-day
//
//  Created by Sergey Bendak on 20.09.2024.
//

import SwiftUI

enum EventCategory: String, CaseIterable, Identifiable {
    case events
    case births
    case deaths

    var id: String { self.rawValue }

    var string: String {
        switch self {
        case .events: return LocalizedString("category.events")
        case .births: return LocalizedString("category.births")
        case .deaths: return LocalizedString("category.deaths")
        }
    }

    var color: Color {
        switch self {
        case .events: return .blue
        case .births: return .green
        case .deaths: return .gray
        }
    }

    static func from(_ type: EventType) -> EventCategory {
        switch type {
        case .general: return .events
        case .birth: return .births
        case .death: return .deaths
        }
    }
}

struct CategoryPicker: View {
    @Binding var selectedCategory: EventCategory
    @EnvironmentObject var localizationManager: LocalizationManager

    var body: some View {
        Picker(LocalizedString("category_picker.title"), selection: $selectedCategory) {
            ForEach(EventCategory.allCases) { category in
                Text(category.string).tag(category)
            }
        }
        .id(UUID()) // need for update localization
        .pickerStyle(SegmentedPickerStyle())
        .onChange(of: localizationManager.currentLanguage) {
            selectedCategory = selectedCategory
        }
    }
}
