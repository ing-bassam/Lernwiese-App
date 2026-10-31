import SwiftUI

enum Palette {
    static let skyTop = Color(red: 0.60, green: 0.83, blue: 0.98)
    static let skyBottom = Color(red: 0.87, green: 0.95, blue: 1.00)
    static let hillBack = Color(red: 0.56, green: 0.81, blue: 0.40)
    static let hillFront = Color(red: 0.40, green: 0.71, blue: 0.31)
    static let sun = Color(red: 1.00, green: 0.82, blue: 0.24)
    static let ink = Color(red: 0.15, green: 0.19, blue: 0.27)
    static let correct = Color(red: 0.20, green: 0.66, blue: 0.32)
    static let star = Color(red: 1.00, green: 0.75, blue: 0.08)
    static let starEmpty = Color(red: 0.82, green: 0.85, blue: 0.89)
}

extension Tint {
    var color: Color {
        switch self {
        case .green: return Color(red: 0.33, green: 0.70, blue: 0.30)
        case .yellow: return Color(red: 0.97, green: 0.76, blue: 0.16)
        case .orange: return Color(red: 0.97, green: 0.56, blue: 0.20)
        case .blue: return Color(red: 0.27, green: 0.56, blue: 0.94)
        case .red: return Color(red: 0.92, green: 0.31, blue: 0.33)
        case .purple: return Color(red: 0.60, green: 0.43, blue: 0.89)
        case .teal: return Color(red: 0.16, green: 0.67, blue: 0.70)
        case .pink: return Color(red: 0.94, green: 0.43, blue: 0.66)
        }
    }
}

extension Font {
    static func rounded(_ size: CGFloat, _ weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}

/// Sky, sun, a cloud and two green hills – drawn with plain shapes.
struct MeadowBackground: View {
    var showsSun = true

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height
            ZStack {
                LinearGradient(colors: [Palette.skyTop, Palette.skyBottom], startPoint: .top, endPoint: .bottom)
                if showsSun {
                    Circle().fill(Palette.sun.opacity(0.3)).frame(width: 190, height: 190).position(x: width - 54, y: 40)
                    Circle().fill(Palette.sun).frame(width: 120, height: 120).position(x: width - 54, y: 40)
                }
                Cloud().frame(width: 140, height: 52).position(x: width * 0.24, y: 74).opacity(0.9)
                Cloud().frame(width: 100, height: 38).position(x: width * 0.72, y: 140).opacity(0.7)
                Ellipse().fill(Palette.hillBack)
                    .frame(width: width * 1.3, height: max(height * 0.3, 170))
                    .position(x: width * 0.2, y: height + 10)
                Ellipse().fill(Palette.hillFront)
                    .frame(width: width * 1.4, height: max(height * 0.26, 150))
                    .position(x: width * 0.9, y: height + 34)
            }
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

struct Cloud: View {
    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height
            ZStack {
                Capsule().fill(Color.white).frame(width: width, height: height * 0.6).position(x: width / 2, y: height * 0.7)
                Circle().fill(Color.white).frame(width: height * 0.85, height: height * 0.85).position(x: width * 0.38, y: height * 0.45)
                Circle().fill(Color.white).frame(width: height * 0.65, height: height * 0.65).position(x: width * 0.63, y: height * 0.52)
            }
        }
    }
}

struct StarsView: View {
    let count: Int
    var maximum = ProgressStore.maxStars
    var size: CGFloat = 18

    var body: some View {
        HStack(spacing: size * 0.2) {
            ForEach(0..<maximum, id: \.self) { index in
                Image(systemName: "star.fill")
                    .font(.system(size: size, weight: .bold))
                    .foregroundColor(index < count ? Palette.star : Palette.starEmpty)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(count) von \(maximum) Sternen")
    }
}

struct BouncyButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

struct RoundIconButton: View {
    let systemName: String
    let label: String
    var tint: Color = Palette.ink
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(tint)
                .frame(width: 58, height: 58)
                .background(Circle().fill(Color.white).shadow(color: .black.opacity(0.12), radius: 4, y: 2))
        }
        .buttonStyle(BouncyButtonStyle())
        .accessibilityLabel(label)
    }
}

struct BigButton: View {
    let title: String
    let systemImage: String
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: systemImage)
                Text(title)
            }
            .font(.rounded(24, .heavy))
            .foregroundColor(.white)
            .padding(.horizontal, 26)
            .frame(minHeight: 64)
            .background(Capsule().fill(tint))
            .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
        }
        .buttonStyle(BouncyButtonStyle())
    }
}

/// Wiggles a wrong answer sideways.
struct Shake: GeometryEffect {
    var amount: CGFloat = 10
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX: amount * sin(animatableData * .pi * 4), y: 0))
    }
}

