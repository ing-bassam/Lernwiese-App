import SwiftUI

/// "Formen-Garten": Pieks found things on the meadow. The child drags each one into the outline that fits –
/// or simply taps the outline. A wrong outline only sends the thing gently back.
struct ShapeGameView: View {
    let game: GameID
    let speaksIntro: Bool
    let onAgain: () -> Void
    let onClose: () -> Void

    @EnvironmentObject private var progress: ProgressStore
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var round: ShapeRound
    @State private var index = 0
    @State private var placed: [ShapeKind: [ShapeItem]] = [:]
    @State private var drag: CGSize = .zero
    @State private var dragging = false
    @State private var frames: [ShapeKind: CGRect] = [:]
    @State private var wrongShake: [ShapeKind: Int] = [:]
    @State private var highlighted: ShapeKind?
    @State private var burst = 0
    @State private var finished = false

    private let space = "shapesGame"

    init(game: GameID, level: Int, seed: UInt64, speaksIntro: Bool,
         onAgain: @escaping () -> Void, onClose: @escaping () -> Void) {
        self.game = game
        self.speaksIntro = speaksIntro
        self.onAgain = onAgain
        self.onClose = onClose
        var rng = SeededGenerator(seed: seed)
        let round = ShapeRound.make(level: level, using: &rng)
        _round = State(initialValue: round)
        if DemoContent.startsSolved, let first = round.items.first {
            _placed = State(initialValue: [first.shape: [first]])
            _index = State(initialValue: 1)
        }
    }

    private var current: ShapeItem? {
        round.items.indices.contains(index) ? round.items[index] : nil
    }

    var body: some View {
        GeometryReader { geo in
            let compact = geo.size.width < 600
            ZStack {
                MeadowBackground(showsSun: false)
                VStack(spacing: compact ? 10 : 16) {
                    GameTopBar(done: index, total: round.items.count, showsSpeaker: settings.speechEnabled,
                               onClose: onClose, onRepeat: speakItem)
                    Text(current.map { "Wohin passt \($0.thing.subject)?" } ?? "Alles einsortiert!")
                        .font(.rounded(compact ? 28 : 36, .heavy))
                        .foregroundColor(Palette.ink)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.6)
                        .accessibilityAddTraits(.isHeader)
                    HStack(alignment: .bottom, spacing: 12) {
                        Mascot(mood: .thinking, size: compact ? 90 : 130)
                        if let current {
                            itemTile(current, side: compact ? 130 : 180)
                                .id(index)
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .frame(maxHeight: .infinity)
                    .zIndex(1)
                    outlines(compact: compact, width: geo.size.width - 32)
                        .padding(.bottom, 12)
                }
                .padding(.horizontal, 16)
                .frame(maxWidth: 1000)
                .frame(maxWidth: .infinity)

                StarBurst(trigger: burst)

                if finished {
                    FinishView(stars: progress.stars(for: game), onAgain: onAgain, onHome: onClose)
                        .transition(.opacity)
                }
            }
            .coordinateSpace(name: space)
            .onPreferenceChange(ShapeFrameKey.self) { frames = $0 }
        }
        .task {
            speakItem()
        }
    }

    // MARK: - Pieces

    private func itemTile(_ item: ShapeItem, side: CGFloat) -> some View {
        Text(item.thing.emoji)
            .font(.system(size: side * 0.62))
            .frame(width: side, height: side)
            .background(Circle().fill(Color.white).shadow(color: .black.opacity(dragging ? 0.25 : 0.12),
                                                           radius: dragging ? 12 : 6, y: dragging ? 8 : 3))
            .scaleEffect(dragging ? 1.08 : 1)
            .offset(drag)
            .gesture(
                DragGesture(coordinateSpace: .named(space))
                    .onChanged { value in
                        dragging = true
                        drag = value.translation
                        highlighted = frames.first { $0.value.contains(value.location) }?.key
                    }
                    .onEnded { value in
                        let target = frames.first { $0.value.contains(value.location) }?.key
                        dragging = false
                        highlighted = nil
                        if let target {
                            drop(on: target)
                        } else {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { drag = .zero }
                        }
                    })
            .accessibilityLabel(item.thing.name)
            .accessibilityHint("Zieh es in die passende Form oder tippe unten auf eine Form.")
    }

    private func outlines(compact: Bool, width: CGFloat) -> some View {
        let count = CGFloat(round.shapes.count)
        let side = min((width - (count - 1) * 10) / count, compact ? 120 : 170)
        return HStack(spacing: 10) {
            ForEach(round.shapes) { shape in
                Button {
                    drop(on: shape)
                } label: {
                    outline(shape, side: side)
                }
                .buttonStyle(BouncyButtonStyle())
                .modifier(Shake(animatableData: CGFloat(wrongShake[shape] ?? 0)))
                .background(GeometryReader { proxy in
                    Color.clear.preference(key: ShapeFrameKey.self,
                                           value: [shape: proxy.frame(in: .named(space))])
                })
                .accessibilityLabel(shape.name)
            }
        }
    }

    private func outline(_ shape: ShapeKind, side: CGFloat) -> some View {
        let items = placed[shape] ?? []
        let isTarget = highlighted == shape
        return ZStack {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.white.opacity(isTarget ? 0.95 : 0.7))
            ShapeOutline(kind: shape)
                .fill(shape.tint.color.opacity(isTarget ? 0.35 : 0.18))
                .padding(side * 0.14)
            ShapeOutline(kind: shape)
                .stroke(shape.tint.color, style: StrokeStyle(lineWidth: 4, lineJoin: .round, dash: [9, 6]))
                .padding(side * 0.14)
            if !items.isEmpty {
                Text(items.map(\.thing.emoji).joined())
                    .font(.system(size: side * 0.22))
                    .lineLimit(1)
                    .minimumScaleFactor(0.4)
                    .padding(.horizontal, 6)
            }
        }
        .frame(width: side, height: side)
        .scaleEffect(isTarget ? 1.06 : 1)
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isTarget)
    }

    // MARK: - Logic

    private func drop(on shape: ShapeKind) {
        guard let item = current, !finished else { return }
        if item.shape == shape {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                placed[shape, default: []].append(item)
                drag = .zero
                index += 1
            }
            burst += 1
            Haptics.success()
            MusicPlayer.shared.playCorrect()
            let fact = "\(item.thing.subject.capitalizedFirst) \(shape.likeness)."
            if index >= round.items.count {
                finish(after: fact)
            } else {
                Speaker.shared.say("\(Phrases.randomPraise()) \(fact)")
                if let next = current {
                    Speaker.shared.say("Und wohin passt \(next.thing.subject)?", interrupt: false)
                }
            }
        } else {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { drag = .zero }
            withAnimation(reduceMotion ? nil : .linear(duration: 0.45)) { wrongShake[shape, default: 0] += 1 }
            Haptics.gentle()
            MusicPlayer.shared.playTryAgain()
            Speaker.shared.say("Das ist ein \(shape.name). \(Phrases.randomTryAgain())")
        }
    }

    private func speakItem() {
        let intro = speaksIntro && index == 0 ? game.intro + " " : ""
        guard let item = current else { return }
        Speaker.shared.say(intro + "Wohin passt \(item.thing.subject)?")
    }

    private func finish(after fact: String) {
        let earned = progress.recordCompletion(of: game)
        withAnimation(.easeOut(duration: 0.25).delay(0.6)) { finished = true }
        MusicPlayer.shared.playFinish()
        Speaker.shared.say("\(fact) " + (earned ? "Super gemacht! Du hast einen Stern bekommen." : "Super gemacht! Alles passt."))
    }
}

