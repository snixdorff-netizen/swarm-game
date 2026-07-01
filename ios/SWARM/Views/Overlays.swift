// SwiftUI overlays for SWARM: menu, level-up choice, game over.

import SwiftUI

enum SwarmTheme {
    static let bg = Color(red: 0.04, green: 0.04, blue: 0.07)
    static let cyan = Color(red: 0.20, green: 0.88, blue: 1.0)
    static let red = Color(red: 1.0, green: 0.30, blue: 0.42)
    static let lime = Color(red: 0.71, green: 1.0, blue: 0.36)
    static let foam = Color(white: 0.95)
    static func title(_ s: CGFloat) -> Font { .system(size: s, weight: .heavy, design: .rounded) }
    static func ui(_ s: CGFloat, _ w: Font.Weight = .semibold) -> Font { .system(size: s, weight: w, design: .rounded) }
}

private struct NeonButton: ButtonStyle {
    var tint: Color = SwarmTheme.cyan
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(SwarmTheme.ui(20, .bold))
            .foregroundColor(.black)
            .padding(.vertical, 16).padding(.horizontal, 30)
            .frame(maxWidth: .infinity)
            .background(tint)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: tint.opacity(0.6), radius: configuration.isPressed ? 4 : 12)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

struct MenuOverlay: View {
    @ObservedObject var model: GameModel
    @ObservedObject private var gameCenter = GameCenterManager.shared
    @AppStorage("swarm_seen_hint") private var seenHint = false

    var body: some View {
        ZStack {
            SwarmTheme.bg.opacity(0.88).ignoresSafeArea()
            VStack(spacing: 10) {
                HStack {
                    Spacer()
                    Button { model.openSettings() } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(SwarmTheme.foam.opacity(0.7))
                            .padding(12)
                    }
                    .accessibilityLabel("Settings")
                }
                .padding(.horizontal, 12)
                .padding(.top, 8)

                Spacer()
                Text("SWARM")
                    .font(SwarmTheme.title(76)).foregroundColor(SwarmTheme.cyan)
                    .tracking(6)
                    .shadow(color: SwarmTheme.cyan.opacity(0.7), radius: 18)
                Text(AcousticFieldCopy.subtitle)
                    .font(SwarmTheme.ui(16)).foregroundColor(SwarmTheme.foam.opacity(0.75))
                Text(AcousticFieldCopy.tagline)
                    .font(SwarmTheme.ui(14, .semibold)).foregroundColor(SwarmTheme.lime.opacity(0.85))
                HStack(spacing: 16) {
                    if model.bestSurveyScore > 0 {
                        Text("Best score: \(model.bestSurveyScore)")
                            .font(SwarmTheme.ui(14, .bold)).foregroundColor(SwarmTheme.lime)
                    }
                    Text("\(model.cores) \(AcousticFieldCopy.grantsLabel)")
                        .font(SwarmTheme.ui(14, .bold)).foregroundColor(SwarmTheme.cyan)
                }.padding(.top, 4)
                Text(gameCenter.statusLine)
                    .font(SwarmTheme.ui(11))
                    .foregroundColor(SwarmTheme.foam.opacity(gameCenter.isAvailable ? 0.45 : 0.3))
                if !gameCenter.syncStatusLine.isEmpty {
                    Text(gameCenter.syncStatusLine)
                        .font(SwarmTheme.ui(10))
                        .foregroundColor(SwarmTheme.lime.opacity(0.55))
                }
                Spacer()
                VStack(spacing: 14) {
                    if !seenHint {
                        FirstRunHint { seenHint = true }
                    }
                    HabitatSitePicker(selection: Binding(
                        get: { model.habitatSite },
                        set: { model.setHabitatSite($0) }
                    ))
                    TransectModePicker(selection: Binding(
                        get: { model.transectMode },
                        set: { model.setTransectMode($0) }
                    ))
                    DeployModePicker(selection: Binding(
                        get: { model.deployMode },
                        set: { model.setDeployMode($0) }
                    ))
                    Button(AcousticFieldCopy.deployButton) { model.start() }.buttonStyle(NeonButton())
                    Button("Lab Board") { model.openLabBoard() }.buttonStyle(NeonButton(tint: Color(white: 0.24)))
                    Button("Species Catalog") { model.openCatalog() }.buttonStyle(NeonButton(tint: Color(white: 0.26)))
                    Button(AcousticFieldCopy.fieldLabButton) { model.openMeta() }.buttonStyle(NeonButton(tint: Color(white: 0.22)))
                    if seenHint {
                        Text("Drag to move · classifiers scan automatically · IDs archive on confirm")
                            .font(SwarmTheme.ui(12)).foregroundColor(SwarmTheme.foam.opacity(0.5))
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.horizontal, 36).padding(.bottom, 48)
            }
        }
    }
}

private struct FirstRunHint: View {
    let onDismiss: () -> Void
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Field briefing")
                    .font(SwarmTheme.ui(14, .bold))
                    .foregroundColor(SwarmTheme.lime)
                Spacer()
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(SwarmTheme.foam.opacity(0.45))
                }
            }
            VStack(alignment: .leading, spacing: 4) {
                ForEach(Array(EngagementCopy.firstRunSteps.enumerated()), id: \.offset) { i, step in
                    Text("\(i + 1). \(step)")
                        .font(SwarmTheme.ui(11))
                        .foregroundColor(SwarmTheme.foam.opacity(0.75))
                }
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color(white: 0.12)))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(SwarmTheme.cyan.opacity(0.3), lineWidth: 1))
    }
}

