import SwiftUI

/// Plays the five rounds of a question game. Wrong answers are only greyed out – the child keeps trying
/// until the right one is found. There is no timer and no score to lose.
struct QuizGameView: View {
    let game: GameID
    let speaksIntro: Bool
    let onAgain: () -> Void
    let onClose: () -> Void

    @EnvironmentObject private var progress: ProgressStore
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var rounds: [Round]
    @State private var index = 0
    @State private var wrong: Set<Int> = []
    @State private var solved: Bool
    @State private var shakes: [Int: Int] = [:]
    @State private var burst = 0
    @State private var finished = false

    init(game: GameID, level: Int, seed: UInt64, speaksIntro: Bool,
         onAgain: @escaping () -> Void, onClose: @escaping () -> Void) {
        self.game = game
        self.speaksIntro = speaksIntro
        self.onAgain = onAgain
        self.onClose = onClose
        var rng = SeededGenerator(seed: seed)
        _rounds = State(initialValue: RoundFactory.rounds(for: game, level: level, using: &rng))
        _solved = State(initialValue: DemoContent.startsSolved)
    }

    private var round: Round { rounds[index] }
    private var isLastRound: Bool { index == rounds.count - 1 }

    var body: some View {
        GeometryReader { geo in
            let compact = geo.size.width < 600
            ZStack {
                MeadowBackground(showsSun: false)
                VStack(spacing: compact ? 10 : 16) {
                    GameTopBar(done: index + (solved ? 1 : 0), total: rounds.count,
                               showsSpeaker: settings.speechEnabled, onClose: onClose, onRepeat: speakRound)
                    Text(round.prompt)
                        .font(.rounded(compact ? 28 : 36, .heavy))
                        .foregroundColor(Palette.ink)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.6)
                        .accessibilityAddTraits(.isHeader)
                    if case .none = round.stage {
                        choices(compact: compact)
                            .frame(maxHeight: .infinity)
                    } else {
                        StageView(stage: round.stage, solved: solved)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .id(round.id)
                        choices(compact: compact)
                            .frame(height: choiceHeight(compact: compact, viewHeight: geo.size.height))
                    }
                    footer
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 6)
                .frame(maxWidth: 1000)
                .frame(maxWidth: .infinity)

                StarBurst(trigger: burst)

                if finished {
                    FinishView(stars: progress.stars(for: game), onAgain: onAgain, onHome: onClose)
                        .transition(.opacity)
                }
            }
        }
        .task(id: index) {
            speakRound()
        }
    }

    private func choices(compact: Bool) -> some View {
        ChoiceGrid(choices: round.choices, answer: round.answer, wrong: wrong, solved: solved,
                   shakes: shakes, compact: compact, onTap: choose)
            .id(round.id)
    }

    private func choiceHeight(compact: Bool, viewHeight: CGFloat) -> CGFloat {
        let rows = ChoiceGrid.rowCount(for: round.choices, compact: compact)
        let perRow: CGFloat = compact ? min(150, viewHeight * 0.17) : min(210, viewHeight * 0.2)
        return perRow * CGFloat(rows) + CGFloat(rows - 1) * 12
    }

    private var footer: some View {
        ZStack {
            if solved {
                Button(action: next) {
                    HStack(spacing: 10) {
                        Text(isLastRound ? "Fertig" : "Weiter")
                        Image(systemName: isLastRound ? "checkmark" : "arrow.right")
                    }
                    .font(.rounded(26, .heavy))
                    .foregroundColor(.white)
                    .padding(.horizontal, 40)
                    .frame(height: 64)
                    .background(Capsule().fill(Palette.correct))
                    .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
                }
                .buttonStyle(BouncyButtonStyle())
                .transition(.scale.combined(with: .opacity))
            }
        }
        .frame(height: 72)
    }

    private func speakRound() {
        let intro = index == 0 && speaksIntro ? game.intro + " " : ""
        Speaker.shared.say(intro + round.spoken)
    }

    private func choose(_ choice: Int) {
        guard !solved, !wrong.contains(choice) else { return }
        if choice == round.answer {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) { solved = true }
            burst += 1
            Haptics.success()
            Speaker.shared.say("\(Phrases.randomPraise()) \(round.fact)")
        } else {
            wrong.insert(choice)
            withAnimation(reduceMotion ? nil : .linear(duration: 0.45)) {
                shakes[choice, default: 0] += 1
            }
            Haptics.gentle()
            Speaker.shared.say(Phrases.randomTryAgain())
        }
    }

    private func next() {
        guard !isLastRound else {
            finish()
            return
        }
        wrong = []
        shakes = [:]
        solved = false
        index += 1
    }

    private func finish() {
        let earned = progress.recordCompletion(of: game)
        withAnimation(.easeOut(duration: 0.25)) { finished = true }
        burst += 1
        Haptics.success()
        Speaker.shared.say(earned ? "Super gemacht! Du hast einen Stern bekommen." : "Super gemacht! Du bist ein echter Profi.")
    }
}

