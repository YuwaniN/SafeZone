import Foundation
import SwiftUI

@MainActor
final class AlertCenter: ObservableObject {
    @Published var banner: AlertBanner?

    private var dismissTask: Task<Void, Never>?

    func present(_ banner: AlertBanner) {
        dismissTask?.cancel()
        withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
            self.banner = banner
        }
        dismissTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(9))
            guard !Task.isCancelled else { return }
            self?.dismiss()
        }
    }

    func dismiss() {
        dismissTask?.cancel()
        dismissTask = nil
        withAnimation(.easeInOut(duration: 0.25)) {
            banner = nil
        }
    }
}