struct LevelUpOverlay: View {
    @ObservedObject var model: GameModel
    var body: some View {
        ZStack {
            Color.black.opacity(0.62).ignoresSafeArea()
            VStack(spacing: 16) {
                Text("RANK \(model.level)")
                    .font(SwarmTheme.title(40)).foregroundColor(SwarmTheme.lime)
                    .shadow(color: SwarmTheme.lime.opacity(0.6), radius: 12)
                Text("New kit module — expand your survey rig")
                    .font(SwarmTheme.ui(15)).foregroundColor(SwarmTheme.foam.opacity(0.7))
                VStack(spacing: 12) {
                    ForEach(model.choices) { c in
                        Button { model.pick(c.id) } label: { ChoiceCard(card: c) }
                            .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 22)
            }
        }
    }
}

private struct ChoiceCard: View {
    let card: UpgradeCard
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12).fill(SwarmTheme.cyan.opacity(0.16)).frame(width: 52, height: 52)
                Image(systemName: card.symbol).font(.system(size: 24, weight: .bold)).foregroundColor(SwarmTheme.cyan)
            }
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 8) {
                    Text(card.title).font(SwarmTheme.ui(18, .bold)).foregroundColor(SwarmTheme.foam)
                    if !card.levelText.isEmpty {
                        Text(card.levelText).font(SwarmTheme.ui(11, .bold)).foregroundColor(.black)
                            .padding(.horizontal, 7).padding(.vertical, 2)
                            .background(card.levelText == "NEW" ? SwarmTheme.lime : SwarmTheme.cyan)
                            .clipShape(Capsule())
                    }
                }
                Text(card.subtitle).font(SwarmTheme.ui(13)).foregroundColor(SwarmTheme.foam.opacity(0.65))
            }
            Spacer()
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(white: 0.1)))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(SwarmTheme.cyan.opacity(0.35), lineWidth: 1))
    }
}

struct GameOverOverlay: View {
    @ObservedObject var model: GameModel
    @State private var shareImage: UIImage?
    @State private var showShare = false
    @State private var showReportExport = false
    @State private var shareFailed = false

    private var report: SurveyRunReport? { model.surveyReport }

    private var sharePayload: DeathSharePayload {
        DeathSharePayload(
            surveyScore: report?.surveyScore ?? 0,
            detections: report?.detections ?? model.kills,
            richness: report?.richness ?? model.speciesRichness,
            missionTitle: report?.missionTitle,
            missionPassed: report?.missionPassed ?? false,
            timeSec: model.timeSec,
            bestSurveyScore: model.bestSurveyScore
        )
    }

