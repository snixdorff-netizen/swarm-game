// Player-facing motivation copy — survey protocol tone.

import Foundation

enum EngagementCopy {
    static func deathLines(report: SurveyRunReport, isNewBestScore: Bool) -> (headline: String, subline: String) {
        if report.abortReason != nil {
            return (
                SurveyProtocolCopy.deploymentAborted,
                report.abortReason! + " · Score \(report.surveyScore) · " + report.scoreBreakdown
            )
        }
        if report.missionPassed {
            let head = isNewBestScore ? "NEW BEST SURVEY SCORE" : SurveyProtocolCopy.missionPassed
            return (head, "\(report.missionTitle) · Score \(report.surveyScore) · " + report.scoreBreakdown)
        }
        if report.timeSec >= 420 {
            return (
                SurveyProtocolCopy.transectComplete,
                SurveyProtocolCopy.missionIncomplete + " · Score \(report.surveyScore) · " + report.scoreBreakdown
            )
        }
        return (
            "DEPLOYMENT ENDED",
            "Score \(report.surveyScore) · " + report.scoreBreakdown
        )
    }

    static let firstRunSteps = AcousticFieldCopy.firstRunSteps
}