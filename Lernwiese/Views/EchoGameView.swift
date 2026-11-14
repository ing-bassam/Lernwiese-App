import SwiftUI

/// "Klang-Echo": Pieks plays a few tones on singing flowers, the child plays them back.
/// A mistake is no problem – Pieks simply plays the tones again.
struct EchoGameView: View {
    let game: GameID
    let speaksIntro: Bool
    let onAgain: () -> Void
    let onClose: () -> Void

    @EnvironmentObject private var progress: ProgressStore
    @EnvironmentObject private var settings: AppSettings

    @State private var sequences: [[Int]]
    @State private var index = 0
    @State private var entered: [Int] = []
    @State private var listening = true
    @State private var lit: Int?
    @State private var burst = 0
    @State private var finished = false
    @State private var playToken = 0

    static let flowers: [(emoji: String, name: String, tint: Tint)] = [
        ("🌷", "rote Tulpe", .red),
        ("🌻", "Sonnenblume", .yellow),
        ("🍀", "Kleeblatt", .green),
        ("🌸", "rosa Blüte", .pink),
    ]

    init(game: GameID, level: Int, seed: UInt64, speaksIntro: Bool,
         onAgain: @escaping () -> Void, onClose: @escaping () -> Void) {
        self.game = game
        self.speaksIntro = speaksIntro
        self.onAgain = onAgain
        self.onClose = onClose
        var rng = SeededGenerator(seed: seed)
        _sequences = State(initialValue: EchoPlan.sequences(level: level, using: &rng))
        if DemoContent.isActive {
            _listening = State(initialValue: false)
            _lit = State(initialValue: 2)
        }
    }

    private var sequence: [Int] { sequences[index] }

    var body: some View {
        GeometryReader { geo in
            let compact = geo.size.width < 600
            ZStack {
                MeadowBackground(showsSun: false)
                VStack(spacing: compact ? 12 : 18) {
                    GameTopBar(done: index, total: sequences.count, showsSpeaker: true,
                               onClose: onClose, onRepeat: replay)
                    MascotSays(text: listening ? "Hör gut zu! 👂" : "Jetzt du! 🎵",
                               mood: listening ? .happy : .waving, size: compact ? 90 : 120)
                    progressDots
                    flowerGrid(compact: compact, size: geo.size)
                        .frame(maxHeight: .infinity)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
                .frame(maxWidth: 1000)
                .frame(maxWidth: .infinity)

                StarBurst(trigger: burst)

                if finished {
                    FinishView(stars: progress.stars(for: game), onAgain: onAgain, onHome: onClose)
                        .transition(.opacity)
                }
            }
        }
        .task {
            guard !DemoContent.isActive else { return }
            if speaksIntro {
                Speaker.shared.say(game.intro)
                try? await Task.sleep(nanoseconds: 3_500_000_000)
            }
            await play()
        }
    }

    /// One dot per tone of the current round, filled while the child plays.
    private var progressDots: some View {
        HStack(spacing: 10) {
            ForEach(0..<sequence.count, id: \.self) { step in
                Image(systemName: "music.note")
                    .font(.system(size: 22, weight: .heavy))
                    .foregroundColor(step < entered.count ? Palette.star : Palette.ink.opacity(0.25))
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(entered.count) von \(sequence.count) Tönen")
    }

    private func flowerGrid(compact: Bool, size: CGSize) -> some View {
        let columns = compact ? 2 : 4
        let side = compact ? min((size.width - 48) / 2, size.height * 0.22) : min((size.width - 90) / 4, 220)
        return LazyVGrid(columns: Array(repeating: GridItem(.fixed(side), spacing: 16), count: columns), spacing: 16) {
            ForEach(0..<Self.flowers.count, id: \.self) { flower in
                Button {
                    tap(flower)
                } label: {
                    flowerView(flower, side: side)
                }
                .buttonStyle(BouncyButtonStyle())
                .disabled(listening || finished)
                .accessibilityLabel(Self.flowers[flower].name)
            }
        }
    }

    private func flowerView(_ flower: Int, side: CGFloat) -> some View {
        let isLit = lit == flower
        let tint = Self.flowers[flower].tint.color
        return Text(Self.flowers[flower].emoji)
            .font(.system(size: side * 0.55))
            .frame(width: side, height: side)
            .background(
                Circle()
                    .fill(isLit ? tint.opacity(0.55) : Color.white)
                    .shadow(color: isLit ? tint : .black.opacity(0.1), radius: isLit ? 18 : 5, y: isLit ? 0 : 3))
            .overlay(Circle().stroke(tint, lineWidth: isLit ? 8 : 4))
            .scaleEffect(isLit ? 1.12 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.55), value: isLit)
    }

    // MARK: - Logic

    @MainActor
    private func play() async {
        playToken += 1
        let token = playToken
        listening = true
        entered = []
        try? await Task.sleep(nanoseconds: 600_000_000)
        for tone in sequence {
            guard token == playToken, !Task.isCancelled else { return }
            light(tone)
            try? await Task.sleep(nanoseconds: 750_000_000)
        }
        guard token == playToken else { return }
        listening = false
    }

    private func light(_ flower: Int) {
        lit = flower
        MusicPlayer.shared.playFlower(flower)
        Haptics.tap()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            if lit == flower { lit = nil }
        }
    }

    private func tap(_ flower: Int) {
        guard !listening, !finished else { return }
        light(flower)
        let step = entered.count
        guard sequence.indices.contains(step) else { return }
        if sequence[step] == flower {
            entered.append(flower)
            if entered.count == sequence.count {
                roundDone()
            }
        } else {
            Haptics.gentle()
            listening = true
            Speaker.shared.say("Fast! Hör noch einmal zu.")
            Task {
                try? await Task.sleep(nanoseconds: 1_600_000_000)
                await play()
            }
        }
    }

    private func roundDone() {
        burst += 1
        Haptics.success()
        listening = true
        if index == sequences.count - 1 {
            let earned = progress.recordCompletion(of: game)
            MusicPlayer.shared.playFinish()
            withAnimation(.easeOut(duration: 0.25).delay(0.5)) { finished = true }
            Speaker.shared.say(earned ? "Wunderschön gespielt! Du hast einen Stern bekommen." : "Wunderschön gespielt!")
            return
        }
        Speaker.shared.say(Phrases.randomPraise())
        Task {
            try? await Task.sleep(nanoseconds: 1_400_000_000)
            index += 1
            await play()
        }
    }

    private func replay() {
        guard !finished else { return }
        Task { await play() }
    }
}
