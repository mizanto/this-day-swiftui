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
            return ShortEvent(id: self.id ?? UUID(), title: self.title ?? "")
        case .general:
            return DefaultEvent(id: self.id ?? UUID(), year: self.year ?? "", title: self.title ?? "")
        case .birth, .death:
            return ExtendedEvent(
                id: self.id ?? UUID(),
                year: self.year ?? "",
                title: self.title ?? "",
                subtitle: self.subtitle ?? ""
            )
        }
    }
}
