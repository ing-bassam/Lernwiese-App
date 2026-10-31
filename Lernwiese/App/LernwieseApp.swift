import SwiftUI

@main
struct LernwieseApp: App {
    @StateObject private var progress = ProgressStore.shared
    @StateObject private var settings = AppSettings.shared

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
    }
}
