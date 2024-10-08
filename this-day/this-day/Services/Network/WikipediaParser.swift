//
//  WikipediaParser.swift
//  this-day
//
//  Created by Sergey Bendak on 19.09.2024.
//

import Foundation

final class WikipediaParser {

    // Enum for categories
    enum Category: String, CaseIterable {
        case events = "== Events =="
        case births = "== Births =="
        case deaths = "== Deaths =="

        func toLanguage(_ language: String) -> String {
            if language == "en" { return en }
            if language == "ru" { return ru }
            return en
        }

        // swiftlint:disable:next identifier_name
        private var en: String {
            switch self {
            case .events: return "== Events =="
            case .births: return "== Births =="
            case .deaths: return "== Deaths =="
            }
        }

        // swiftlint:disable:next identifier_name
        private var ru: String {
            switch self {
            case .events: return "== События =="
            case .births: return "== Родились =="
            case .deaths: return "== Скончались =="
            }
        }
    }

    private let language: String

    init(language: String) {
        self.language = language
    }

    func cleanExtract(from extract: String) -> String {
        AppLogger.shared.debug("Cleaning extract by removing subcategories and unwanted symbols", category: .parser)

        let cleanedLines = extract
            .components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter {
                !$0.isEmpty && !$0.hasPrefix("===") && !$0.hasSuffix(":") && !$0.hasPrefix("-")
            }

        AppLogger.shared.debug("Finished cleaning extract", category: .parser)
        return cleanedLines.joined(separator: "\n")
    }

    func parseWikipediaDay(from extract: String) throws -> DayNetworkModel {
        AppLogger.shared.debug("Parsing Wikipedia day from extract", category: .parser)

        let cleanedExtract = cleanExtract(from: extract)

        guard let introRange = cleanedExtract.range(of: "==") else {
            AppLogger.shared.error("No section headings found in Wikipedia extract", category: .parser)
            throw DecodingError.dataCorrupted(
                .init(codingPath: [], debugDescription: "No section headings found in the Wikipedia extract."))
        }

        let introText = String(cleanedExtract[..<introRange.lowerBound])
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let parsedCategories = Category.allCases
            .reduce(into: [Category: [EventNetworkModel]]()) { result, category in
                result[category] = parseCategory(from: cleanedExtract, category: category)
            }

        return DayNetworkModel(
            text: introText,
            general: parsedCategories[.events] ?? [],
            births: parsedCategories[.births] ?? [],
            deaths: parsedCategories[.deaths] ?? []
        )
    }

    func parseCategory(from extract: String, category: Category) -> [EventNetworkModel] {
        let categoryString = category.toLanguage(language)
        AppLogger.shared.debug("Parsing category: \(categoryString)", category: .parser)

        guard let categoryText = rawCategory(from: extract, for: category) else {
            AppLogger.shared.info("No \(categoryString) section found in Wikipedia extract", category: .parser)
            return []
        }

        let lines = categoryText.components(separatedBy: "\n")

        let separator: Character = language == "en" ? "–" : "—"
        let yearPattern = language == "en" ? "^[0-9]{1,4}( BC)?$"
                                           : "^[0-9]{1,4}( до н\\. э\\.)?$"
        var events: [EventNetworkModel] = []
        var currentYear: String?

        for line in lines {
            let cleanedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)

            // skip if the line is empty
            guard !cleanedLine.isEmpty else { continue }

            // check if possible to parse "year - text"
            if let separator = cleanedLine.firstIndex(of: separator) {
                let potentialYear = cleanedLine.prefix(upTo: separator).trimmingCharacters(in: .whitespacesAndNewlines)
                let eventText = cleanedLine
                    .suffix(from: cleanedLine.index(after: separator))
                    .trimmingCharacters(in: .whitespacesAndNewlines)

                // check if the beginning of the string matches the year
                if potentialYear.range(of: yearPattern, options: .regularExpression) != nil {
                    currentYear = potentialYear
                    events.append(model(year: potentialYear, text: eventText, category: category))
                    continue
                }
            }

            // check if the line is only the year
            if cleanedLine.range(of: yearPattern, options: .regularExpression) != nil {
                currentYear = cleanedLine
            } else if let year = currentYear {
                events.append(model(year: year, text: cleanedLine, category: category))
            }
        }

        return events
    }

    func rawCategory(from extract: String, for category: Category) -> String? {
        let categoryString = category.toLanguage(language)

        // find the beegining of the current category
        guard let categoryRange = extract.range(of: categoryString) else {
            AppLogger.shared.info("No \(categoryString) section found in Wikipedia extract", category: .parser)
            return nil
        }

        let remainingText = extract[categoryRange.upperBound...]

        // find the beginning of the next category or the end of the text
        let nextCategoryRange = remainingText.range(of: "== ") ?? remainingText.endIndex..<remainingText.endIndex

        return String(remainingText[..<nextCategoryRange.lowerBound])
    }

    func model(year: String, text: String, category: Category) -> EventNetworkModel {
        if category == .events {
            shortModel(year: year, text: text)
        } else {
            extendedModel(year: year, text: text)
        }
    }

    func shortModel(year: String, text: String) -> EventNetworkModel {
        EventNetworkModel(year: year, title: text.capitalizedFirstLetter())
    }

    func extendedModel(year: String, text: String) -> EventNetworkModel {
        if let commaIndex = text.firstIndex(of: ",") {
            let titlePart = text[..<commaIndex].trimmingCharacters(in: .whitespacesAndNewlines)
            let additionalPart = text[text.index(after: commaIndex)...]
                .trimmingCharacters(in: .whitespacesAndNewlines)
            return EventNetworkModel(year: year,
                                     title: String(titlePart).capitalizedFirstLetter(),
                                     additional: String(additionalPart).capitalizedFirstLetter())
        } else {
            return shortModel(year: year, text: text)
        }
    }
}
