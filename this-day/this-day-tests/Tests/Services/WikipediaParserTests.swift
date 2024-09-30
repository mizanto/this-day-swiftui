//
//  WikipediaParserTests.swift
//  this-day-tests
//
//  Created by Sergey Bendak on 23.09.2024.
//

import XCTest

@testable import this_day

final class WikipediaParserTests: XCTestCase {
    
    private var parser: WikipediaParser!
    
    override func setUp() {
        super.setUp()
        parser = WikipediaParser(language: "en")
    }
    
    override func tearDown() {
        parser = nil
        super.tearDown()
    }
    
    func testCleanExtractRemovesSubcategoriesAndUnwantedSymbols() {
        let input = """
        === Subcategory ===
        - First Event
        Real Event
        Ending with colon:
        """
        let result = parser.cleanExtract(from: input)
        
        XCTAssertEqual(result, "Real Event")
    }
    
    func testCleanExtractHandlesEmptyInput() {
        let input = ""
        let result = parser.cleanExtract(from: input)
        
        XCTAssertTrue(result.isEmpty)
    }
    
    // Test the parseWikipediaDay method
    func testParseWikipediaDaySuccessfulParsing() throws {
        let input = """
        Introduction text
        == Events ==
        1912 – Titanic sinks.
        == Births ==
        1890 – Papa Jack Laine, American drummer and bandleader (d. 1966)
        == Deaths ==
        1966 – A famous person, an important figure (b. 1890)
        == Holidays and observances ==
        National Cake Day
        """
        
        let result = try parser.parseWikipediaDay(from: input)
        
        XCTAssertEqual(result.text, "Introduction text")
        
        XCTAssertEqual(result.general.count, 1)
        XCTAssertEqual(result.general.first?.year, "1912")
        XCTAssertEqual(result.general.first?.title, "Titanic sinks.")
        
        XCTAssertEqual(result.births.count, 1)
        XCTAssertEqual(result.births.first?.year, "1890")
        XCTAssertEqual(result.births.first?.title, "Papa Jack Laine")
        XCTAssertEqual(result.births.first?.additional, "American drummer and bandleader (d. 1966)")
        
        XCTAssertEqual(result.deaths.count, 1)
        XCTAssertEqual(result.deaths.first?.year, "1966")
        XCTAssertEqual(result.deaths.first?.title, "A famous person")
        XCTAssertEqual(result.deaths.first?.additional, "An important figure (b. 1890)")
    }
    
    func testParseWikipediaDayNoSectionHeadings() {
        let input = "This is just some random text without any section headings."
        
        XCTAssertThrowsError(try parser.parseWikipediaDay(from: input)) { error in
            guard case DecodingError.dataCorrupted(let context) = error else {
                XCTFail("Expected a dataCorrupted error")
                return
            }
            XCTAssertEqual(context.debugDescription, "No section headings found in the Wikipedia extract.")
        }
    }
    
    // Test the parseCategory method
    func testParseCategoryNoCategoryFound() {
        let input = "Some text without the category."
        
        let result = parser.parseCategory(from: input, category: .events)
        
        XCTAssertTrue(result.isEmpty)
    }
    
    func testParseCategoryHandlesValidCategory() {
        let input = """
        == Events ==
        1945 – End of World War II.
        """
        
        let result = parser.parseCategory(from: input, category: .events)
        
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.year, "1945")
        XCTAssertEqual(result.first?.title, "End of World War II.")
    }
    
    func testParseCategoryMultipleEventsForDate() {
        let input = """
        == Events ==
        1945
        Event 1
        event 2
        """
        
        let result = parser.parseCategory(from: input, category: .events)
        
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result[0].year, "1945")
        XCTAssertEqual(result[0].title, "Event 1")
        XCTAssertEqual(result[1].year, "1945")
        XCTAssertEqual(result[1].title, "Event 2")
    }
    
    func testConvertToModelEventWithYearAndTitle() {
        let result = parser.shortModel(year: "1947", text: "Independence of India")
        
        XCTAssertEqual(result.year, "1947")
        XCTAssertEqual(result.title, "Independence of India")
        XCTAssertNil(result.additional)
    }
    
    func testConvertToModelBirthOrDeathEvent() {
        let result = parser.extendedModel(year: "1890", text: "Famous Person, known for something special (d. 1966)")
        
        XCTAssertEqual(result.year, "1890")
        XCTAssertEqual(result.title, "Famous Person")
        XCTAssertEqual(result.additional, "Known for something special (d. 1966)")
    }
}
