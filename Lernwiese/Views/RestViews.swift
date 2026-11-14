import SwiftUI

/// Gentle notice a few minutes before the daily time is up. Shown on top of the meadow and of every game.
struct TimeNoticeBanner: View {
    let minutesLeft: Int

    var body: some View {
        MascotSays(text: minutesLeft == 1
                   ? "Noch eine Minute, dann machen wir eine Pause."
                   : "Noch \(minutesLeft) Minuten, dann machen wir eine Pause.",
                   mood: .happy, size: 70)
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 26, style: .continuous).fill(Tint.yellow.color.opacity(0.92)))
            .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
            .padding(.horizontal, 16)
            .frame(maxWidth: 620)
    }
}

/// Watches the play time and shows the notice once when little time is left.
struct TimeNoticeModifier: ViewModifier {
    @ObservedObject var playTime: PlayTimeStore
    @ObservedObject var settings: AppSettings
    @State private var shownFor: String?
    @State private var visibleMinutes: Int?

    func body(content: Content) -> some View {
        ZStack(alignment: .top) {
            content
            banner
        }
        .onChange(of: playTime.status(settings: settings)) { status in
            statusChanged(status)
        }
    }

    @ViewBuilder
    private var banner: some View {
        if let minutes = visibleMinutes {
            TimeNoticeBanner(minutesLeft: minutes)
                .padding(.top, 70)
                .transition(.move(edge: .top).combined(with: .opacity))
                .onTapGesture { hide() }
        }
    }

    private func statusChanged(_ status: ScreenTime.Status) {
        guard case .almost(let minutes) = status else { return }
        let limit = settings.dailyLimitMinutes ?? 0
        let key = playTime.dayKey(Date()) + "-\(limit)-\(playTime.todayExtraMinutes)"
        guard shownFor != key else { return }
        shownFor = key
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) { visibleMinutes = minutes }
        let spoken = minutes == 1 ? "eine Minute" : "\(minutes) Minuten"
        Speaker.shared.say("Noch \(spoken), dann machen wir eine Pause.", interrupt: false)
        DispatchQueue.main.asyncAfter(deadline: .now() + 9) { hide() }
    }

    private func hide() {
        withAnimation(.easeOut(duration: 0.3)) { visibleMinutes = nil }
    }
}

extension View {
    func timeNotice() -> some View {
        modifier(TimeNoticeModifier(playTime: .shared, settings: .shared))
    }
}

/// Shown when the daily time is used up: Pieks goes to sleep and suggests something to do away from the screen.
/// Only parents can allow more time (behind the parental gate).
struct RestView: View {
    @EnvironmentObject private var settings: AppSettings
    @ObservedObject private var playTime = PlayTimeStore.shared
    @State private var idea = Int.random(in: 0..<ScreenTime.breakIdeas.count)
    @State private var showingGate = false

    var body: some View {
        GeometryReader { geo in
            let compact = geo.size.width < 600
            ZStack {
                LinearGradient(colors: [Color(red: 0.23, green: 0.27, blue: 0.52), Color(red: 0.47, green: 0.42, blue: 0.70)],
                               startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
                stars(in: geo.size)
                ScrollView {
                    VStack(spacing: compact ? 16 : 24) {
                        Text("🌙").font(.system(size: compact ? 60 : 84)).accessibilityHidden(true)
                        Text("Zeit für eine Pause!")
                            .font(.rounded(compact ? 34 : 46, .heavy))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .accessibilityAddTraits(.isHeader)
                        Text("Du hast heute schon toll gelernt. Deine Augen und dein Kopf brauchen jetzt eine Pause.")
                            .font(.rounded(compact ? 19 : 24, .semibold))
                            .foregroundColor(.white.opacity(0.92))
                            .multilineTextAlignment(.center)
                        Mascot(mood: .sleepy, size: compact ? 130 : 180)
                        ideaCard(compact: compact)
                        Button {
                            Speaker.shared.stop()
                            showingGate = true
                        } label: {
                            Label("Eltern: mehr Zeit erlauben", systemImage: "lock.fill")
                                .font(.rounded(15, .bold))
                                .foregroundColor(.white.opacity(0.75))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(Capsule().stroke(Color.white.opacity(0.4), lineWidth: 1.5))
                        }
                        .padding(.top, 8)
                    }
                    .padding(24)
                    .frame(maxWidth: 680)
                    .frame(maxWidth: .infinity, minHeight: geo.size.height)
                }
            }
        }
        .sheet(isPresented: $showingGate) {
            ParentGateView(onSuccess: {
                playTime.allowExtraTime()
                showingGate = false
            }, onCancel: { showingGate = false })
        }
        .onAppear {
            MusicPlayer.shared.setMood(.rest)
            speak()
        }
    }

    private func ideaCard(compact: Bool) -> some View {
        let current = ScreenTime.breakIdeas[idea]
        return VStack(spacing: 12) {
            Text("Meine Idee für dich:")
                .font(.rounded(18, .bold))
                .foregroundColor(Palette.ink.opacity(0.7))
            HStack(spacing: 14) {
                Text(current.emoji).font(.system(size: compact ? 48 : 64)).accessibilityHidden(true)
                Text(current.text)
                    .font(.rounded(compact ? 22 : 28, .heavy))
                    .foregroundColor(Palette.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
            BigButton(title: "Andere Idee", systemImage: "sparkles", tint: Tint.purple.color) {
                var next = Int.random(in: 0..<ScreenTime.breakIdeas.count)
                if next == idea { next = (next + 1) % ScreenTime.breakIdeas.count }
                idea = next
                Speaker.shared.say(ScreenTime.breakIdeas[next].text)
            }
        }
        .padding(22)
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 30, style: .continuous).fill(Color.white))
    }

    private func stars(in size: CGSize) -> some View {
        let points: [(CGFloat, CGFloat, CGFloat)] = [
            (0.1, 0.08, 10), (0.3, 0.15, 6), (0.55, 0.06, 8), (0.8, 0.12, 12), (0.92, 0.3, 6),
            (0.07, 0.35, 7), (0.85, 0.5, 9), (0.15, 0.62, 6), (0.6, 0.22, 5),
        ]
        return ZStack {
            ForEach(points.indices, id: \.self) { index in
                Image(systemName: "star.fill")
                    .font(.system(size: points[index].2))
                    .foregroundColor(.white.opacity(0.7))
                    .position(x: size.width * points[index].0, y: size.height * points[index].1)
            }
        }
        .accessibilityHidden(true)
    }

    private func speak() {
        Speaker.shared.say("Zeit für eine Pause! Du hast heute schon toll gelernt. Meine Idee für dich: "
                           + ScreenTime.breakIdeas[idea].text)
    }
}