    var body: some View {
        ZStack {
            SwarmTheme.bg.opacity(0.9).ignoresSafeArea()
            ScrollView {
                VStack(spacing: 8) {
                    Spacer(minLength: 24)
                    Text(model.deathHeadline)
                        .font(SwarmTheme.title(model.runWasNewBest ? 40 : 46))
                        .foregroundColor(model.runWasNewBest ? SwarmTheme.lime : SwarmTheme.red)
                        .shadow(color: (model.runWasNewBest ? SwarmTheme.lime : SwarmTheme.red).opacity(0.6), radius: 16)
                        .multilineTextAlignment(.center)

                    if let report {
                        missionStatusBadge(report)
                        Text(report.missionTitle)
                            .font(SwarmTheme.ui(15, .bold))
                            .foregroundColor(SwarmTheme.cyan)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }

                    Text("Transect \(timeStr(model.timeSec))")
                        .font(SwarmTheme.ui(18, .bold)).foregroundColor(SwarmTheme.foam).padding(.top, 4)

                    if !model.deathSubline.isEmpty {
                        Text(model.deathSubline)
                            .font(SwarmTheme.ui(13))
                            .foregroundColor(SwarmTheme.foam.opacity(0.65))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 28)
                            .padding(.top, 2)
                    }

                    HStack(spacing: 18) {
                        stat("\(report?.surveyScore ?? 0)", "survey score")
                        stat("\(report?.detections ?? model.kills)", SurveyProtocolCopy.detectionsLabel.lowercased())
                        stat("\(report?.richness ?? model.speciesRichness)", "species")
                    }.padding(.top, 12)

                    if let report, !report.vouchers.isEmpty {
                        voucherList(report.vouchers)
                            .padding(.horizontal, 28)
                            .padding(.top, 8)
                    }

                    if model.coresEarned > 0 {
                        Text("+\(model.coresEarned) survey grants")
                            .font(SwarmTheme.ui(15, .bold)).foregroundColor(SwarmTheme.cyan).padding(.top, 6)
                    }

                    VStack(spacing: 12) {
                        Button("Deploy again") { model.start() }.buttonStyle(NeonButton(tint: SwarmTheme.cyan))
                        if report != nil {
                            Button("Export survey report") { showReportExport = true }
                                .buttonStyle(NeonButton(tint: Color(white: 0.22)))
                        }
                        Button("Share") { presentShare() }.buttonStyle(NeonButton(tint: SwarmTheme.lime))
                        Button("Menu") { model.restart() }.buttonStyle(NeonButton(tint: Color(white: 0.3)))
                    }
                    .padding(.horizontal, 36)
                    .padding(.top, 16)
                    .padding(.bottom, 48)
                }
            }
        }
        .onAppear { cacheShareImage() }
        .sheet(isPresented: $showShare, onDismiss: { shareImage = nil }) {
            if let shareImage {
                ActivityShareSheet(items: [shareImage, AcousticFieldCopy.shareTagline])
            }
        }
        .sheet(isPresented: $showReportExport) {
            if let report {
                ActivityShareSheet(items: [
                    SurveyReportExporter.textReport(report, deployMode: model.deployMode),
                    SurveyReportExporter.csvRows(report, deployMode: model.deployMode),
                ])
            }
        }
        .alert("Couldn't create share image", isPresented: $shareFailed) {
            Button("OK", role: .cancel) {}
        }
    }

    @ViewBuilder
    private func missionStatusBadge(_ report: SurveyRunReport) -> some View {
        let passed = report.missionPassed
        let label = report.abortReason != nil
            ? SurveyProtocolCopy.deploymentAborted
            : (passed ? SurveyProtocolCopy.missionPassed : SurveyProtocolCopy.missionIncomplete)
        Text(label)
            .font(SwarmTheme.ui(11, .bold))
            .foregroundColor(.black)
            .padding(.horizontal, 12).padding(.vertical, 5)
            .background(passed ? SwarmTheme.lime : SwarmTheme.red.opacity(0.85))
            .clipShape(Capsule())
            .padding(.top, 6)
    }

    private func voucherList(_ vouchers: [DetectionVoucher]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Detection vouchers")
                .font(SwarmTheme.ui(11, .bold))
                .foregroundColor(SwarmTheme.foam.opacity(0.55))
            ForEach(vouchers.suffix(6)) { v in
                HStack(spacing: 8) {
                    Image(systemName: v.validated ? "checkmark.seal.fill" : "questionmark.circle")
                        .font(.system(size: 12))
                        .foregroundColor(v.validated ? SwarmTheme.lime : SwarmTheme.foam.opacity(0.4))
                    VStack(alignment: .leading, spacing: 1) {
                        Text(v.commonName)
                            .font(SwarmTheme.ui(12, .semibold))
                            .foregroundColor(SwarmTheme.foam)
                        Text(v.scientificName)
                            .font(.system(size: 10, weight: .medium, design: .serif))
                            .italic()
                            .foregroundColor(SwarmTheme.foam.opacity(0.5))
                        Text(v.clipFilename)
                            .font(SwarmTheme.ui(9, .medium))
                            .foregroundColor(SwarmTheme.cyan.opacity(0.55))
                    }
                    Spacer()
                    Text("\(Int(v.confidence * 100))%")
                        .font(SwarmTheme.ui(11, .bold))
                        .foregroundColor(SwarmTheme.cyan.opacity(0.8))
                }
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(white: 0.08)))
    }

    private func cacheShareImage() {
        shareImage = ShareCardRenderer.image(for: sharePayload)
    }

    private func presentShare() {
        if shareImage == nil { cacheShareImage() }
        if shareImage != nil {
            showShare = true
        } else {
            shareFailed = true
        }
    }
    private func stat(_ v: String, _ l: String) -> some View {
        VStack(spacing: 2) {
            Text(v).font(SwarmTheme.ui(22, .bold)).foregroundColor(SwarmTheme.lime)
            Text(l).font(SwarmTheme.ui(12)).foregroundColor(SwarmTheme.foam.opacity(0.6))
        }
    }
}

struct MetaOverlay: View {
    @ObservedObject var model: GameModel
    @ObservedObject private var meta: MetaStore

    init(model: GameModel) {
        self.model = model
        _meta = ObservedObject(wrappedValue: model.meta)
    }

