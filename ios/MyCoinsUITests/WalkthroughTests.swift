import XCTest

/// Walks the app the way a new user would — make an account, open a coin,
/// visit every tab — and keeps a screenshot of each screen.
///
/// Less a test of behaviour than a way to *look* at the app without a hand
/// on the simulator: the assertions are only that each screen it expects is
/// reached. The pictures and a dump of each screen's elements go to
/// `$SHOTS_DIR` when it is set (pass `TEST_RUNNER_SHOTS_DIR=…` to
/// `xcodebuild test`), and are attached to the test result either way.
///
/// Run it against a Release build: that one carries its JavaScript, so no
/// Metro server has to be up.
final class WalkthroughTests: XCTestCase {

    private var app: XCUIApplication!
    private var step = 0
    private let password = "walkthrough-pass-1"

    override func setUp() {
        continueAfterFailure = true
        app = XCUIApplication()
    }

    private func snap(_ name: String) {
        step += 1
        let label = String(format: "%02d-%@", step, name)
        let shot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: shot)
        attachment.name = label
        attachment.lifetime = .keepAlways
        add(attachment)
        guard let dir = ProcessInfo.processInfo.environment["SHOTS_DIR"], !dir.isEmpty else { return }
        let base = URL(fileURLWithPath: dir)
        try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        try? shot.pngRepresentation.write(to: base.appendingPathComponent(label + ".png"))
        try? app.debugDescription.write(
            to: base.appendingPathComponent(label + ".txt"), atomically: true, encoding: .utf8
        )
    }

    /// React Native gives a touchable the label of the text inside it, and a
    /// tab the label "Keys, tab, 1 of 5": match on how the label starts.
    private func element(_ label: String) -> XCUIElement {
        let match = NSPredicate(format: "label ==[c] %@ OR label BEGINSWITH[c] %@", label, label + ",")
        // A screen's title can carry the same words as its button ("Create
        // Account"): prefer the touchable, which React Native exposes as a
        // button or as a plain element, over the text.
        let button = app.buttons.matching(match).firstMatch
        if button.exists { return button }
        let touchable = app.otherElements.matching(match).firstMatch
        if touchable.exists { return touchable }
        return app.descendants(matching: .any).matching(match).firstMatch
    }

    @discardableResult
    private func tap(_ label: String, timeout: TimeInterval = 10, file: StaticString = #filePath, line: UInt = #line) -> Bool {
        let target = element(label)
        guard target.waitForExistence(timeout: timeout) else {
            XCTFail("no \"\(label)\" to tap", file: file, line: line)
            return false
        }
        target.tap()
        return true
    }

    private func expect(_ label: String, _ what: String, timeout: TimeInterval = 20) {
        XCTAssertTrue(element(label).waitForExistence(timeout: timeout), what)
    }

    /// Dismiss whatever alert is up (the backup reminder, a network error).
    private func dismissAlerts() {
        for _ in 0..<3 {
            let alert = app.alerts.firstMatch
            guard alert.waitForExistence(timeout: 2) else { return }
            snap("alert")
            alert.buttons.element(boundBy: 0).tap()
        }
    }

    /// Log in, creating the account on a fresh install.
    private func reachHome() {
        XCTAssertTrue(element("Login").waitForExistence(timeout: 30), "the login screen")
        snap("login")
        tap("Create New Account")
        expect("Back to Login", "the create-account screen")
        let fields = app.secureTextFields
        fields.element(boundBy: 0).tap()
        fields.element(boundBy: 0).typeText(password)
        fields.element(boundBy: 1).tap()
        fields.element(boundBy: 1).typeText(password)
        snap("create-account")
        tap("Create Account")
        dismissAlerts()
        expect("Coins", "the coins page", timeout: 40)
    }

    func testWalkthrough() {
        app.launch()
        reachHome()
        snap("coins")

        tap("FCH")
        snap("coin-detail")
        tap("Receive")
        snap("receive")
        tap("Back")
        tap("Send")
        snap("send")
        // The amount field sits low on the form: with the keyboard up it
        // must still be on screen.
        let amount = app.textFields.element(boundBy: 1)
        if amount.waitForExistence(timeout: 5) {
            amount.tap()
            amount.typeText("1")
            snap("send-keyboard")
            // The number pad has no Done key and covers the tab bar:
            // dragging the form is how it is put away.
            app.swipeDown()
            snap("send-keyboard-gone")
        }
        tap("Back")
        tap("Back")

        // Keys has no tab: it opens from the floating FID chip ("FJiAVZ...ykJpy3").
        let chip = app.otherElements.matching(
            NSPredicate(format: "label MATCHES %@", "^\\w{6}\\.\\.\\.\\w{6}$")
        ).firstMatch
        XCTAssertTrue(chip.waitForExistence(timeout: 10), "the FID chip")
        chip.tap()
        snap("keys")
        tap("+ Add Key")
        snap("add-key")
        tap("Back")

        tap("Swap")
        snap("swap")

        tap("Settings")
        snap("settings")
        app.swipeUp()
        snap("settings-lower")
        app.swipeUp()
        snap("settings-bottom")
    }
}
