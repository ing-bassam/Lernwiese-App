import SwiftUI

/// Pieks, the little hedgehog who lives on the meadow. Drawn only with SwiftUI shapes.
struct Mascot: View {
    enum Mood {
        case happy, waving, sleepy, thinking
    }

    var mood: Mood = .happy
    var size: CGFloat = 120

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var blink = false
    @State private var bob = false

    private let spikes = Color(red: 0.47, green: 0.33, blue: 0.24)
    private let spikesDark = Color(red: 0.36, green: 0.24, blue: 0.17)
    private let skin = Color(red: 0.98, green: 0.85, blue: 0.68)
    private let cheek = Color(red: 0.97, green: 0.58, blue: 0.58)

    var body: some View {
        ZStack {
            // Spiky back
            SpikeShape(count: 9)
                .fill(spikesDark)
                .frame(width: size * 0.98, height: size * 0.8)
                .offset(x: size * 0.06, y: -size * 0.02)
            SpikeShape(count: 8)
                .fill(spikes)
                .frame(width: size * 0.88, height: size * 0.7)
                .offset(x: size * 0.08, y: size * 0.02)
            // Feet
            HStack(spacing: size * 0.22) {
                foot
                foot
            }
            .offset(y: size * 0.36)
            // Face
            Ellipse()
                .fill(skin)
                .frame(width: size * 0.56, height: size * 0.5)
                .offset(x: -size * 0.16, y: size * 0.1)
            // Snout and nose
            Ellipse()
                .fill(skin)
                .frame(width: size * 0.32, height: size * 0.22)
                .offset(x: -size * 0.38, y: size * 0.16)
            Circle()
                .fill(Palette.ink)
                .frame(width: size * 0.1, height: size * 0.1)
                .offset(x: -size * 0.53, y: size * 0.12)
            // Ear
            Circle()
                .fill(skin)
                .frame(width: size * 0.14, height: size * 0.14)
                .overlay(Circle().fill(cheek.opacity(0.6)).padding(size * 0.03))
                .offset(x: -size * 0.02, y: -size * 0.1)
            eye
                .offset(x: -size * 0.26, y: size * 0.04)
            // Cheek
            Ellipse()
                .fill(cheek.opacity(0.55))
                .frame(width: size * 0.1, height: size * 0.06)
                .offset(x: -size * 0.16, y: size * 0.17)
            mouth
                .offset(x: -size * 0.37, y: size * 0.26)
            if mood == .waving {
                Capsule()
                    .fill(skin)
                    .frame(width: size * 0.1, height: size * 0.26)
                    .rotationEffect(.degrees(bob ? -35 : -10), anchor: .bottom)
                    .offset(x: -size * 0.05, y: size * 0.08)
            }
            if mood == .sleepy {
                Text("z z")
                    .font(.rounded(size * 0.16, .heavy))
                    .foregroundColor(Palette.ink.opacity(0.5))
                    .offset(x: size * 0.1, y: -size * 0.5 + (bob ? -4 : 4))
            }
            if mood == .thinking {
                Text("?")
                    .font(.rounded(size * 0.26, .heavy))
                    .foregroundColor(Tint.blue.color)
                    .offset(x: -size * 0.2, y: -size * 0.45)
            }
        }
        .frame(width: size * 1.15, height: size)
        .offset(y: reduceMotion ? 0 : (bob ? -size * 0.02 : size * 0.02))
        .accessibilityHidden(true)
        .onAppear(perform: animate)
    }

    private var foot: some View {
        Ellipse()
            .fill(spikesDark)
            .frame(width: size * 0.16, height: size * 0.1)
    }

    @ViewBuilder private var eye: some View {
        if mood == .sleepy || blink {
            Capsule()
                .fill(Palette.ink)
                .frame(width: size * 0.09, height: size * 0.025)
        } else {
            Circle()
                .fill(Palette.ink)
                .frame(width: size * 0.09, height: size * 0.09)
                .overlay(Circle().fill(Color.white).frame(width: size * 0.03, height: size * 0.03)
                    .offset(x: -size * 0.015, y: -size * 0.015))
        }
    }

    @ViewBuilder private var mouth: some View {
        if mood == .sleepy {
            Circle()
                .stroke(Palette.ink, lineWidth: max(1.5, size * 0.018))
                .frame(width: size * 0.05, height: size * 0.05)
        } else {
            SmileShape()
                .stroke(Palette.ink, style: StrokeStyle(lineWidth: max(1.5, size * 0.022), lineCap: .round))
                .frame(width: size * 0.12, height: size * 0.05)
        }
    }

    private func animate() {
        guard !reduceMotion, !DemoContent.isActive else { return }
        withAnimation(.easeInOut(duration: mood == .sleepy ? 2.2 : 1.1).repeatForever(autoreverses: true)) {
            bob = true
        }
        scheduleBlink()
    }

    private func scheduleBlink() {
        DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 2.5...5)) {
            blink = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                blink = false
                scheduleBlink()
            }
        }
    }
}

/// Half an oval with a zigzag edge – the hedgehog's spikes.
struct SpikeShape: Shape {
    let count: Int

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.maxY * 0.92)
        let outer = CGSize(width: rect.width / 2, height: rect.height * 0.92)
        let inner = CGSize(width: outer.width * 0.82, height: outer.height * 0.8)
        let points = count * 2
        path.move(to: CGPoint(x: center.x - outer.width, y: center.y))
        for step in 0...points {
            let angle = Double.pi - Double.pi * Double(step) / Double(points)
            let radius = step.isMultiple(of: 2) ? inner : outer
            path.addLine(to: CGPoint(x: center.x + CGFloat(cos(angle)) * radius.width,
                                     y: center.y - CGFloat(sin(angle)) * radius.height))
        }
        path.closeSubpath()
        return path
    }
}

struct SmileShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY), control: CGPoint(x: rect.midX, y: rect.maxY * 1.6))
        return path
    }
}

/// Pieks with a speech bubble.
struct MascotSays: View {
    let text: String
    var mood: Mascot.Mood = .happy
    var size: CGFloat = 96

    var body: some View {
        HStack(alignment: .center, spacing: 6) {
            Mascot(mood: mood, size: size)
            Text(text)
                .font(.rounded(max(16, size * 0.19), .heavy))
                .foregroundColor(Palette.ink)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color.white)
                        .shadow(color: .black.opacity(0.1), radius: 4, y: 2))
        }
        .accessibilityElement(children: .combine)
    }
}
