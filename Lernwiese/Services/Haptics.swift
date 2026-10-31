import UIKit

/// Gentle vibrations as feedback. Wrong answers only get a soft tap – never anything that feels like a punishment.
enum Haptics {
    private static var isEnabled: Bool {
        AppSettings.shared.hapticsEnabled && !AppSettings.shared.isDemo
    }

    @MainActor
    static func success() {
        guard isEnabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    @MainActor
    static func gentle() {
        guard isEnabled else { return }
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
    }

    @MainActor
    static func tap() {
        guard isEnabled else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}
