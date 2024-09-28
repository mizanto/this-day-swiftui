//
//  EventEntity.swift
//  this-day
//
//  Created by Sergey Bendak on 24.09.2024.
//

import CoreData

extension EventEntity {

    var stringDate: String? {
        if eventType == .holiday {
            return day?.date.toFormat("MMMM dd")
        } else {
            guard let year, let stringDate = day?.date.toFormat("MMMM dd") else { return nil }
            return stringDate + ", \(year)"
        }
    }

    var inBookmarks: Bool {
        return bookmark != nil
    }

    static func from(networkModel: EventNetworkModel,
                     type: EventType,
                     context: NSManagedObjectContext) -> EventEntity {
        let eventEntity = EventEntity(context: context)
        eventEntity.id = UUID()
        eventEntity.title = networkModel.title
        eventEntity.year = networkModel.year
        eventEntity.subtitle = networkModel.additional
        eventEntity.eventType = type
        return eventEntity
    }

    func toDisplayModel() -> any EventProtocol {
        switch self.eventType {
        case .holiday:
            return ShortEvent(
                id: self.id,
                title: self.title,
                inBookmarks: self.inBookmarks
            )
        case .general, .birth, .death:
            return ExtendedEvent(
                id: self.id,
                year: self.year ?? "",
                title: self.title,
                subtitle: self.subtitle,
                inBookmarks: self.inBookmarks
            )
        }
    }

    func toSharingString() -> String? {
        guard let date = day?.date else {
            return nil
        }

        var resultString = date.toFormat("MMMM dd")

        if let year = self.year {
            resultString += ", \(year)"
        }
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
        case .holiday:
            let celebrates = LocalizedString("sharing_text.celebrates")
            resultString = "\(date.toFormat("MMMM dd")), \(celebrates) \(self.title)"
        }

        if let subtitle = self.subtitle, !subtitle.isEmpty {
            resultString += " - \(subtitle)"
        }

        return resultString
    }
}
