import SwiftUI

@main
struct LernwieseApp: App {
    @StateObject private var progress = ProgressStore.shared
    @StateObject private var settings = AppSettings.shared
    @Environment(\.scenePhase) private var scenePhase

    init() {
        DemoContent.prepareIfNeeded()
        Speaker.shared.prepareAudioSession()
        MusicPlayer.shared.prepare()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(progress)
                .environmentObject(settings)
                .preferredColorScheme(.light)
        }
        .onChange(of: scenePhase) { phase in
            // Parents may have downloaded a more natural voice in the iOS settings.
            if phase == .active {
                Speaker.shared.refreshVoices()
                MusicPlayer.shared.resume()
                if !DemoContent.isActive {
                    PlayTimeStore.shared.startCounting()
                }
            } else {
                PlayTimeStore.shared.stopCounting()
            }
        }
    }
}
