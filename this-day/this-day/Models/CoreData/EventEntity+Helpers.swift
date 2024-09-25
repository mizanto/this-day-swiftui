//
//  EventEntity.swift
//  this-day
//
//  Created by Sergey Bendak on 24.09.2024.
//

import CoreData

extension EventEntity {
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

    func toSharingString(for date: Date) -> String {
            var resultString = "This day (\(date.toFormat("MMMM dd")))"

            if let year = self.year {
                resultString += " in \(year)"
            }
            resultString += ":\n"

            switch self.eventType {
            case .general:
                resultString += self.title
            case .birth:
                resultString += "Was born \(self.title)"
            case .death:
                resultString += "Died \(self.title)"
            case .holiday:
                resultString = "Today is a \(self.title)"
            }

            if let subtitle = self.subtitle, !subtitle.isEmpty {
                resultString += " - \(subtitle)"
            }

            return resultString
        }
}
