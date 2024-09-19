//
//  WikiParser.swift
//  this-day
//
//  Created by Sergey Bendak on 19.09.2024.
//

import Foundation

final class WikiParser {
    
    // Enum for categories
    enum Category: String, CaseIterable {
        case events = "== Events =="
        case births = "== Births =="
        case deaths = "== Deaths =="
        case holidays = "== Holidays and observances =="
    }

    func cleanExtract(from extract: String) -> String {
        AppLogger.shared.debug("Cleaning extract by removing subcategories and unwanted symbols", category: .parser)

        // Split the text into lines
        let lines = extract.components(separatedBy: "\n")
        
        var cleanedLines: [String] = []
        
        for line in lines {
            // Skip lines that are subcategories (surrounded by ===)
            if line.contains("===") {
                continue
            }
            
            // Remove the "-" symbol at the start of the line
            let cleanedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: "^-", with: "", options: .regularExpression)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Add the cleaned line to the array if it's not empty
            if !cleanedLine.isEmpty {
                cleanedLines.append(cleanedLine)
            }
        }
        
        // Join the cleaned lines back into a single string
        let cleanedExtract = cleanedLines.joined(separator: "\n")
        AppLogger.shared.debug("Finished cleaning extract", category: .parser)

        return cleanedExtract
    }
    
    func parseWikipediaDay(from extract: String) throws -> WikipediaDay {
        AppLogger.shared.debug("Parsing Wikipedia day from extract", category: .parser)

        // Clean the text before parsing
        let cleanedExtract = cleanExtract(from: extract)

        // Extract the main text before the first category
        let introRange = cleanedExtract.range(of: "==")
        guard let introRange else {
            AppLogger.shared.error("No section headings found in Wikipedia extract", category: .parser)
            let context = DecodingError.Context(codingPath: [],
                                                debugDescription: "No section headings found in the Wikipedia extract.")
            throw DecodingError.dataCorrupted(context)
        }
        let introText = String(cleanedExtract[..<introRange.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)

        // Parse categories using the enum
        let events = parseCategory(from: cleanedExtract, category: .events)
        let births = parseCategory(from: cleanedExtract, category: .births)
        let deaths = parseCategory(from: cleanedExtract, category: .deaths)
        let holidays = parseCategory(from: cleanedExtract, category: .holidays)

        // Create a WikipediaDay model
        return WikipediaDay(text: introText, events: events, births: births, deaths: deaths, holidays: holidays)
    }

    func parseCategory(from extract: String, category: Category) -> [WikipediaEvent] {
        AppLogger.shared.debug("Parsing category: \(category.rawValue)", category: .parser)

        // Find the start of the category
        guard let categoryRange = extract.range(of: category.rawValue) else {
            AppLogger.shared.info("No \(category.rawValue) section found in Wikipedia extract", category: .parser)
            return []
        }

        // Find the end of the category — either the start of the next category or the end of the text
        let remainingText = extract[categoryRange.upperBound...]
        let nextCategoryRange = remainingText.range(of: "== ")

        let categoryText: Substring
        if let nextRange = nextCategoryRange {
            categoryText = remainingText[..<nextRange.lowerBound]
        } else {
            categoryText = remainingText
        }

        // Split the category text into lines
        let lines = categoryText.components(separatedBy: "\n")

        // Parse non-empty lines as events or holidays
        return lines.compactMap { line -> WikipediaEvent? in
            let cleanedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Skip empty lines
            guard !cleanedLine.isEmpty else { return nil }
            
            // Check if the line contains an event or holiday description
            if let separatorRange = cleanedLine.range(of: " – ") {
                let title = String(cleanedLine[..<separatorRange.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
                let text = String(cleanedLine[separatorRange.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
                return WikipediaEvent(title: title, text: text)
            } else if !cleanedLine.contains("==") {
                // If no separator is found, treat the line as an event or holiday
                return WikipediaEvent(title: cleanedLine, text: "")
            }
            
            return nil
        }
    }
}