    var body: some View {
        ZStack {
            SwarmTheme.bg.opacity(0.94).ignoresSafeArea()
            VStack(spacing: 12) {
                HStack {
                    Text("FIELD LAB")
                        .font(SwarmTheme.title(32)).foregroundColor(SwarmTheme.cyan)
                    Spacer()
                    Text("\(meta.cores) grants")
                        .font(SwarmTheme.ui(16, .bold)).foregroundColor(SwarmTheme.lime)
                }
                .padding(.horizontal, 22).padding(.top, 20)

                Text("Permanent rig upgrades for every deployment")
                    .font(SwarmTheme.ui(13)).foregroundColor(SwarmTheme.foam.opacity(0.55))

                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(MetaCatalog.all) { up in
                            metaRow(up)
                        }
                    }
                    .padding(.horizontal, 22)
                }

                Button("Back") { model.closeMeta() }
                    .buttonStyle(NeonButton(tint: Color(white: 0.28)))
                    .padding(.horizontal, 36).padding(.bottom, 36)
            }
        }
    }

    private func metaRow(_ up: MetaUpgrade) -> some View {
        let lv = meta.level(for: up.id)
        let maxed = lv >= up.maxLevel
        let cost = maxed ? 0 : up.cost(lv)
        let canBuy = meta.canBuy(up)

        return HStack(spacing: 12) {
            Image(systemName: up.symbol)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(SwarmTheme.cyan)
                .frame(width: 40)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(up.title).font(SwarmTheme.ui(16, .bold)).foregroundColor(SwarmTheme.foam)
                    Text("Lv \(lv)/\(up.maxLevel)")
                        .font(SwarmTheme.ui(11, .bold)).foregroundColor(.black)
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(SwarmTheme.cyan.opacity(0.85)).clipShape(Capsule())
                }
                Text(up.subtitle).font(SwarmTheme.ui(12)).foregroundColor(SwarmTheme.foam.opacity(0.6))
            }
            Spacer()
            if maxed {
                Text("MAX").font(SwarmTheme.ui(12, .bold)).foregroundColor(SwarmTheme.lime)
            } else {
                Button("\(cost)") { model.buyMeta(up.id) }
                    .font(SwarmTheme.ui(14, .bold))
                    .foregroundColor(canBuy ? .black : SwarmTheme.foam.opacity(0.4))
                    .padding(.horizontal, 14).padding(.vertical, 8)
                    .background(canBuy ? SwarmTheme.lime : Color(white: 0.15))
                    .clipShape(Capsule())
                    .disabled(!canBuy)
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color(white: 0.1)))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(SwarmTheme.cyan.opacity(0.25), lineWidth: 1))
    }
}

struct SettingsOverlay: View {
    @ObservedObject var model: GameModel
    @State private var soundOn = GameSettings.soundEnabled
    @State private var hapticsOn = GameSettings.hapticsEnabled
    @State private var listenGain = Double(GameSettings.listenGain)
    @State private var colorblindOn = GameSettings.colorblindSpectrogram
    @State private var traineeOn = GameSettings.traineeMode
    @State private var captionsOn = GameSettings.captionsEnabled

    var body: some View {
        ZStack {
            SwarmTheme.bg.opacity(0.94).ignoresSafeArea()
            ScrollView {
                VStack(spacing: 20) {
                    Text("SETTINGS")
                        .font(SwarmTheme.title(32))
                        .foregroundColor(SwarmTheme.cyan)
                        .padding(.top, 28)

                    VStack(spacing: 12) {
                        settingsToggle("Field Audio", isOn: $soundOn)
                        settingsToggle("Haptics", isOn: $hapticsOn)
                        settingsToggle("Detection captions", isOn: $captionsOn)
                        settingsToggle("Trainee mode", isOn: $traineeOn)
                        settingsToggle("Colorblind spectrogram", isOn: $colorblindOn)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Listen gain \(Int(listenGain * 100))%")
                                .font(SwarmTheme.ui(17, .semibold))
                                .foregroundColor(SwarmTheme.foam)
                            Slider(value: $listenGain, in: 0.6...1.4, step: 0.05)
                                .tint(SwarmTheme.cyan)
                        }
                        .padding(14)
                        .background(RoundedRectangle(cornerRadius: 14).fill(Color(white: 0.1)))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(SwarmTheme.cyan.opacity(0.25), lineWidth: 1))
                    }
                    .padding(.horizontal, 28)

                    Button("Back") { model.closeSettings() }
                        .buttonStyle(NeonButton(tint: Color(white: 0.28)))
                        .padding(.horizontal, 36)
                        .padding(.top, 8)
                        .padding(.bottom, 48)
                }
            }
        }
        .onBooleanChange(soundOn) { GameSettings.soundEnabled = $0 }
        .onBooleanChange(hapticsOn) { GameSettings.hapticsEnabled = $0 }
        .onBooleanChange(captionsOn) { GameSettings.captionsEnabled = $0 }
        .onBooleanChange(traineeOn) { GameSettings.traineeMode = $0 }
        .onBooleanChange(colorblindOn) { GameSettings.colorblindSpectrogram = $0 }
        .onDoubleChange(listenGain) { GameSettings.listenGain = Float($0) }
    }

    private func settingsToggle(_ title: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            Text(title)
                .font(SwarmTheme.ui(17, .semibold))
                .foregroundColor(SwarmTheme.foam)
        }
        .tint(SwarmTheme.cyan)
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color(white: 0.1)))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(SwarmTheme.cyan.opacity(0.25), lineWidth: 1))
    }
}

struct MentorshipOverlay: View {
    @ObservedObject var model: GameModel

    var body: some View {
        ZStack {
            SwarmTheme.bg.opacity(0.94).ignoresSafeArea()
            VStack(spacing: 16) {
                Text("MENTORSHIP DEPLOY")
                    .font(SwarmTheme.title(34))
                    .foregroundColor(SwarmTheme.lime)
                    .padding(.top, 36)
                Text(MentorshipCopy.briefingLead)
                    .font(SwarmTheme.ui(14))
                    .foregroundColor(SwarmTheme.foam.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(MentorshipCopy.protocolSteps.enumerated()), id: \.offset) { i, step in
                        HStack(alignment: .top, spacing: 8) {
                            Text("\(i + 1).")
                                .font(SwarmTheme.ui(12, .bold))
                                .foregroundColor(SwarmTheme.cyan)
                            Text(step)
                                .font(SwarmTheme.ui(12))
                                .foregroundColor(SwarmTheme.foam.opacity(0.8))
                        }
                    }
                }
                .padding(16)
                .background(RoundedRectangle(cornerRadius: 14).fill(Color(white: 0.1)))
                .padding(.horizontal, 24)
                Spacer()
                Button("Begin transect") { model.completeMentorship() }
                    .buttonStyle(NeonButton())
                    .padding(.horizontal, 36)
                    .padding(.bottom, 48)
            }
        }
    }
}

