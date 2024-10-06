//
//  EventEntity.swift
//  this-day
//
//  Created by Sergey Bendak on 24.09.2024.
//

import CoreData

extension EventEntity {

    var inBookmarks: Bool {
        return bookmark != nil
    }

    static func createID(dayID: String, year: String, suffix: String) -> String {
        let preparedYear = year.replacingOccurrences(of: " ", with: "")
                               .replacingOccurrences(of: ".", with: "")
        return dayID.appending("-").appending(preparedYear)
                    .appending("-").appending(suffix)
    }

    static func extractDayID(from eventID: String) -> String? {
        let components = eventID.split(separator: "-")
        guard components.count >= 3 else { return nil }

        let dayIDComponents = components.prefix(3)
        let dayID = dayIDComponents.joined(separator: "-")

        if dayID.isEmpty { return nil }
        return dayID
    }

    static func from(model: EventNetworkModel,
                     dayID: String,
                     type: EventType,
                     context: NSManagedObjectContext) -> EventEntity {
        let eventEntity = EventEntity(context: context)
        eventEntity.id = createID(dayID: dayID, year: model.year,
                                  suffix: model.title.sha256Hash(short: true))
        eventEntity.title = model.title
        eventEntity.year = model.year
        eventEntity.subtitle = model.additional
        eventEntity.eventType = type
        return eventEntity
    }

    func stringDate(language: String) -> String? {
        guard let stringDate = day?.date.toLocalizedDayMonth(language: language) else { return nil }
        return stringDate + ", \(year)"
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
        guard let date = day?.date else {
            return nil
        }

        var resultString = date.toLocalizedDayMonth(language: language)
        resultString += language == "ru" ? " \(year) г." : ", \(year)"
        resultString += ":\n"

        switch self.eventType {
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