// MARK: - Answers

enum ChoiceState: Equatable {
    case normal, wrong, correct, faded
}

struct ChoiceGrid: View {
    let choices: [Choice]
    let answer: Int
    let wrong: Set<Int>
    let solved: Bool
    let shakes: [Int: Int]
    let compact: Bool
    let onTap: (Int) -> Void

    static func columnCount(for choices: [Choice], compact: Bool) -> Int {
        guard let first = choices.first else { return 1 }
        switch first {
        case .group: return compact ? 1 : 2
        case .number: return choices.count
        default: return compact && choices.count == 4 ? 2 : choices.count
        }
    }

    static func rowCount(for choices: [Choice], compact: Bool) -> Int {
        let columns = columnCount(for: choices, compact: compact)
        return max(1, (choices.count + columns - 1) / columns)
    }

    var body: some View {
        GeometryReader { geo in
            let columns = Self.columnCount(for: choices, compact: compact)
            let rows = Self.rowCount(for: choices, compact: compact)
            let spacing: CGFloat = compact ? 12 : 18
            let width = (geo.size.width - spacing * CGFloat(columns - 1)) / CGFloat(columns)
            let height = (geo.size.height - spacing * CGFloat(rows - 1)) / CGFloat(rows)
            VStack(spacing: spacing) {
                ForEach(0..<rows, id: \.self) { row in
                    HStack(spacing: spacing) {
                        ForEach((row * columns)..<min(choices.count, (row + 1) * columns), id: \.self) { index in
                            ChoiceButton(choice: choices[index], state: state(of: index),
                                         size: CGSize(width: max(width, 40), height: max(height, 40))) {
                                onTap(index)
                            }
                            .modifier(Shake(animatableData: CGFloat(shakes[index] ?? 0)))
                        }
                    }
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }

    private func state(of index: Int) -> ChoiceState {
        if solved {
            return index == answer ? .correct : .faded
        }
        return wrong.contains(index) ? .wrong : .normal
    }
}

struct ChoiceButton: View {
    let choice: Choice
    let state: ChoiceState
    let size: CGSize
    let action: () -> Void

    private var side: CGFloat { min(size.width, size.height) }

    private var binTint: Tint? {
        if case .bin(_, _, let tint) = choice { return tint }
        return nil
    }

    var body: some View {
        Button(action: action) {
            content
                .frame(width: size.width, height: size.height)
                .background(background)
                .overlay(border)
                .overlay(alignment: .topTrailing) {
                    if state == .correct {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundColor(Palette.correct)
                            .background(Circle().fill(Color.white))
                            .offset(x: 8, y: -8)
                    }
                }
        }
        .buttonStyle(BouncyButtonStyle())
        .opacity(state == .wrong ? 0.35 : state == .faded ? 0.45 : 1)
        .scaleEffect(state == .correct ? 1.04 : 1)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: state)
        .accessibilityLabel(choice.spokenName)
        .accessibilityValue(state == .wrong ? "leider nicht richtig" : state == .correct ? "richtig" : "")
    }

    @ViewBuilder private var content: some View {
        switch choice {
        case .picture(let picture):
            VStack(spacing: side * 0.03) {
                Text(picture.emoji)
                    .font(.system(size: side * 0.46))
                Text(picture.name)
                    .font(.rounded(max(15, side * 0.14), .heavy))
                    .foregroundColor(Palette.ink)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.6)
                    .padding(.horizontal, 6)
            }
        case .number(let number):
            Text("\(number)")
                .font(.rounded(side * 0.56, .heavy))
                .foregroundColor(Palette.ink)
                .minimumScaleFactor(0.5)
        case .word(let word):
            Text(word)
                .font(.rounded(max(20, side * 0.24), .heavy))
                .foregroundColor(Palette.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.4)
                .padding(.horizontal, 10)
        case .group(let picture, _, let count):
            EmojiCluster(emoji: picture.emoji, count: count, columns: 5,
                         size: CGSize(width: size.width - 28, height: size.height - 28))
        case .bin(let title, let examples, _):
            VStack(spacing: side * 0.05) {
                Text(examples.joined())
                    .font(.system(size: side * (examples.count > 1 ? 0.2 : 0.36)))
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                Text(title)
                    .font(.rounded(max(17, side * 0.15), .heavy))
                    .foregroundColor(Palette.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            .padding(.horizontal, 8)
        }
    }

    @ViewBuilder private var background: some View {
        let shape = RoundedRectangle(cornerRadius: 24, style: .continuous)
        if let tint = binTint {
            shape.fill(tint.color.opacity(0.25))
                .background(shape.fill(Color.white))
                .shadow(color: .black.opacity(0.1), radius: 5, y: 3)
        } else {
            shape.fill(Color.white)
                .shadow(color: .black.opacity(0.1), radius: 5, y: 3)
        }
    }

    private var border: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .stroke(state == .correct ? Palette.correct : (binTint?.color ?? Color.black.opacity(0.06)),
                    lineWidth: state == .correct ? 6 : (binTint == nil ? 1 : 4))
    }
}

// MARK: - Stage

struct StageView: View {
    let stage: Stage
    let solved: Bool

    var body: some View {
        GeometryReader { geo in
            content(in: geo.size)
                .frame(width: geo.size.width, height: geo.size.height)
        }
    }

    @ViewBuilder private func content(in size: CGSize) -> some View {
        switch stage {
        case .none:
            EmptyView()
        case .item(let picture):
            ItemStage(picture: picture, size: size)
        case .count(let picture, let plural, let number):
            CountingStage(picture: picture, plural: plural, number: number, size: size,
                          initiallyCounted: DemoContent.isActive ? DemoContent.countedItems : 0)
        case .equation(let picture, let first, let second, let isPlus):
            EquationStage(picture: picture, first: first, second: second, isPlus: isPlus, solved: solved, size: size)
        case .sequence(let steps, let missing):
            SequenceStage(steps: steps, missing: missing, solved: solved, size: size)
        }
    }
}

/// One big picture; tapping it reads its name.
struct ItemStage: View {
    let picture: Picture
    let size: CGSize

    var body: some View {
        let diameter = max(70, min(size.width * 0.7, size.height - 54, 300))
        Button {
            Speaker.shared.say(picture.name)
        } label: {
            VStack(spacing: 8) {
                Text(picture.emoji)
                    .font(.system(size: diameter * 0.58))
                    .frame(width: diameter, height: diameter)
                    .background(Circle().fill(Color.white).shadow(color: .black.opacity(0.1), radius: 6, y: 3))
                Text(picture.name)
                    .font(.rounded(26, .heavy))
                    .foregroundColor(Palette.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
        }
        .buttonStyle(BouncyButtonStyle())
        .accessibilityLabel(picture.name)
        .accessibilityHint("Liest den Namen vor")
    }
}

/// Things to count in rows of five. Tapping a thing counts it aloud and puts a number on it.
struct CountingStage: View {
    let picture: Picture
    let plural: String
    let number: Int
    let size: CGSize
    @State private var counted: [Int]

    init(picture: Picture, plural: String, number: Int, size: CGSize, initiallyCounted: Int) {
        self.picture = picture
        self.plural = plural
        self.number = number
        self.size = size
        _counted = State(initialValue: Array(0..<max(0, min(initiallyCounted, number))))
    }

    var body: some View {
        let columns = max(1, min(number, 5))
        let rows = number > 5 ? 2 : 1
        let item = max(30, min(size.width / (CGFloat(columns) * 1.14), (size.height - 50) / (CGFloat(rows) * 1.22), 110))
        VStack(spacing: 10) {
            VStack(spacing: item * 0.16) {
                ForEach(0..<rows, id: \.self) { row in
                    HStack(spacing: item * 0.12) {
                        ForEach((row * columns)..<min(number, (row + 1) * columns), id: \.self) { index in
                            countItem(index, size: item)
                        }
                    }
                }
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 28, style: .continuous).fill(Color.white.opacity(0.75)))
            Label("Tippe zum Mitzählen", systemImage: "hand.point.up.left.fill")
                .font(.rounded(16, .semibold))
                .foregroundColor(Palette.ink.opacity(0.6))
                .opacity(counted.isEmpty ? 1 : 0)
                .accessibilityHidden(true)
        }
    }

    private func countItem(_ index: Int, size item: CGFloat) -> some View {
        let position = counted.firstIndex(of: index)
        return Button {
            count(index)
        } label: {
            Text(picture.emoji)
                .font(.system(size: item * 0.78))
                .frame(width: item, height: item)
                .overlay(alignment: .bottomTrailing) {
                    if let position {
                        Text("\(position + 1)")
                            .font(.rounded(item * 0.24, .heavy))
                            .foregroundColor(.white)
                            .frame(width: item * 0.42, height: item * 0.42)
                            .background(Circle().fill(Palette.correct))
                    }
                }
        }
        .buttonStyle(BouncyButtonStyle())
        .accessibilityLabel(position.map { "\(picture.name), gezählt: \($0 + 1)" } ?? picture.name)
    }

    private func count(_ index: Int) {
        if let position = counted.firstIndex(of: index) {
            Speaker.shared.say("\(position + 1)")
            return
        }
        counted.append(index)
        Haptics.tap()
        Speaker.shared.say("\(counted.count)")
    }
}

/// "3 + 2" with pictures, or "5 − 2" where the last two are leaving.
struct EquationStage: View {
    let picture: Picture
    let first: Int
    let second: Int
    let isPlus: Bool
    let solved: Bool
    let size: CGSize

    var body: some View {
        let pictureHeight = max(60, size.height - 76)
        let sign = isPlus ? "+" : "−"
        let result = solved ? String(isPlus ? first + second : first - second) : "?"
        VStack(spacing: 10) {
            if isPlus {
                HStack(spacing: 10) {
                    cluster(first, width: (size.width - 60) / 2, height: pictureHeight)
                    Text("+").font(.rounded(44, .heavy)).foregroundColor(Palette.ink)
                    cluster(second, width: (size.width - 60) / 2, height: pictureHeight)
                }
            } else {
                EmojiCluster(emoji: picture.emoji, count: first, columns: 5,
                             size: CGSize(width: size.width - 40, height: pictureHeight - 28), leaving: second)
                    .padding(14)
                    .background(RoundedRectangle(cornerRadius: 24, style: .continuous).fill(Color.white.opacity(0.75)))
            }
            Text("\(first) \(sign) \(second) = \(result)")
                .font(.rounded(46, .heavy))
                .foregroundColor(Palette.ink)
                .accessibilityLabel("\(first) \(isPlus ? "plus" : "minus") \(second)")
        }
        .accessibilityElement(children: .contain)
    }

    private func cluster(_ count: Int, width: CGFloat, height: CGFloat) -> some View {
        EmojiCluster(emoji: picture.emoji, count: count, columns: 3,
                     size: CGSize(width: width - 24, height: height - 24))
            .padding(12)
            .frame(width: width, height: height)
            .background(RoundedRectangle(cornerRadius: 24, style: .continuous).fill(Color.white.opacity(0.75)))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(count) \(picture.name)")
    }
}

/// Steps of a change in nature with one gap.
struct SequenceStage: View {
    let steps: [Picture]
    let missing: Int
    let solved: Bool
    let size: CGSize

    var body: some View {
        let count = CGFloat(steps.count)
        let box = max(50, min((size.width - (count - 1) * 42) / count, size.height * 0.8, 170))
        HStack(spacing: 8) {
            ForEach(steps.indices, id: \.self) { index in
                if index > 0 {
                    Image(systemName: "arrow.right")
                        .font(.system(size: 22, weight: .heavy))
                        .foregroundColor(Palette.ink.opacity(0.45))
                }
                step(index, box: box)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(steps.indices.map { $0 == missing && !solved ? "Fragezeichen" : steps[$0].name }
            .joined(separator: ", dann "))
    }

    @ViewBuilder private func step(_ index: Int, box: CGFloat) -> some View {
        let shape = RoundedRectangle(cornerRadius: 20, style: .continuous)
        if index == missing && !solved {
            shape
                .strokeBorder(Palette.ink.opacity(0.4), style: StrokeStyle(lineWidth: 4, dash: [10, 8]))
                .background(shape.fill(Color.white.opacity(0.5)))
                .frame(width: box, height: box)
                .overlay(Text("?").font(.rounded(box * 0.5, .heavy)).foregroundColor(Palette.ink.opacity(0.5)))
        } else {
            Text(steps[index].emoji)
                .font(.system(size: box * 0.58))
                .frame(width: box, height: box)
                .background(shape.fill(Color.white))
                .overlay(shape.stroke(index == missing ? Palette.correct : Color.clear, lineWidth: 5))
        }
    }
}
