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
                Text("Outlast the horde.")
                    .font(SwarmTheme.ui(18)).foregroundColor(SwarmTheme.foam.opacity(0.8))
                HStack(spacing: 16) {
                    if model.bestTime > 0 {
                        Text("Best: \(timeStr(model.bestTime))")
                            .font(SwarmTheme.ui(14)).foregroundColor(SwarmTheme.lime)
                    }
                    Text("\(model.cores) cores")
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
                    Button("Play") { model.start() }.buttonStyle(NeonButton())
                    Button("Upgrades") { model.openMeta() }.buttonStyle(NeonButton(tint: Color(white: 0.22)))
                    if seenHint {
                        Text("Drag to move · weapons fire on their own · grab the green to level up")
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
                Text("Quick start")
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
                Text("LEVEL \(model.level)")
                    .font(SwarmTheme.title(40)).foregroundColor(SwarmTheme.lime)
                    .shadow(color: SwarmTheme.lime.opacity(0.6), radius: 12)
                Text("Power spike — pick your path")
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
    @State private var shareFailed = false

    private var sharePayload: DeathSharePayload {
        DeathSharePayload(
            timeSec: model.timeSec,
            kills: model.kills,
            level: model.level,
            bestTime: model.bestTime
        )
    }

    var body: some View {
        ZStack {
            SwarmTheme.bg.opacity(0.9).ignoresSafeArea()
            VStack(spacing: 8) {
                Spacer()
                Text(model.deathHeadline)
                    .font(SwarmTheme.title(model.runWasNewBest ? 46 : 52))
                    .foregroundColor(model.runWasNewBest ? SwarmTheme.lime : SwarmTheme.red)
                    .shadow(color: (model.runWasNewBest ? SwarmTheme.lime : SwarmTheme.red).opacity(0.6), radius: 16)
                Text("Survived \(timeStr(model.timeSec))")
                    .font(SwarmTheme.ui(22, .bold)).foregroundColor(SwarmTheme.foam).padding(.top, 6)
                if !model.deathSubline.isEmpty {
                    Text(model.deathSubline)
                        .font(SwarmTheme.ui(14))
                        .foregroundColor(SwarmTheme.foam.opacity(0.65))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 28)
                        .padding(.top, 4)
                }
                HStack(spacing: 22) {
                    stat("\(model.kills)", "kills")
                    stat("LV \(model.level)", "reached")
                    stat(timeStr(model.bestTime), "best")
                }.padding(.top, 14)
                if model.coresEarned > 0 {
                    Text("+\(model.coresEarned) cores")
                        .font(SwarmTheme.ui(16, .bold)).foregroundColor(SwarmTheme.cyan).padding(.top, 6)
                }
                Spacer()
                VStack(spacing: 12) {
                    Button("Run again") { model.start() }.buttonStyle(NeonButton(tint: SwarmTheme.cyan))
                    Button("Share") { presentShare() }.buttonStyle(NeonButton(tint: SwarmTheme.lime))
                    Button("Menu") { model.restart() }.buttonStyle(NeonButton(tint: Color(white: 0.3)))
                }.padding(.horizontal, 36).padding(.bottom, 48)
            }
        }
        .onAppear { cacheShareImage() }
        .sheet(isPresented: $showShare, onDismiss: { shareImage = nil }) {
            if let shareImage {
                ActivityShareSheet(items: [shareImage, "Outlast the horde — SWARM"])
            }
        }
        .alert("Couldn't create share image", isPresented: $shareFailed) {
            Button("OK", role: .cancel) {}
        }
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
                    Text("UPGRADES")
                        .font(SwarmTheme.title(32)).foregroundColor(SwarmTheme.cyan)
                    Spacer()
                    Text("\(meta.cores) cores")
                        .font(SwarmTheme.ui(16, .bold)).foregroundColor(SwarmTheme.lime)
                }
                .padding(.horizontal, 22).padding(.top, 20)

                Text("Permanent bonuses apply every run")
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

    var body: some View {
        ZStack {
            SwarmTheme.bg.opacity(0.94).ignoresSafeArea()
            VStack(spacing: 20) {
                Text("SETTINGS")
                    .font(SwarmTheme.title(32))
                    .foregroundColor(SwarmTheme.cyan)
                    .padding(.top, 28)

                VStack(spacing: 12) {
                    settingsToggle("Sound", isOn: $soundOn)
                    settingsToggle("Haptics", isOn: $hapticsOn)
                }
                .padding(.horizontal, 28)

                Spacer()

                Button("Back") { model.closeSettings() }
                    .buttonStyle(NeonButton(tint: Color(white: 0.28)))
                    .padding(.horizontal, 36)
                    .padding(.bottom, 48)
            }
        }
        .onBooleanChange(soundOn) { GameSettings.soundEnabled = $0 }
        .onBooleanChange(hapticsOn) { GameSettings.hapticsEnabled = $0 }
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
}
