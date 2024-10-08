//
//  EventDataModel.swift
//  this-day
//
//  Created by Sergey Bendak on 4.10.2024.
//

import Foundation

struct EventDataModel {
    let id: String
    let year: String
    let title: String
    let subtitle: String?
    let type: EventType
    let date: Date?
    let language: String
    let inBookmarks: Bool

    var stringDate: String? {
        guard let stringDate = date?.toLocalizedDayMonth(language: language) else { return nil }
        return stringDate + ", \(year)"
    }

    init(entity: EventEntity) {
        self.id = entity.id
        self.year = entity.year
        self.title = entity.title
        self.subtitle = entity.subtitle
        self.type = entity.eventType
        self.date = entity.day?.date
        self.language = entity.day?.language ?? "en"
        self.inBookmarks = entity.inBookmarks
    }

    func toDisplayModel() -> Event {
        Event(
            id: self.id,
            year: self.year,
            title: self.title,
            subtitle: self.subtitle,
            inBookmarks: self.inBookmarks
        )
    }

    func toSharingString(language: String) -> String? {
        guard let date else { return nil }

        var resultString = date.toLocalizedDayMonth(language: language)
        resultString += language == "ru" ? " \(year) г" : ", \(year)"
        resultString += ":\n"

        switch type {
        case .general:
            resultString += self.title
        case .birth:
            let prefix = LocalizedString("sharing_text.was_born")
            resultString += "\(prefix) \(self.title)"
        case .death:
            let prefix = LocalizedString("sharing_text.died")
            resultString += "\(prefix) \(self.title)"
        }

        if let subtitle = self.subtitle, !subtitle.isEmpty {
            resultString += " - \(subtitle)"
        }

        return resultString
    }
}