private struct ShapeFrameKey: PreferenceKey {
    static var defaultValue: [ShapeKind: CGRect] = [:]
    static func reduce(value: inout [ShapeKind: CGRect], nextValue: () -> [ShapeKind: CGRect]) {
        value.merge(nextValue()) { $1 }
    }
}

/// Circle, square, triangle, star or heart, filling the given rectangle.
struct ShapeOutline: Shape {
    let kind: ShapeKind

    func path(in rect: CGRect) -> Path {
        let side = min(rect.width, rect.height)
        let box = CGRect(x: rect.midX - side / 2, y: rect.midY - side / 2, width: side, height: side)
        var path = Path()
        switch kind {
        case .circle:
            path.addEllipse(in: box)
        case .square:
            path.addRoundedRect(in: box.insetBy(dx: side * 0.06, dy: side * 0.06),
                                cornerSize: CGSize(width: side * 0.06, height: side * 0.06))
        case .triangle:
            path.move(to: CGPoint(x: box.midX, y: box.minY + side * 0.04))
            path.addLine(to: CGPoint(x: box.maxX, y: box.maxY - side * 0.08))
            path.addLine(to: CGPoint(x: box.minX, y: box.maxY - side * 0.08))
            path.closeSubpath()
        case .star:
            let center = CGPoint(x: box.midX, y: box.midY + side * 0.04)
            for step in 0..<10 {
                let radius = step.isMultiple(of: 2) ? side * 0.5 : side * 0.21
                let angle = -Double.pi / 2 + Double(step) * Double.pi / 5
                let point = CGPoint(x: center.x + CGFloat(cos(angle)) * radius, y: center.y + CGFloat(sin(angle)) * radius)
                if step == 0 { path.move(to: point) } else { path.addLine(to: point) }
            }
            path.closeSubpath()
        case .heart:
            let width = box.width
            let height = box.height
            path.move(to: CGPoint(x: box.midX, y: box.minY + height * 0.92))
            path.addCurve(to: CGPoint(x: box.minX + width * 0.02, y: box.minY + height * 0.32),
                          control1: CGPoint(x: box.minX + width * 0.3, y: box.minY + height * 0.75),
                          control2: CGPoint(x: box.minX, y: box.minY + height * 0.55))
            path.addArc(center: CGPoint(x: box.minX + width * 0.27, y: box.minY + height * 0.3), radius: width * 0.25,
                        startAngle: .degrees(175), endAngle: .degrees(0), clockwise: false)
            path.addArc(center: CGPoint(x: box.minX + width * 0.73, y: box.minY + height * 0.3), radius: width * 0.25,
                        startAngle: .degrees(180), endAngle: .degrees(5), clockwise: false)
            path.addCurve(to: CGPoint(x: box.midX, y: box.minY + height * 0.92),
                          control1: CGPoint(x: box.maxX, y: box.minY + height * 0.55),
                          control2: CGPoint(x: box.minX + width * 0.7, y: box.minY + height * 0.75))
            path.closeSubpath()
        }
        return path
    }
}
