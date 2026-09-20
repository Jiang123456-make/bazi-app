import XCTest

/// 灵犀真机（模拟器）冒烟测试：
/// 启动（首次引导）→ 试排示例（自动排盘并跳转命盘页）→ 返回 → 报告 → 顾问（键盘陷阱验证）
/// → 我的（自检 490/490 + 展开详情）→ 词典。逐屏截图存 /tmp/lingxi-shots，CI 上传为 artifacts。
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

        // ⓪ 首次启动引导（3 页）：跳过或走到最后
        let skip = app.buttons["跳过"]
        let start = app.buttons["开始使用"]
        if skip.waitForExistence(timeout: 5) {
            shot(app, "00-引导页")
            skip.tap()
            sleep(1)
        } else if start.exists {
            start.tap()
            sleep(1)
        }

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
                // 等键盘真正消失（最长 10 秒，云 runner 动画偶发偏慢）
                let gone = expectation(for: NSPredicate(format: "exists == false"), evaluatedWith: kb)
                wait(for: [gone], timeout: 10)
                shot(app, "07-键盘收起后")
                XCTAssertFalse(kb.exists, "点「完成」后键盘应已收起")
                XCTAssertTrue(app.tabBars.buttons["我的"].isHittable, "tabBar 应可点（键盘陷阱修复验证）")
            }
        }

        // ⑥ 我的页：后台自检出 490/490（功能入口 badge），展开详情查看
        app.tabBars.buttons["我的"].tap()
        let passed = app.staticTexts.matching(NSPredicate(format: "label CONTAINS '490/490'")).firstMatch
        _ = passed.waitForExistence(timeout: 120)
        shot(app, "08-我的-自检结果")
        XCTAssertTrue(passed.exists, "自检 badge 应出现 490/490（后台异步校验完成）")
        // 展开自检详情卡
        let checkEntry = app.buttons.matching(NSPredicate(format: "label CONTAINS '引擎自检'")).firstMatch
        if checkEntry.waitForExistence(timeout: 5) {
            checkEntry.tap()
            sleep(1)
            shot(app, "08b-自检详情展开")
        }

        // ⑦ 词典入口打开
        let glossary = app.buttons.matching(NSPredicate(format: "label CONTAINS '术语词典'")).firstMatch
        if glossary.waitForExistence(timeout: 5) {
            glossary.tap()
            sleep(2)
            shot(app, "09-术语词典")
        }
    }
}
