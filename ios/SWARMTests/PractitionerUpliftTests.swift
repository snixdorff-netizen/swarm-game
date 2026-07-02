import XCTest
@testable import SWARM

final class PractitionerUpliftTests: XCTestCase {
    func testEmitUpliftReportJSONForHarness() {
        let report = PractitionerUpliftEngine.computeUpliftReport()
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let data = try! encoder.encode(report)
        let json = String(data: data, encoding: .utf8)!
        print("UPLIFT_REPORT_JSON:\(json)")
        XCTAssertTrue(report.passesTarget)
    }
    func testComputeUpliftReportMeets15PercentTarget() {
        let report = PractitionerUpliftEngine.computeUpliftReport()
        XCTAssertTrue(report.passesTarget, report.summaryLine)
        XCTAssertGreaterThanOrEqual(report.liftPct, PractitionerUpliftEngine.targetLiftPct)
        XCTAssertEqual(report.baselineScore, 40, accuracy: 0.01)
        XCTAssertEqual(report.currentScore, 46, accuracy: 0.01)
    }

    func testAllP6CriteriaPassViaShippedProbes() {
        let p6 = PractitionerUpliftEngine.computeUpliftReport().criteria.filter { $0.wave == "P6" }
        XCTAssertEqual(p6.count, 4)
        XCTAssertTrue(p6.allSatisfy(\.pass), p6.filter { !$0.pass }.map(\.label).joined(separator: ", "))
    }

    func testAllP5BaselineCriteriaStillPass() {
        let p5 = PractitionerUpliftEngine.computeUpliftReport().criteria.filter { $0.wave == "P5" }
        XCTAssertEqual(p5.count, 4)
        XCTAssertTrue(p5.allSatisfy(\.pass))
    }

    func testUpliftReportSummaryIsDeterministic() {
        let a = PractitionerUpliftEngine.computeUpliftReport()
        let b = PractitionerUpliftEngine.computeUpliftReport()
        XCTAssertEqual(a, b)
        XCTAssertTrue(a.summaryLine.contains("lift=15.0%"))
    }
}