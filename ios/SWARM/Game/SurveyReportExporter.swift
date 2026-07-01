// Survey report text + CSV export (P1 — paper-figure fantasy).

import Foundation

enum SurveyReportExporter {
    static func textReport(_ report: SurveyRunReport, deployMode: DeployMode) -> String {
        var lines: [String] = [
            "SWARM — Survey Report",
            "Mission: \(report.missionTitle)",
            "Recorder: \(deployMode.title)",
            "Transect duration: \(formatTime(report.timeSec))",
            "Survey score: \(report.surveyScore)",
            "Status: \(report.abortReason != nil ? SurveyProtocolCopy.deploymentAborted : (report.missionPassed ? SurveyProtocolCopy.missionPassed : SurveyProtocolCopy.missionIncomplete))",
            "",
            "Summary",
            "  Detections: \(report.detections)",
            "  Species richness: \(report.richness)",
            "  Mean confidence: \(Int(report.meanConfidence * 100))%",
            "  False positives: \(report.falsePositives)",
            "",
            "Detection vouchers",
        ]
        if report.vouchers.isEmpty {
            lines.append("  (none)")
        } else {
            for v in report.vouchers {
                let status = v.validated ? SurveyProtocolCopy.validated : SurveyProtocolCopy.tentative
                lines.append("  \(v.commonName) (\(v.scientificName)) — \(Int(v.confidence * 100))% — \(status) @ \(formatTime(v.timeSec))")
            }
        }
        lines.append("")
        lines.append(AcousticFieldCopy.tagline)
        return lines.joined(separator: "\n")
    }

    static func csvRows(_ report: SurveyRunReport, deployMode: DeployMode) -> String {
        var rows = [
            "mission_id,mission_title,recorder,time_sec,survey_score,mission_passed,detections,richness,mean_confidence,false_positives",
            "\(csv(report.missionId)),\(csv(report.missionTitle)),\(csv(deployMode.rawValue)),\(report.timeSec),\(report.surveyScore),\(report.missionPassed),\(report.detections),\(report.richness),\(String(format: "%.2f", report.meanConfidence)),\(report.falsePositives)",
            "species_id,common_name,scientific_name,confidence,time_sec,validated",
        ]
        for v in report.vouchers {
            rows.append("\(csv(v.speciesId)),\(csv(v.commonName)),\(csv(v.scientificName)),\(String(format: "%.2f", v.confidence)),\(v.timeSec),\(v.validated)")
        }
        return rows.joined(separator: "\n")
    }

    private static func formatTime(_ sec: Int) -> String {
        String(format: "%d:%02d", sec / 60, sec % 60)
    }

    private static func csv(_ value: String) -> String {
        if value.contains(",") || value.contains("\"") {
            return "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return value
    }
}