/// Stars flying out of the middle after a right answer. With "Reduce Motion" only one star fades in and out.
struct StarBurst: View {
    let trigger: Int
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var progress: CGFloat = 0
    @State private var visible = false

    private let colors: [Color] = [Palette.star, Tint.pink.color, Tint.blue.color, Tint.green.color, Tint.orange.color]
    private let count = 14

    var body: some View {
        ZStack {
            if reduceMotion {
                Image(systemName: "star.fill")
                    .font(.system(size: 120))
                    .foregroundColor(Palette.star)
            } else {
                ForEach(0..<count, id: \.self) { index in
                    let angle = Double(index) / Double(count) * 2 * .pi
                    Image(systemName: "star.fill")
                        .font(.system(size: index.isMultiple(of: 2) ? 38 : 26))
                        .foregroundColor(colors[index % colors.count])
                        .offset(x: cos(angle) * 190 * progress, y: sin(angle) * 190 * progress)
                        .scaleEffect(1.3 - 0.5 * progress)
                }
            }
        }
        .opacity(visible ? 1 : 0)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .onChange(of: trigger) { _ in fire() }
    }

    private func fire() {
        progress = 0
        visible = true
        withAnimation(.easeOut(duration: 0.9)) { progress = 1 }
        withAnimation(.easeIn(duration: 0.35).delay(0.75)) { visible = false }
    }
}

/// A number of emoji in rows, like on a ten frame. The last `leaving` items are shown fading away (minus).
struct EmojiCluster: View {
    let emoji: String
    let count: Int
    let columns: Int
    let size: CGSize
    var leaving = 0

    var body: some View {
        let perRow = max(1, min(columns, count))
        let rows = max(1, Int((Double(count) / Double(perRow)).rounded(.up)))
        let item = max(14, min(size.width / (CGFloat(perRow) * 1.12), size.height / (CGFloat(rows) * 1.15), 96))
        VStack(spacing: item * 0.12) {
            ForEach(0..<rows, id: \.self) { row in
                HStack(spacing: item * 0.12) {
                    ForEach((row * perRow)..<min(count, (row + 1) * perRow), id: \.self) { index in
                        let isLeaving = index >= count - leaving
                        Text(emoji)
                            .font(.system(size: item * 0.8))
                            .frame(width: item, height: item)
                            .opacity(isLeaving ? 0.25 : 1)
                            .offset(y: isLeaving ? -item * 0.18 : 0)
                    }
                }
            }
        }
    }
}

/// Close button, progress dots and "read again" button above every game.
struct GameTopBar: View {
    let done: Int
    let total: Int
    let showsSpeaker: Bool
    let onClose: () -> Void
    let onRepeat: () -> Void

    var body: some View {
        HStack {
            RoundIconButton(systemName: "xmark", label: "Zurück zur Wiese", action: onClose)
            Spacer()
            HStack(spacing: 8) {
                ForEach(0..<total, id: \.self) { index in
                    Circle()
                        .fill(index < done ? Palette.star : Color.white)
                        .frame(width: 16, height: 16)
                        .overlay(Circle().stroke(Palette.ink.opacity(0.15), lineWidth: 1))
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(done) von \(total) geschafft")
            Spacer()
            if showsSpeaker {
                RoundIconButton(systemName: "speaker.wave.2.fill", label: "Nochmal vorlesen", tint: Tint.blue.color, action: onRepeat)
            } else {
                Color.clear.frame(width: 58, height: 58)
            }
        }
    }
}

/// Shown after the last round: one more star (until all three are collected) and two big buttons.
struct FinishView: View {
    let stars: Int
    let onAgain: () -> Void
    let onHome: () -> Void
    @State private var appeared = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.25).ignoresSafeArea()
            VStack(spacing: 22) {
                Text("🎉").font(.system(size: 76)).accessibilityHidden(true)
                Text("Super gemacht!")
                    .font(.rounded(36, .heavy))
                    .foregroundColor(Palette.ink)
                StarsView(count: stars, size: 46)
                    .scaleEffect(appeared ? 1 : 0.4)
                ViewThatFitsOrStack {
                    BigButton(title: "Nochmal", systemImage: "arrow.counterclockwise", tint: Tint.blue.color, action: onAgain)
                    BigButton(title: "Zur Wiese", systemImage: "house.fill", tint: Palette.correct, action: onHome)
                }
            }
            .padding(28)
            .background(RoundedRectangle(cornerRadius: 36, style: .continuous).fill(Color.white))
            .padding(20)
            .frame(maxWidth: 560)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.5)) { appeared = true }
        }
    }
}

/// Places its content side by side when there is room, otherwise below each other.
struct ViewThatFitsOrStack<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        ViewThatFits {
            HStack(spacing: 16, content: content)
            VStack(spacing: 14, content: content)
        }
    }
}
