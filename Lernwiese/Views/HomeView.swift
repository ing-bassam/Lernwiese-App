import SwiftUI

/// The meadow, with the break screen on top once the daily time is used up.
struct RootView: View {
    @EnvironmentObject private var settings: AppSettings
    @ObservedObject private var playTime = PlayTimeStore.shared

    private var resting: Bool {
        DemoContent.launchScreen == "rest" || playTime.status(settings: settings) == .over
    }

    var body: some View {
        ZStack {
            HomeView(resting: resting)
            if resting {
                RestView()
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .animation(.easeInOut(duration: 0.6), value: resting)
        .onChange(of: resting) { isResting in
            if !isResting {
                MusicPlayer.shared.setMood(.meadow)
            }
        }
    }
}

struct HomeView: View {
    let resting: Bool
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
                    ForEach(World.allCases.filter { !visibleGames($0).isEmpty }) { world in
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
        .timeNotice()
        .onChange(of: resting) { isResting in
            guard isResting else { return }
            activeGame = nil
            showingParents = false
        }
        .onChange(of: activeGame) { game in
            if game == nil && !resting {
                MusicPlayer.shared.setMood(.meadow)
            }
        }
        .onAppear {
            if !resting {
                MusicPlayer.shared.setMood(.meadow)
            }
            if let game = DemoContent.launchGame {
                activeGame = game
            } else if DemoContent.launchScreen == "parents" {
                showingParents = true
            }
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            Mascot(mood: .waving, size: 92)
            VStack(alignment: .leading, spacing: 6) {
                Text("Lernwiese")
                    .font(.rounded(42, .heavy))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
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

    private func visibleGames(_ world: World) -> [GameID] {
        world.games.filter(settings.isVisible)
    }

    private func worldSection(_ world: World) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("\(world.emoji) \(world.title)")
                .font(.rounded(28, .heavy))
                .foregroundColor(Palette.ink)
                .accessibilityLabel(world.title)
                .accessibilityAddTraits(.isHeader)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150, maximum: 280), spacing: 14)], spacing: 14) {
                ForEach(visibleGames(world)) { game in
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
            switch game.kind {
            case .memory:
                MemoryGameView(game: game, level: level, seed: seed, speaksIntro: session == 0,
                               onAgain: again, onClose: close)
            case .shapes:
                ShapeGameView(game: game, level: level, seed: seed, speaksIntro: session == 0,
                              onAgain: again, onClose: close)
            case .echo:
                EchoGameView(game: game, level: level, seed: seed, speaksIntro: session == 0,
                             onAgain: again, onClose: close)
            case .quiz:
                QuizGameView(game: game, level: level, seed: seed, speaksIntro: session == 0,
                             onAgain: again, onClose: close)
            }
        }
        .id(session)
        .timeNotice()
        .onAppear {
            // The tone game is about listening, so the background music stays quiet there.
            MusicPlayer.shared.setMood(game.kind == .echo ? .silent : .play)
        }
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
