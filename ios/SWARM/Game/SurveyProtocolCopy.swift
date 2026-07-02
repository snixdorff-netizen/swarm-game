// Survey protocol vocabulary — field-facing strings (P0 trust wave).

import Foundation

enum SurveyProtocolCopy {
    static let noiseBudgetLabel = "Noise budget"
    static let detectionsLabel = "Detections"
    static let rankLabel = "Survey rank"
    static let deploymentAborted = "DEPLOYMENT ABORTED"
    static let transectComplete = "TRANSECT COMPLETE"
    static let missionPassed = "MISSION PASSED"
    static let missionIncomplete = "MISSION INCOMPLETE"
    static let validated = "Validated"
    static let tentative = "Tentative ID"
    static let autoIdAccepted = "Auto-ID accepted"
    static let manualIdConfirmed = "Manual ID confirmed"
    static let manualIdRejected = "Rejected (noise)"
    static let needsReview = "Needs review"
    static let presencePresent = "Present"
    static let presenceTentative = "Tentative"
    static let presenceInsufficient = "Insufficient evidence"
    static let conservativeClassifier = "+1 Conservative classifier"
    static let presenceAbsenceHeader = "Presence / absence"
    static let presenceAbsenceNightCard = "Presence / absence — night card"
    static let presenceAbsenceNightCardCSVHeader = "presence_absence_night_card"
    static let analystBacklogLabel = "Analyst backlog"
}