import XCTest

final class ChatUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testSendMessageToInboxShowsAndPersists() throws {
        let app = launch(reset: true)
        XCTAssertTrue(app.buttons["chatRow-Inbox"].waitForExistence(timeout: 10))
        XCTAssertEqual(app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'chatRow-'")).count, 1,
                       "Reset must leave only the Inbox chat")
        openChat("Inbox", in: app)

        let input = app.descendants(matching: .any).matching(identifier: "messageInput").firstMatch
        let sendButton = app.buttons["sendButton"]
        XCTAssertTrue(input.waitForExistence(timeout: 10), "Message input not found")
        XCTAssertFalse(sendButton.isEnabled, "Send must be disabled for empty input")

        let text = "Hello from XCUITest"
        input.tap()
        input.typeText(text)
        XCTAssertTrue(sendButton.isEnabled)
        sendButton.tap()

        let bubble = app.staticTexts.matching(NSPredicate(format: "label == %@", text)).firstMatch
        XCTAssertTrue(bubble.waitForExistence(timeout: 5), "Sent message not shown in chat")
        attachScreenshot(of: app, name: "After send")

        // Relaunch without reset: the message must come back from storage.
        app.terminate()
        let relaunched = launch(reset: false)
        let preview = relaunched.staticTexts.matching(NSPredicate(format: "label == %@", text)).firstMatch
        XCTAssertTrue(preview.waitForExistence(timeout: 10), "Last message not shown in chat list after relaunch")
        attachScreenshot(of: relaunched, name: "Chat list after relaunch")
        openChat("Inbox", in: relaunched)
        XCTAssertTrue(bubble.waitForExistence(timeout: 5), "Message not restored after relaunch")
    }

    @MainActor
    func testWhitespaceOnlyMessageCannotBeSent() throws {
        let app = launch(reset: true)
        openChat("Inbox", in: app)

        let input = app.descendants(matching: .any).matching(identifier: "messageInput").firstMatch
        XCTAssertTrue(input.waitForExistence(timeout: 10))
        input.tap()
        input.typeText("   ")
        XCTAssertFalse(app.buttons["sendButton"].isEnabled)
    }

    @MainActor
    func testCreateChatAndSearch() throws {
        let app = launch(reset: true)
        app.buttons["newChatButton"].tap()
        let title = app.alerts.textFields.firstMatch
        XCTAssertTrue(title.waitForExistence(timeout: 5))
        title.typeText("Sport")
        app.alerts.buttons["Create"].tap()

        // Creating a chat opens it.
        XCTAssertTrue(app.descendants(matching: .any)["messageInput"].waitForExistence(timeout: 5))
        app.navigationBars.buttons["Chats"].tap()

        let inboxRow = app.buttons["chatRow-Inbox"]
        let sportRow = app.buttons["chatRow-Sport"]
        XCTAssertTrue(sportRow.waitForExistence(timeout: 5))
        XCTAssertTrue(inboxRow.exists)

        let search = app.searchFields.firstMatch
        search.tap()
        search.typeText("spo")
        XCTAssertTrue(sportRow.waitForExistence(timeout: 5))
        XCTAssertFalse(inboxRow.exists, "Search must hide chats that do not match")
        attachScreenshot(of: app, name: "Search")
    }

    @MainActor
    func testSettingsShowsAboutAndExport() throws {
        let app = launch(reset: true)
        app.buttons["settingsButton"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["exportMarkdown"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.descendants(matching: .any)["exportJSON"].exists)
        let author = app.descendants(matching: .any)
            .matching(NSPredicate(format: "label CONTAINS %@", "Mikhail Laptev")).firstMatch
        XCTAssertTrue(author.exists, "Author not shown in About")
        attachScreenshot(of: app, name: "Settings")
    }

    @MainActor
    private func launch(reset: Bool) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = reset ? ["-resetStorage"] : []
        app.launch()
        return app
    }

    @MainActor
    private func openChat(_ title: String, in app: XCUIApplication) {
        let row = app.buttons["chatRow-\(title)"]
        XCTAssertTrue(row.waitForExistence(timeout: 10), "Chat \(title) not in list")
        row.tap()
    }

    @MainActor
    private func attachScreenshot(of app: XCUIApplication, name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
