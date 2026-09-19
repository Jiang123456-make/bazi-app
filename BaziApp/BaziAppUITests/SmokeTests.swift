import XCTest

/// 灵犀真机（模拟器）冒烟测试：
/// 实际启动 App → 试排示例（自动排盘并跳转命盘页）→ 返回 → 报告 → 顾问（键盘陷阱验证）
/// → 我的（自检 490/490）→ 词典。逐屏截图存 /tmp/lingxi-shots，CI 上传为 artifacts。
final class SmokeTests: XCTestCase {

    private func shot(_ app: XCUIApplication, _ name: String) {
        let s = XCUIScreen.main.screenshot()
        let dir = "/tmp/lingxi-shots"
        try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        try? s.pngRepresentation.write(to: URL(fileURLWithPath: "\(dir)/\(name).png"))
    }

    @MainActor
    func testFullWalkthrough() throws {
        let app = XCUIApplication()
        app.launch()

        // ① 排盘页
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 10), "App 应启动并显示 TabBar")
        shot(app, "01-排盘页")

        // ② 一键试排示例（loadDemo 会自动生成并跳转命盘页）
        let demo = app.buttons.matching(NSPredicate(format: "label CONTAINS '试排示例'")).firstMatch
        XCTAssertTrue(demo.waitForExistence(timeout: 5), "应有「试排示例」按钮")
        demo.tap()
        sleep(3)
        shot(app, "02-命盘页")

        // ③ 从命盘页返回排盘输入页
        let back = app.navigationBars.buttons.firstMatch
        if back.waitForExistence(timeout: 5) {
            back.tap()
            sleep(1)
        }
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 5), "返回后 TabBar 应可见")
        shot(app, "03-返回排盘页")

        // ④ 报告页
        let reportTab = app.tabBars.buttons["报告"]
        XCTAssertTrue(reportTab.waitForExistence(timeout: 5))
        reportTab.tap()
        sleep(3)
        shot(app, "04-报告页")

        // ⑤ 顾问页 + 键盘陷阱验证
        app.tabBars.buttons["顾问"].tap()
        sleep(2)
        shot(app, "05-顾问页")
        let field = app.textFields["输入你的问题…"]
        if field.waitForExistence(timeout: 5) {
            field.tap()
            let kb = app.keyboards.firstMatch
            if kb.waitForExistence(timeout: 5) {
                shot(app, "06-键盘弹出")
                let done = app.buttons["完成"]
                if done.waitForExistence(timeout: 3) {
                    done.tap()
                }
                // 等键盘真正消失（最长 5 秒）
                let gone = expectation(for: NSPredicate(format: "exists == false"), evaluatedWith: kb)
                wait(for: [gone], timeout: 5)
                shot(app, "07-键盘收起后")
                XCTAssertFalse(kb.exists, "点「完成」后键盘应已收起")
                XCTAssertTrue(app.tabBars.buttons["我的"].isHittable, "tabBar 应可点（键盘陷阱修复验证）")
            }
        }

        // ⑥ 我的页：等后台自检跑完出 490/490
        app.tabBars.buttons["我的"].tap()
        let passed = app.staticTexts.matching(NSPredicate(format: "label CONTAINS '490'")).firstMatch
        _ = passed.waitForExistence(timeout: 120)
        shot(app, "08-我的-自检结果")
        XCTAssertTrue(passed.exists, "自检卡应出现 490/490（后台异步校验完成）")

        // ⑦ 词典入口打开
        let glossary = app.buttons.matching(NSPredicate(format: "label CONTAINS '术语词典'")).firstMatch
        if glossary.waitForExistence(timeout: 5) {
            glossary.tap()
            sleep(2)
            shot(app, "09-术语词典")
        }
    }
}
