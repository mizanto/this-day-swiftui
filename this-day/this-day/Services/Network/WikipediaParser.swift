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
        case holidays = "== Holidays and observances =="
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
            deaths: parsedCategories[.deaths] ?? [],
            holidays: parsedCategories[.holidays] ?? []
        )
    }

    func parseCategory(from extract: String, category: Category) -> [EventNetworkModel] {
        AppLogger.shared.debug("Parsing category: \(category.rawValue)", category: .parser)

        // Find the start of the category
        guard let categoryRange = extract.range(of: category.rawValue) else {
            AppLogger.shared.info("No \(category.rawValue) section found in Wikipedia extract", category: .parser)
            return []
        }

        // Find the end of the category — either the start of the next category or the end of the text
        let remainingText = extract[categoryRange.upperBound...]

        // Find the range of the next category or the end of the text if no further category exists
        let nextCategoryRange = remainingText.range(of: "== ") ?? remainingText.endIndex..<remainingText.endIndex

        let categoryText = remainingText[..<nextCategoryRange.lowerBound]

        // Split the category text into lines
        let lines = categoryText.components(separatedBy: "\n")

        return lines.compactMap { line -> EventNetworkModel? in
            let cleanedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            return convertToModel(from: cleanedLine, category: category)
        }
    }

    func convertToModel(from line: String, category: Category) -> EventNetworkModel? {
        guard !line.isEmpty else { return nil }

        let components = line.split(separator: "–", maxSplits: 1)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

        guard components.count == 2 else {
            return category == .events || category == .holidays ? EventNetworkModel(title: line) : nil
        }

        let year = components[0]
        let title = components[1]

        if category == .births || category == .deaths, let commaIndex = title.firstIndex(of: ",") {
            let titlePart = title[..<commaIndex].trimmingCharacters(in: .whitespacesAndNewlines)
            let additionalPart = title[title.index(after: commaIndex)...]
                .trimmingCharacters(in: .whitespacesAndNewlines)
            return EventNetworkModel(year: year, title: String(titlePart), additional: String(additionalPart))
        }

        return EventNetworkModel(year: year, title: title)
    }
}