struct PausedOverlay: View {
    @ObservedObject var model: GameModel

    var body: some View {
        ZStack {
            Color.black.opacity(0.55).ignoresSafeArea()
            VStack(spacing: 16) {
                Text("PAUSED")
                    .font(SwarmTheme.title(40))
                    .foregroundColor(SwarmTheme.cyan)
                Text("Transect on hold — noise floor stable")
                    .font(SwarmTheme.ui(14))
                    .foregroundColor(SwarmTheme.foam.opacity(0.65))
                VStack(spacing: 12) {
                    Button("Resume") { model.resume() }.buttonStyle(NeonButton())
                    Button("Settings") { model.openSettings() }.buttonStyle(NeonButton(tint: Color(white: 0.24)))
                    Button("Abort to menu") { model.restart() }.buttonStyle(NeonButton(tint: Color(white: 0.3)))
                }
                .padding(.horizontal, 36)
            }
        }
    }
}

struct LabBoardOverlay: View {
    @ObservedObject var model: GameModel
    @ObservedObject private var board: LabBoardStore
    @State private var showExport = false

    init(model: GameModel) {
        self.model = model
        _board = ObservedObject(wrappedValue: model.labBoard)
    }

    var body: some View {
        ZStack {
            SwarmTheme.bg.opacity(0.94).ignoresSafeArea()
            VStack(spacing: 12) {
                HStack {
                    Text("LAB BOARD")
                        .font(SwarmTheme.title(30))
                        .foregroundColor(SwarmTheme.cyan)
                    Spacer()
                }
                .padding(.horizontal, 22)
                .padding(.top, 20)
                Text("Async field detections from your lab mates")
                    .font(SwarmTheme.ui(12))
                    .foregroundColor(SwarmTheme.foam.opacity(0.5))
                Text("Simulated lab mate activity for demo purposes")
                    .font(SwarmTheme.ui(10, .medium))
                    .foregroundColor(SwarmTheme.foam.opacity(0.35))
                    .italic()
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(board.events) { event in
                            labRow(event)
                        }
                    }
                    .padding(.horizontal, 22)
                }
                Button("Export notebook CSV") { showExport = true }
                    .buttonStyle(NeonButton(tint: SwarmTheme.lime))
                    .padding(.horizontal, 36)
                Button("Back") { model.closeLabBoard() }
                    .buttonStyle(NeonButton(tint: Color(white: 0.28)))
                    .padding(.horizontal, 36)
                    .padding(.bottom, 36)
            }
        }
        .sheet(isPresented: $showExport) {
            ActivityShareSheet(items: [
                CitizenScienceExporter.catalogCSV(catalog: model.catalog, habitat: model.habitatSite),
                CitizenScienceExporter.metadataJSON(habitat: model.habitatSite, deployMode: model.deployMode, catalog: model.catalog),
            ])
        }
    }

    private func labRow(_ event: LabBoardEvent) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: event.mateName == "You" ? "person.fill" : "person.2.fill")
                .foregroundColor(event.mateName == "You" ? SwarmTheme.lime : SwarmTheme.cyan.opacity(0.8))
            VStack(alignment: .leading, spacing: 2) {
                Text("\(event.mateName) · \(event.siteLabel)")
                    .font(SwarmTheme.ui(12, .bold))
                    .foregroundColor(SwarmTheme.foam)
                Text("\(event.speciesCommon) (\(event.speciesScientific))")
                    .font(SwarmTheme.ui(11))
                    .foregroundColor(SwarmTheme.foam.opacity(0.65))
                Text(event.recorder)
                    .font(SwarmTheme.ui(9))
                    .foregroundColor(SwarmTheme.foam.opacity(0.4))
            }
            Spacer()
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(white: 0.1)))
    }
}

struct CaptionOverlay: View {
    let text: String
    var body: some View {
        VStack {
            Spacer()
            Text(text)
                .font(SwarmTheme.ui(13, .semibold))
                .foregroundColor(SwarmTheme.foam)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color.black.opacity(0.72)))
                .padding(.bottom, 120)
        }
        .allowsHitTesting(false)
    }
}

private struct HabitatSitePicker: View {
    @Binding var selection: HabitatSite

