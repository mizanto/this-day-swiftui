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
    
    static func createID(dayID: String, year: String) -> String {
        let preparedYear = year.replacingOccurrences(of: " ", with: "")
                               .replacingOccurrences(of: ".", with: "")
        return "\(dayID)-\(preparedYear)"
    }

    static func from(networkModel: EventNetworkModel,
                     dayID: String,
                     type: EventType,
                     context: NSManagedObjectContext) -> EventEntity {
        let eventEntity = EventEntity(context: context)
        eventEntity.id = createID(dayID: dayID, year: networkModel.year)
        eventEntity.title = networkModel.title
        eventEntity.year = networkModel.year
        eventEntity.subtitle = networkModel.additional
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
