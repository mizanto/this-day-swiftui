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
        parser = WikipediaParser()
    }
    
    override func tearDown() {
        parser = nil
        super.tearDown()
    }
    
    // Test the cleanExtract method
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
        XCTAssertEqual(result.deaths.first?.additional, "an important figure (b. 1890)")
        
        XCTAssertEqual(result.holidays.count, 1)
        XCTAssertEqual(result.holidays.first?.title, "National Cake Day")
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
    
    // Test convertToModel method
    func testConvertToModelEventWithoutYear() {
        let line = "Event without year"
        let result = parser.convertToModel(from: line, category: .events)
        
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.title, "Event without year")
        XCTAssertNil(result?.year)
        XCTAssertNil(result?.additional)
    }
    
    func testConvertToModelEventWithYearAndTitle() {
        let line = "1947 – Independence of India"
        let result = parser.convertToModel(from: line, category: .events)
        
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.year, "1947")
        XCTAssertEqual(result?.title, "Independence of India")
        XCTAssertNil(result?.additional)
    }
    
    func testConvertToModelBirthOrDeathEvent() {
        let line = "1890 – Famous Person, known for something special (d. 1966)"
        let result = parser.convertToModel(from: line, category: .births)
        
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.year, "1890")
        XCTAssertEqual(result?.title, "Famous Person")
        XCTAssertEqual(result?.additional, "known for something special (d. 1966)")
    }
    
    func testConvertToModelIgnoresInvalidLineForBirths() {
        let line = "Just some random text without separator"
        let result = parser.convertToModel(from: line, category: .births)
        
        XCTAssertNil(result)
    }
}