    var body: some View {
        HStack(spacing: 8) {
            ForEach(HabitatSite.allCases, id: \.self) { site in
                Button { selection = site } label: {
                    VStack(spacing: 3) {
                        Image(systemName: site.symbol)
                            .font(.system(size: 13, weight: .bold))
                        Text(site.title)
                            .font(SwarmTheme.ui(9, .bold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .foregroundColor(selection == site ? .black : SwarmTheme.foam.opacity(0.85))
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                    .background(selection == site ? SwarmTheme.cyan : Color(white: 0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private struct DeployModePicker: View {
    @Binding var selection: DeployMode

    var body: some View {
        HStack(spacing: 10) {
            ForEach(DeployMode.allCases, id: \.self) { mode in
                Button {
                    selection = mode
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Image(systemName: mode.symbol)
                                .font(.system(size: 14, weight: .bold))
                            Text(mode.title)
                                .font(SwarmTheme.ui(12, .bold))
                        }
                        Text(mode.subtitle)
                            .font(SwarmTheme.ui(9))
                            .foregroundColor(SwarmTheme.foam.opacity(0.55))
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }
                    .foregroundColor(selection == mode ? .black : SwarmTheme.foam.opacity(0.85))
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(selection == mode ? SwarmTheme.lime : Color(white: 0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(selection == mode ? SwarmTheme.lime : SwarmTheme.cyan.opacity(0.25), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private struct TransectModePicker: View {
    @Binding var selection: TransectMode

    var body: some View {
        HStack(spacing: 10) {
            ForEach(TransectMode.allCases, id: \.self) { mode in
                Button { selection = mode } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Image(systemName: mode.symbol)
                                .font(.system(size: 14, weight: .bold))
                            Text(mode.title)
                                .font(SwarmTheme.ui(12, .bold))
                        }
                        Text(mode.subtitle)
                            .font(SwarmTheme.ui(9))
                            .foregroundColor(SwarmTheme.foam.opacity(0.55))
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }
                    .foregroundColor(selection == mode ? .black : SwarmTheme.foam.opacity(0.85))
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(selection == mode ? SwarmTheme.cyan : Color(white: 0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(selection == mode ? SwarmTheme.cyan : SwarmTheme.lime.opacity(0.25), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct CatalogOverlay: View {
    @ObservedObject var model: GameModel
    @ObservedObject private var catalog: SpeciesCatalogStore
    @State private var showCatalogExport = false

    init(model: GameModel) {
        self.model = model
        _catalog = ObservedObject(wrappedValue: model.catalog)
    }

    var body: some View {
        ZStack {
            SwarmTheme.bg.opacity(0.94).ignoresSafeArea()
            VStack(spacing: 12) {
                HStack {
                    Text("SPECIES CATALOG")
                        .font(SwarmTheme.title(28))
                        .foregroundColor(SwarmTheme.cyan)
                    Spacer()
                    Text("\(catalog.discoveredCount)/\(catalog.entries.count)")
                        .font(SwarmTheme.ui(14, .bold))
                        .foregroundColor(SwarmTheme.lime)
                }
                .padding(.horizontal, 22)
                .padding(.top, 20)

                Text("Study notebook · presence/absence across deployments")
                    .font(SwarmTheme.ui(12))
                    .foregroundColor(SwarmTheme.foam.opacity(0.5))

                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(catalog.entries) { entry in
                            catalogRow(entry)
                        }
                    }
                    .padding(.horizontal, 22)
                }

                Button("Export pipeline CSV") { showCatalogExport = true }
                    .buttonStyle(NeonButton(tint: SwarmTheme.lime))
                    .padding(.horizontal, 36)
                Button("Back") { model.closeCatalog() }
                    .buttonStyle(NeonButton(tint: Color(white: 0.28)))
                    .padding(.horizontal, 36)
                    .padding(.bottom, 36)
            }
        }
        .sheet(isPresented: $showCatalogExport) {
            ActivityShareSheet(items: [
                CitizenScienceExporter.catalogCSV(catalog: catalog, habitat: model.habitatSite),
                CitizenScienceExporter.metadataJSON(habitat: model.habitatSite, deployMode: model.deployMode, catalog: catalog),
            ])
        }
    }

    private func catalogRow(_ entry: CatalogEntry) -> some View {
        HStack(spacing: 12) {
            Image(systemName: entry.discovered ? "checkmark.circle.fill" : "circle.dashed")
                .foregroundColor(entry.discovered ? SwarmTheme.lime : SwarmTheme.foam.opacity(0.35))
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.species.commonName)
                    .font(SwarmTheme.ui(15, .bold))
                    .foregroundColor(entry.discovered ? SwarmTheme.foam : SwarmTheme.foam.opacity(0.45))
                Text(entry.species.scientificName)
                    .font(.system(size: 11, weight: .medium, design: .serif))
                    .italic()
                    .foregroundColor(SwarmTheme.foam.opacity(entry.discovered ? 0.55 : 0.35))
                Text(entry.species.bandLabel)
                    .font(SwarmTheme.ui(10))
                    .foregroundColor(SwarmTheme.foam.opacity(0.45))
                if entry.discovered {
                    notebookMeta(entry.record)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 3) {
                Text(entry.discovered ? "\(entry.count)×" : "—")
                    .font(SwarmTheme.ui(14, .bold))
                    .foregroundColor(entry.discovered ? SwarmTheme.cyan : SwarmTheme.foam.opacity(0.3))
                if entry.record.deploymentCount > 0 {
                    Text("\(entry.record.deploymentCount) deploys")
                        .font(SwarmTheme.ui(9))
                        .foregroundColor(SwarmTheme.foam.opacity(0.4))
                }
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(white: 0.1)))
    }

    @ViewBuilder
    private func notebookMeta(_ record: SpeciesNotebookRecord) -> some View {
        HStack(spacing: 8) {
            if record.sm5Count > 0 {
                Text("SM5 \(record.sm5Count)")
                    .font(SwarmTheme.ui(9, .bold))
                    .foregroundColor(SwarmTheme.lime.opacity(0.75))
            }
            if record.sm5batCount > 0 {
                Text("SM5BAT \(record.sm5batCount)")
                    .font(SwarmTheme.ui(9, .bold))
                    .foregroundColor(SwarmTheme.cyan.opacity(0.75))
            }
        }
    }
}

struct PlayingFieldOverlay: View {
    @ObservedObject var model: GameModel

    var body: some View {
        ZStack {
            VStack {
                if let mission = model.activeMission {
                    MissionBriefCard(
                        mission: mission,
                        detections: model.kills,
                        richness: model.speciesRichness,
                        noiseBudgetPct: model.noiseBudgetPct,
                        deploymentId: model.deploymentId,
                        transectMode: model.transectMode
                    )
                    .padding(.horizontal, 16)
                    .padding(.top, 52)
                }
                HStack {
                    Button {
                        model.pause()
                    } label: {
                        Image(systemName: "pause.fill")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(SwarmTheme.foam.opacity(0.85))
                            .padding(10)
                            .background(Circle().fill(Color.black.opacity(0.45)))
                    }
                    .padding(.leading, 16)
                    .padding(.top, model.activeMission == nil ? 52 : 8)
                    Spacer()
                    Button {
                        model.listenBurst()
                    } label: {
                        Label("Listen", systemImage: "ear.fill")
                            .font(SwarmTheme.ui(13, .bold))
                            .foregroundColor(.black)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 9)
                            .background(SwarmTheme.cyan)
                            .clipShape(Capsule())
                            .shadow(color: SwarmTheme.cyan.opacity(0.5), radius: 8)
                    }
                    .padding(.trailing, 16)
                    .padding(.top, model.activeMission == nil ? 52 : 8)
                }
                if model.passiveBatMode {
                    Text("PASSIVE MONITOR")
                        .font(SwarmTheme.ui(10, .bold))
                        .foregroundColor(SwarmTheme.cyan.opacity(0.85))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(Color.black.opacity(0.45)))
                        .padding(.top, 6)
                }
                if let spec = model.spectrogram {
                    SpectrogramStripView(snapshot: spec)
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
                Spacer()
                if !model.recentVouchers.isEmpty {
                    VoucherFeedStrip(vouchers: model.recentVouchers)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 8)
                }
                if let hint = model.nextGoalHint {
                    Text(hint)
                        .font(SwarmTheme.ui(12, .semibold))
                        .foregroundColor(SwarmTheme.foam.opacity(0.55))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(Color.black.opacity(0.35)))
                        .padding(.bottom, 18)
                        .allowsHitTesting(false)
                }
            }
        }
        .animation(.easeOut(duration: 0.2), value: model.spectrogram)
    }
}

private struct VoucherFeedStrip: View {
    let vouchers: [DetectionVoucher]

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Recent vouchers")
                .font(SwarmTheme.ui(9, .bold))
                .foregroundColor(SwarmTheme.foam.opacity(0.45))
            ForEach(vouchers) { v in
                HStack(spacing: 6) {
                    Image(systemName: v.validated ? "checkmark.seal.fill" : "questionmark.circle")
                        .font(.system(size: 10))
                        .foregroundColor(v.validated ? SwarmTheme.lime : SwarmTheme.red.opacity(0.7))
                    VStack(alignment: .leading, spacing: 1) {
                        Text(v.commonName)
                            .font(SwarmTheme.ui(11, .semibold))
                            .foregroundColor(SwarmTheme.foam.opacity(0.85))
                        Text(v.clipFilename)
                            .font(SwarmTheme.ui(8, .medium))
                            .foregroundColor(SwarmTheme.foam.opacity(0.4))
                            .lineLimit(1)
                    }
                    Spacer()
                    Text("\(Int(v.confidence * 100))%")
                        .font(SwarmTheme.ui(10, .bold))
                        .foregroundColor(SwarmTheme.cyan.opacity(0.8))
                }
            }
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.black.opacity(0.5)))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(SwarmTheme.cyan.opacity(0.2), lineWidth: 1))
    }
}

private struct MissionBriefCard: View {
    let mission: SurveyMission
    let detections: Int
    let richness: Int
    let noiseBudgetPct: Int
    let deploymentId: String?
    let transectMode: TransectMode

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("MISSION BRIEF")
                    .font(SwarmTheme.ui(10, .bold))
                    .foregroundColor(SwarmTheme.lime)
                Spacer()
                HStack(spacing: 6) {
                    Text(transectMode.title)
                        .font(SwarmTheme.ui(9, .bold))
                        .foregroundColor(SwarmTheme.lime.opacity(0.7))
                    Text(timeStr(mission.transectDurationSec))
                        .font(SwarmTheme.ui(10, .bold))
                        .foregroundColor(SwarmTheme.cyan.opacity(0.75))
                }
            }
            if let dep = deploymentId {
                Text(dep)
                    .font(SwarmTheme.ui(9, .medium))
                    .foregroundColor(SwarmTheme.foam.opacity(0.35))
            }
            Text(mission.title)
                .font(SwarmTheme.ui(14, .bold))
                .foregroundColor(SwarmTheme.foam)
            Text(mission.hypothesis)
                .font(SwarmTheme.ui(11))
                .foregroundColor(SwarmTheme.foam.opacity(0.6))
                .lineLimit(2)
            HStack(spacing: 12) {
                briefStat("\(detections)/\(mission.targetDetections)", "detections")
                briefStat("\(richness)/\(mission.targetRichness)", "species")
                briefStat("\(noiseBudgetPct)%", "noise budget")
            }
            .padding(.top, 2)
            if GameSettings.traineeMode {
                Text(MentorshipCopy.traineeHint)
                    .font(SwarmTheme.ui(9))
                    .foregroundColor(SwarmTheme.lime.opacity(0.75))
                    .padding(.top, 2)
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.black.opacity(0.55)))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(SwarmTheme.lime.opacity(0.3), lineWidth: 1))
    }

    private func briefStat(_ value: String, _ label: String) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(value)
                .font(SwarmTheme.ui(12, .bold))
                .foregroundColor(SwarmTheme.cyan)
            Text(label)
                .font(SwarmTheme.ui(9))
                .foregroundColor(SwarmTheme.foam.opacity(0.45))
        }
    }
}

struct SpectrogramStripView: View {
    let snapshot: SpectrogramSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("LISTEN BURST")
                    .font(SwarmTheme.ui(10, .bold))
                    .foregroundColor(SwarmTheme.lime)
                Spacer()
                Text(snapshot.deployMode == .sm5bat ? "SM5BAT" : "SM5")
                    .font(SwarmTheme.ui(10, .bold))
                    .foregroundColor(SwarmTheme.cyan.opacity(0.8))
            }
            SpectrogramWaterfallView(waterfall: snapshot.waterfall)
                .frame(height: 72)
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(snapshot.bands) { band in
                    VStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(SwarmTheme.cyan.opacity(0.25 + Double(band.level) * 0.65))
                            .frame(width: 28, height: max(8, 40 * band.level))
                        Text(band.label)
                            .font(.system(size: 7, weight: .semibold, design: .monospaced))
                            .foregroundColor(SwarmTheme.foam.opacity(0.55))
                            .multilineTextAlignment(.center)
                            .frame(width: 72)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            if let dominant = snapshot.dominantLabel {
                Text(dominant)
                    .font(SwarmTheme.ui(10, .semibold))
                    .foregroundColor(SwarmTheme.foam.opacity(0.65))
            }
            Text("† ultrasonic band down-converted for playback")
                .font(.system(size: 8))
                .foregroundColor(SwarmTheme.foam.opacity(0.35))
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.black.opacity(0.62)))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(SwarmTheme.cyan.opacity(0.35), lineWidth: 1))
    }
}

struct SpectrogramWaterfallView: View {
    let waterfall: SpectrogramWaterfall

