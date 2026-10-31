import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var progress: ProgressStore
    @EnvironmentObject private var settings: AppSettings
    @State private var activeGame: GameID?
    @State private var showingParents = false

    var body: some View {
        ZStack {
            MeadowBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 26) {
                    header
                    ForEach(World.allCases) { world in
                        worldSection(world)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 48)
                .frame(maxWidth: 960)
                .frame(maxWidth: .infinity)
            }
        }
        .fullScreenCover(item: $activeGame) { game in
            GameContainer(game: game) { activeGame = nil }
                .environmentObject(progress)
                .environmentObject(settings)
        }
        .sheet(isPresented: $showingParents) {
            ParentFlowView()
                .environmentObject(progress)
                .environmentObject(settings)
        }
        .onAppear {
            if let game = DemoContent.launchGame {
                activeGame = game
            } else if DemoContent.launchScreen == "parents" {
                showingParents = true
            }
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Lernwiese")
                    .font(.rounded(42, .heavy))
                    .foregroundColor(Palette.ink)
                    .accessibilityAddTraits(.isHeader)
                HStack(spacing: 6) {
                    Image(systemName: "star.fill").foregroundColor(Palette.star)
                    Text("\(progress.total)")
                        .foregroundColor(Palette.ink)
                }
                .font(.rounded(22, .heavy))
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(Capsule().fill(Color.white.opacity(0.9)))
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(progress.total) Sterne gesammelt")
            }
            Spacer()
            Button {
                showingParents = true
            } label: {
                VStack(spacing: 2) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 20, weight: .bold))
                    Text("Eltern")
                        .font(.rounded(13, .bold))
                }
                .foregroundColor(Palette.ink)
                .frame(width: 66, height: 66)
                .background(Circle().fill(Color.white).shadow(color: .black.opacity(0.12), radius: 4, y: 2))
            }
            .buttonStyle(BouncyButtonStyle())
            .accessibilityLabel("Eltern-Bereich")
        }
    }

    private func worldSection(_ world: World) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("\(world.emoji) \(world.title)")
                .font(.rounded(28, .heavy))
                .foregroundColor(Palette.ink)
                .accessibilityLabel(world.title)
                .accessibilityAddTraits(.isHeader)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150, maximum: 280), spacing: 14)], spacing: 14) {
                ForEach(world.games) { game in
                    GameTile(game: game, stars: progress.stars(for: game)) {
                        activeGame = game
                    }
                }
            }
        }
    }
}

struct GameTile: View {
    let game: GameID
    let stars: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(game.emoji)
                    .font(.system(size: 50))
                    .frame(width: 86, height: 86)
                    .background(Circle().fill(game.tint.color.opacity(0.18)))
                Text(game.title)
                    .font(.rounded(18, .heavy))
                    .foregroundColor(Palette.ink)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
                    .frame(minHeight: 46)
                StarsView(count: stars, size: 17)
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 10)
            .frame(maxWidth: .infinity)
            .background(RoundedRectangle(cornerRadius: 26, style: .continuous).fill(Color.white))
            .overlay(RoundedRectangle(cornerRadius: 26, style: .continuous).stroke(game.tint.color, lineWidth: 4))
            .shadow(color: .black.opacity(0.1), radius: 6, y: 3)
        }
        .buttonStyle(BouncyButtonStyle())
        .accessibilityLabel("\(game.title), \(stars) von \(ProgressStore.maxStars) Sternen")
    }
}

/// Starts a game with the difficulty that matches the stars collected so far.
struct GameContainer: View {
    let game: GameID
    let onClose: () -> Void
    @EnvironmentObject private var progress: ProgressStore
    @State private var session = 0

    var body: some View {
        Group {
            if game.isMemory {
                MemoryGameView(game: game, level: level, seed: seed, speaksIntro: session == 0,
                               onAgain: again, onClose: close)
            } else {
                QuizGameView(game: game, level: level, seed: seed, speaksIntro: session == 0,
                             onAgain: again, onClose: close)
            }
        }
        .id(session)
    }

    private var level: Int {
        DemoContent.isActive ? DemoContent.level : progress.level(for: game)
    }

    private var seed: UInt64 {
        DemoContent.isActive ? DemoContent.seed : UInt64.random(in: 1...UInt64.max)
    }

    private func again() {
        session += 1
    }

    private func close() {
        Speaker.shared.stop()
        onClose()
    }
}
