import XCTest

final class CatalogUITests: XCTestCase {
    func testFranchisePickerAndLiveActivity() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-lcars.motion", "NO"]
        app.launch()
        let picker = app.buttons["Change franchise"].firstMatch
        XCTAssertTrue(picker.waitForExistence(timeout: 10))
        picker.tap()
        let voyager = app.buttons["Voyager"].firstMatch
        XCTAssertTrue(voyager.waitForExistence(timeout: 5), app.debugDescription)
        voyager.tap()
        let changedTheme = NSPredicate(format: "value == %@", "Voyager")
        expectation(for: changedTheme, evaluatedWith: picker)
        waitForExpectations(timeout: 5)

        let start = app.buttons["Start Live Activity"].firstMatch
        let end = app.buttons["End Live Activity"].firstMatch
        if end.exists {
            end.tap()
            XCTAssertTrue(start.waitForExistence(timeout: 10))
        }
        XCTAssertTrue(start.exists)
        start.tap()
        XCTAssertTrue(end.waitForExistence(timeout: 10), app.debugDescription)
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = "Live Activity started"
        attachment.lifetime = .keepAlways
        add(attachment)
        XCUIDevice.shared.press(.home)
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        XCTAssertTrue(springboard.wait(for: .runningForeground, timeout: 5))
        let island = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        island.name = "Dynamic Island on Home Screen"
        island.lifetime = .keepAlways
        add(island)
        let activity = springboard.otherElements.matching(NSPredicate(format: "label == %@", "LCARS, Voyager")).firstMatch
        XCTAssertTrue(activity.waitForExistence(timeout: 10), springboard.debugDescription)
        activity.tap()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10))
        let classic = app.buttons["Classic / TNG"].firstMatch
        XCTAssertTrue(classic.waitForExistence(timeout: 10), app.debugDescription)
        classic.tap()
        expectation(for: NSPredicate(format: "value == %@", "Classic / TNG"), evaluatedWith: picker)
        waitForExpectations(timeout: 5)
        end.tap()
        XCTAssertTrue(app.buttons["Start Live Activity"].firstMatch.waitForExistence(timeout: 10), app.debugDescription)
    }
}
