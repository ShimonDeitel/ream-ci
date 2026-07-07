import XCTest

final class ReamUITests: XCTestCase {
    private var interruptionMonitorToken: NSObjectProtocol?

    override func setUpWithError() throws {
        continueAfterFailure = false
        interruptionMonitorToken = addUIInterruptionMonitor(withDescription: "System alert dismissal") { alert in
            for label in ["Allow", "OK", "Don't Allow", "Cancel"] {
                let button = alert.buttons[label]
                if button.exists {
                    button.tap()
                    return true
                }
            }
            return false
        }
    }

    override func tearDownWithError() throws {
        if let token = interruptionMonitorToken {
            removeUIInterruptionMonitor(token)
        }
    }

    private func launchApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTestReset"]
        app.launch()
        return app
    }

    func testHomeShowsSeededSupplies() throws {
        let app = launchApp()
        XCTAssertTrue(app.buttons["supplyNameLabel_No. 2 Pencils"].waitForExistence(timeout: 12))
        XCTAssertTrue(app.buttons["supplyNameLabel_Glue Stick"].waitForExistence(timeout: 12))
    }

    /// Quirky action + confirmation: tapping "Use" visibly shrinks the
    /// pencil/glue-stick bar and updates its percentage label.
    func testUseSupplyShrinksLevel() throws {
        let app = launchApp()
        let levelLabel = app.staticTexts["levelLabel_Glue Stick"]
        XCTAssertTrue(levelLabel.waitForExistence(timeout: 12))
        let before = levelLabel.label

        let useButton = app.buttons["useButton_Glue Stick"]
        XCTAssertTrue(useButton.waitForExistence(timeout: 8))
        useButton.tap()

        // Level label should change after using (30% -> 18%).
        let predicate = NSPredicate(format: "label != %@", before)
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: levelLabel)
        XCTAssertEqual(XCTWaiter().wait(for: [expectation], timeout: 8), .completed, "Level label did not change after Use tap")
    }

    func testRestockClearsRestockBadge() throws {
        let app = launchApp()
        // Glue Stick seeded at 0.3 with threshold 0.25 is NOT flagged yet;
        // use it once to push it under threshold, then restock it.
        let useButton = app.buttons["useButton_Glue Stick"]
        XCTAssertTrue(useButton.waitForExistence(timeout: 12))
        useButton.tap()
        useButton.tap()

        XCTAssertTrue(app.staticTexts["restockBadge_Glue Stick"].waitForExistence(timeout: 8), "Restock badge did not appear after depleting supply")

        app.buttons["restockButton_Glue Stick"].tap()

        XCTAssertFalse(app.staticTexts["restockBadge_Glue Stick"].waitForExistence(timeout: 6), "Restock badge still present after restocking")
    }

    func testAddSupplyFromHome() throws {
        let app = launchApp()
        let addButton = app.buttons["addSupplyButton"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 12))
        addButton.tap()

        let nameField = app.textFields["supplyNameField"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 12))
        nameField.tap()
        nameField.typeText("Notebook Paper")

        let saveButton = app.buttons["saveSupplyButton"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 8))
        saveButton.tap()

        XCTAssertTrue(app.buttons["supplyNameLabel_Notebook Paper"].waitForExistence(timeout: 12), "New supply did not appear")
    }

    func testEditSupplyChangesName() throws {
        let app = launchApp()
        let label = app.buttons["supplyNameLabel_No. 2 Pencils"]
        XCTAssertTrue(label.waitForExistence(timeout: 12))
        label.tap()

        let nameField = app.textFields["supplyNameField"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 12))
        nameField.tap()
        nameField.clearAndTypeText("Mechanical Pencils")

        app.buttons["saveSupplyButton"].tap()

        XCTAssertTrue(app.buttons["supplyNameLabel_Mechanical Pencils"].waitForExistence(timeout: 12), "Supply name did not update")
    }

    func testDeleteSupplyViaForm() throws {
        let app = launchApp()
        let label = app.buttons["supplyNameLabel_Glue Stick"]
        XCTAssertTrue(label.waitForExistence(timeout: 12))
        label.tap()

        let deleteButton = app.buttons["deleteSupplyButton"]
        XCTAssertTrue(deleteButton.waitForExistence(timeout: 8), "Delete button did not appear in edit form")
        // The Delete Supply button lives in the last Form section, below the
        // restock-threshold slider, and may not be scrolled into view yet even
        // though it already exists in the accessibility hierarchy — tapping a
        // non-hittable-but-existing element can silently no-op. Scroll it into
        // view first, matching the isHittable-guard pattern used elsewhere in
        // this file (see testFreeSupplyLimitTriggersPaywall).
        if !deleteButton.isHittable {
            app.swipeUp()
        }
        XCTAssertTrue(deleteButton.isHittable, "Delete button exists but is not hittable even after scrolling")
        deleteButton.tap()

        // Wait for the edit-supply sheet to actually finish dismissing before
        // checking the Home list — tapping Delete both mutates @Published items
        // and calls dismiss() in the same closure; if the check runs while the
        // sheet dismiss animation and the Combine-driven list re-render are still
        // settling, the stale element can still briefly satisfy existsNoRetry.
        let editFormNavBar = app.navigationBars["Edit Supply"]
        let dismissedExpectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "exists == false"),
            object: editFormNavBar
        )
        _ = XCTWaiter.wait(for: [dismissedExpectation], timeout: 6)

        XCTAssertFalse(app.buttons["supplyNameLabel_Glue Stick"].waitForExistence(timeout: 6), "Supply was not deleted")
    }

    func testFreeSupplyLimitTriggersPaywall() throws {
        let app = launchApp()
        // Seed data already has 2 supplies (free limit is 5) — add 3 more to
        // reach the limit, then a 4th more to genuinely overflow it.
        for i in 0..<4 {
            let addButton = app.buttons["addSupplyButton"]
            XCTAssertTrue(addButton.waitForExistence(timeout: 12))
            if !addButton.isHittable {
                app.swipeDown()
            }
            addButton.tap()

            let nameField = app.textFields["supplyNameField"]
            if nameField.waitForExistence(timeout: 6) {
                nameField.tap()
                nameField.typeText("Extra Item \(i)")
                app.buttons["saveSupplyButton"].tap()
            } else {
                break
            }
        }

        // At this point 6 supplies would exceed the free limit of 5, so the
        // add attempt should have opened the paywall instead of a form.
        XCTAssertTrue(app.staticTexts["Ream Pro"].waitForExistence(timeout: 12), "Paywall did not appear after exceeding the free supply limit")
    }

    func testFreeKidLimitTriggersPaywall() throws {
        let app = launchApp()
        // Seed data already has 1 kid (free limit is 1) — adding a second
        // kid must show the paywall instead of the add-kid form.
        let addKidButton = app.buttons["addKidButton"]
        XCTAssertTrue(addKidButton.waitForExistence(timeout: 12))
        addKidButton.tap()

        XCTAssertTrue(app.staticTexts["Ream Pro"].waitForExistence(timeout: 12), "Paywall did not appear after hitting the free kid limit")
    }
}

private extension XCUIElement {
    func clearAndTypeText(_ text: String) {
        guard let stringValue = self.value as? String, !stringValue.isEmpty else {
            typeText(text)
            return
        }
        self.press(forDuration: 1.0)
        typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: stringValue.count))
        typeText(text)
    }
}
