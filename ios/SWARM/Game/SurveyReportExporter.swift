// Survey report text + CSV export (P1 — paper-figure fantasy).

import Foundation

enum SurveyReportExporter {
    static func textReport(_ report: SurveyRunReport, deployMode: DeployMode) -> String {
        var lines: [String] = [
            "SWARM — Survey Report",
            "Deployment: \(report.deploymentId)",
            "Mission: \(report.missionTitle)",
            "Site: \(report.siteLabel)",
            "Recorder: \(report.recorderProfile)",
            "Transect mode: \(report.transectMode.title)",
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
            SurveyProtocolCopy.presenceAbsenceNightCard,
        ]
        if report.presenceRecords.isEmpty {
            lines.append("  (none)")
        } else {
            for record in report.presenceRecords {
                lines.append("  \(record.summaryLine)")
                lines.append("    validated: \(record.validatedPasses) · tentative: \(record.tentativePasses) · rejected: \(record.rejectedPasses)")
            }
        }
        lines.append("")
        lines.append("Detection vouchers")
        if report.vouchers.isEmpty {
            lines.append("  (none)")
        } else {
            for v in report.vouchers {
                lines.append("  \(v.commonName) (\(v.scientificName)) — \(Int(v.confidence * 100))% — \(v.vetStatus.label) @ \(formatTime(v.timeSec))")
                lines.append("    clip: \(v.clipFilename) · site: \(v.siteLabel) · \(v.recorderProfile)")
            }
        }
        lines.append("")
        lines.append(AcousticFieldCopy.tagline)
        return lines.joined(separator: "\n")
    }

    static func csvRows(_ report: SurveyRunReport, deployMode: DeployMode) -> String {
        var rows = [
            "deployment_id,mission_id,mission_title,site_label,recorder,transect_mode,time_sec,survey_score,mission_passed,detections,richness,mean_confidence,false_positives",
            "\(csv(report.deploymentId)),\(csv(report.missionId)),\(csv(report.missionTitle)),\(csv(report.siteLabel)),\(csv(report.recorderProfile)),\(csv(report.transectMode.rawValue)),\(report.timeSec),\(report.surveyScore),\(report.missionPassed),\(report.detections),\(report.richness),\(String(format: "%.2f", report.meanConfidence)),\(report.falsePositives)",
            "species_id,common_name,scientific_name,confidence,time_sec,auto_id,manual_id,vet_status,deployment_id,site_label,recorder_profile,clip_filename",
        ]
        for v in report.vouchers {
            rows.append([
                csv(v.speciesId), csv(v.commonName), csv(v.scientificName),
                String(format: "%.2f", v.confidence), "\(v.timeSec)",
                csv(v.vetStatus.autoIdColumn), csv(v.vetStatus.manualIdColumn), csv(v.vetStatus.rawValue),
                csv(v.deploymentId), csv(v.siteLabel), csv(v.recorderProfile), csv(v.clipFilename),
            ].joined(separator: ","))
        }
        rows.append("")
        rows.append(SurveyProtocolCopy.presenceAbsenceNightCardCSVHeader)
        rows.append("species_id,common_name,scientific_name,presence_status,validated_passes,tentative_passes,rejected_passes,mean_confidence")
        for record in report.presenceRecords {
            rows.append([
                csv(record.speciesId), csv(record.commonName), csv(record.scientificName),
                csv(record.status.rawValue), "\(record.validatedPasses)", "\(record.tentativePasses)",
                "\(record.rejectedPasses)", String(format: "%.2f", record.meanConfidence),
            ].joined(separator: ","))
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