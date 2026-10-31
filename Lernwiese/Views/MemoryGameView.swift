import SwiftUI

/// "Futter-Paare": turn over two cards and find an animal together with its food.
struct MemoryGameView: View {
    let game: GameID
    let speaksIntro: Bool
    let onAgain: () -> Void
    let onClose: () -> Void

    @EnvironmentObject private var progress: ProgressStore
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var deck: MemoryDeck
    @State private var burst = 0
    @State private var finished = false
    @State private var mismatchToken = 0

    init(game: GameID, level: Int, seed: UInt64, speaksIntro: Bool,
         onAgain: @escaping () -> Void, onClose: @escaping () -> Void) {
        self.game = game
        self.speaksIntro = speaksIntro
        self.onAgain = onAgain
        self.onClose = onClose
        var rng = SeededGenerator(seed: seed)
        var deck = MemoryDeck.make(pairs: MemoryDeck.pairCount(level: level), using: &rng)
        if DemoContent.isActive {
            deck.revealForDemo()
        }
        _deck = State(initialValue: deck)
    }

    var body: some View {
        GeometryReader { geo in
            let compact = geo.size.width < 600
            ZStack {
                MeadowBackground(showsSun: false)
                VStack(spacing: compact ? 10 : 16) {
                    GameTopBar(done: deck.matchedPairs, total: deck.pairCount, showsSpeaker: settings.speechEnabled,
                               onClose: onClose, onRepeat: { Speaker.shared.say(game.intro) })
                    Text("Finde Tier und Futter!")
                        .font(.rounded(compact ? 28 : 36, .heavy))
                        .foregroundColor(Palette.ink)
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.6)
                        .accessibilityAddTraits(.isHeader)
                    cardGrid
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
        .onAppear {
            Speaker.shared.say(speaksIntro ? game.intro : "Finde jedes Tier und sein Futter.")
        }
    }

    private var cardGrid: some View {
        GeometryReader { geo in
            let spacing: CGFloat = 12
            let layout = Self.layout(count: deck.cards.count, in: geo.size, spacing: spacing)
            let rows = (deck.cards.count + layout.columns - 1) / layout.columns
            VStack(spacing: spacing) {
                ForEach(0..<rows, id: \.self) { row in
                    HStack(spacing: spacing) {
                        ForEach((row * layout.columns)..<min(deck.cards.count, (row + 1) * layout.columns), id: \.self) { index in
                            MemoryCardView(card: deck.cards[index], size: layout.card, reduceMotion: reduceMotion) {
                                tap(index)
                            }
                        }
                    }
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }

    /// Picks the number of columns that gives the biggest cards.
    static func layout(count: Int, in size: CGSize, spacing: CGFloat) -> (columns: Int, card: CGSize) {
        let aspect: CGFloat = 0.8
        var best = (columns: 2, card: CGSize(width: 40, height: 50))
        for columns in 2...6 {
            let rows = (count + columns - 1) / columns
            let width = (size.width - spacing * CGFloat(columns - 1)) / CGFloat(columns)
            let height = (size.height - spacing * CGFloat(rows - 1)) / CGFloat(rows)
            let cardWidth = min(width, height * aspect, 260)
            // On a tie prefer more columns: fewer rows look calmer on wide screens.
            if cardWidth >= best.card.width {
                best = (columns, CGSize(width: cardWidth, height: cardWidth / aspect))
            }
        }
        return best
    }

    private func tap(_ index: Int) {
        guard !finished else { return }
        let card = deck.cards[index]
        let animation: Animation = reduceMotion ? .easeInOut(duration: 0.2) : .spring(response: 0.45, dampingFraction: 0.75)
        let result = withAnimation(animation) { deck.flip(at: index) }
        switch result {
        case .ignored:
            Speaker.shared.say(card.picture.name)
        case .first:
            Haptics.tap()
            Speaker.shared.say(card.picture.name)
        case .match(let pairID):
            Haptics.success()
            burst += 1
            Speaker.shared.say("\(card.picture.name). \(Phrases.randomPraise()) \(deck.facts[pairID])")
            if deck.isComplete {
                Task {
                    try? await Task.sleep(nanoseconds: 1_600_000_000)
                    finish()
                }
            }
        case .mismatch:
            Haptics.gentle()
            Speaker.shared.say("\(card.picture.name). Das passt nicht zusammen.")
            mismatchToken += 1
            let token = mismatchToken
            Task {
                try? await Task.sleep(nanoseconds: 1_600_000_000)
                guard token == mismatchToken else { return }
                withAnimation(animation) { deck.hideMismatched() }
            }
        }
    }

    private func finish() {
        let earned = progress.recordCompletion(of: game)
        withAnimation(.easeOut(duration: 0.25)) { finished = true }
        Speaker.shared.say(earned ? "Super gemacht! Du hast einen Stern bekommen." : "Super gemacht! Du bist ein echter Profi.",
                           interrupt: false)
    }
}

struct MemoryCardView: View {
    let card: MemoryCard
    let size: CGSize
    let reduceMotion: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            FlipCard(angle: card.isFaceUp ? 0 : 180, reduceMotion: reduceMotion) {
                front
            } back: {
                back
            }
            .frame(width: size.width, height: size.height)
        }
        .buttonStyle(BouncyButtonStyle())
        .accessibilityLabel(card.isFaceUp ? card.picture.name : "Verdeckte Karte")
        .accessibilityValue(card.isMatched ? "gefunden" : "")
    }

    private var front: some View {
        let shape = RoundedRectangle(cornerRadius: 20, style: .continuous)
        return VStack(spacing: size.width * 0.04) {
            Text(card.picture.emoji)
                .font(.system(size: size.width * 0.5))
            Text(card.picture.name)
                .font(.rounded(max(13, size.width * 0.14), .heavy))
                .foregroundColor(Palette.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .padding(.horizontal, 4)
        }
        .frame(width: size.width, height: size.height)
        .background(shape.fill(Color.white).shadow(color: .black.opacity(0.1), radius: 4, y: 2))
        .overlay(shape.stroke(card.isMatched ? Palette.correct : Color.black.opacity(0.06), lineWidth: card.isMatched ? 5 : 1))
    }

    private var back: some View {
        let shape = RoundedRectangle(cornerRadius: 20, style: .continuous)
        return shape
            .fill(LinearGradient(colors: [Palette.hillBack, Palette.hillFront], startPoint: .top, endPoint: .bottom))
            .overlay(Text("🌼").font(.system(size: size.width * 0.38)))
            .overlay(shape.stroke(Color.white, lineWidth: 4).padding(6))
            .frame(width: size.width, height: size.height)
            .shadow(color: .black.opacity(0.12), radius: 4, y: 2)
    }
}

/// Turns a card around its vertical axis. SwiftUI animates `angle`, so the front shows until halfway.
struct FlipCard<Front: View, Back: View>: View, Animatable {
    var angle: Double
    let reduceMotion: Bool
    let front: Front
    let back: Back

    init(angle: Double, reduceMotion: Bool, @ViewBuilder front: () -> Front, @ViewBuilder back: () -> Back) {
        self.angle = angle
        self.reduceMotion = reduceMotion
        self.front = front()
        self.back = back()
    }

    var animatableData: Double {
        get { angle }
        set { angle = newValue }
    }

    var body: some View {
        ZStack {
            front.opacity(angle < 90 ? 1 : 0)
            back
                .rotation3DEffect(.degrees(reduceMotion ? 0 : 180), axis: (x: 0, y: 1, z: 0))
                .opacity(angle < 90 ? 0 : 1)
        }
        .rotation3DEffect(.degrees(reduceMotion ? 0 : angle), axis: (x: 0, y: 1, z: 0), perspective: 0.4)
    }
}
