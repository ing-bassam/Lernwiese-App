import SwiftUI

@main
struct LernwieseApp: App {
    @StateObject private var progress = ProgressStore.shared
    @StateObject private var settings = AppSettings.shared
    @Environment(\.scenePhase) private var scenePhase

    init() {
        DemoContent.prepareIfNeeded()
        Speaker.shared.prepareAudioSession()
    }

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(progress)
                .environmentObject(settings)
                .preferredColorScheme(.light)
        }
        .onChange(of: scenePhase) { phase in
            // Parents may have downloaded a more natural voice in the iOS settings.
            if phase == .active {
                Speaker.shared.refreshVoices()
            }
        }
    }
}