    var body: some View {
        Canvas { context, size in
            let tN = waterfall.timeSteps
            let fN = waterfall.freqBins
            guard tN > 0, fN > 0 else { return }
            let cellW = size.width / CGFloat(tN)
            let cellH = size.height / CGFloat(fN)

            for row in 0..<fN {
                for col in 0..<tN {
                    let idx = row * tN + col
                    guard idx < waterfall.energy.count else { continue }
                    let e = CGFloat(waterfall.energy[idx])
                    let rect = CGRect(
                        x: CGFloat(col) * cellW,
                        y: size.height - CGFloat(row + 1) * cellH,
                        width: max(1, cellW),
                        height: max(1, cellH)
                    )
                    let color: Color = {
                        if GameSettings.colorblindSpectrogram {
                            let v = 0.15 + Double(e) * 0.85
                            return Color(red: v * 0.45, green: v * 0.75, blue: v)
                        }
                        let hue = 0.52 - Double(row) / Double(fN) * 0.18
                        return Color(hue: hue, saturation: 0.75, brightness: 0.12 + Double(e) * 0.88)
                    }()
                    context.fill(Path(rect), with: .color(color))
                }
            }
        }
        .background(Color(red: 0.02, green: 0.03, blue: 0.06))
    }
}

struct RunBannerOverlay: View {
    let text: String
    var body: some View {
        VStack {
            Text(text)
                .font(SwarmTheme.ui(15, .bold))
                .foregroundColor(SwarmTheme.lime)
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(Capsule().fill(Color.black.opacity(0.55)))
                .overlay(Capsule().stroke(SwarmTheme.lime.opacity(0.45), lineWidth: 1))
                .padding(.top, 56)
            Spacer()
        }
        .allowsHitTesting(false)
    }
}

func timeStr(_ s: Int) -> String { String(format: "%d:%02d", s / 60, s % 60) }

private extension View {
    @ViewBuilder
    func onBooleanChange(_ value: Bool, perform: @escaping (Bool) -> Void) -> some View {
        if #available(iOS 17.0, *) {
            onChange(of: value) { _, newValue in perform(newValue) }
        } else {
            onChange(of: value, perform: perform)
        }
    }

    @ViewBuilder
    func onDoubleChange(_ value: Double, perform: @escaping (Double) -> Void) -> some View {
        if #available(iOS 17.0, *) {
            onChange(of: value) { _, newValue in perform(newValue) }
        } else {
            onChange(of: value, perform: perform)
        }
    }
}
