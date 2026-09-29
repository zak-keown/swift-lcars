#if os(iOS)
import ActivityKit
import SwiftUI
import SwiftLCARS

@MainActor
final class LiveActivityController: ObservableObject {
    @Published var isRunning = false
    @Published private(set) var isStopping = false
    @Published var error: String?
    private var observation: Task<Void, Never>?
    private var updateTask: Task<Void, Never>?
    private var stopTask: Task<Void, Never>?

    init() {
        if let existing = Activity<LCARSActivityAttributes>.activities.first { observe(existing) }
    }
    deinit { observation?.cancel(); updateTask?.cancel(); stopTask?.cancel() }

    func start(theme: LCARSTheme) {
        guard !isStopping else { return }
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            error = "Live Activities are disabled for this device or app. Enable them in Settings to show the franchise in the Dynamic Island."
            return
        }
        if let existing = Activity<LCARSActivityAttributes>.activities.first {
            observe(existing); update(theme: theme); return
        }
        do {
            let activity = try Activity.request(
                attributes: LCARSActivityAttributes(sessionName: "LCARS Catalog"),
                content: ActivityContent(state: .init(themeID: theme.id, themeName: theme.name), staleDate: nil),
                pushType: nil)
            observe(activity)
        } catch { self.error = error.localizedDescription }
    }

    func update(theme: LCARSTheme) {
        guard !isStopping else { return }
        updateTask?.cancel()
        updateTask = Task {
            let content = ActivityContent(state: LCARSActivityAttributes.ContentState(themeID: theme.id, themeName: theme.name), staleDate: nil)
            for activity in Activity<LCARSActivityAttributes>.activities {
                guard !Task.isCancelled else { return }
                await activity.update(content)
            }
        }
    }

    func stop() {
        guard !isStopping else { return }
        isStopping = true
        observation?.cancel()
        updateTask?.cancel()
        stopTask = Task {
            for activity in Activity<LCARSActivityAttributes>.activities {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
            isRunning = false
            isStopping = false
        }
    }

    private func observe(_ activity: Activity<LCARSActivityAttributes>) {
        observation?.cancel()
        isRunning = activity.activityState == .active || activity.activityState == .stale
        observation = Task { [weak self] in
            for await state in activity.activityStateUpdates {
                guard !Task.isCancelled else { return }
                self?.isRunning = state == .active || state == .stale
            }
        }
    }
}
#endif
