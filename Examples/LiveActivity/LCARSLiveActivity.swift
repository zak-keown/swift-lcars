import ActivityKit
import SwiftUI
import WidgetKit
import SwiftLCARS

@main
struct LCARSLiveActivityBundle: WidgetBundle {
    var body: some Widget { LCARSLiveActivity() }
}

struct LCARSLiveActivity: Widget {
    private let pickerURL = URL(string: "swiftlcars://themes")!
    private func theme(_ state: LCARSActivityAttributes.ContentState) -> LCARSTheme {
        LCARSTheme.presets.first { $0.id == state.themeID } ?? .classic
    }
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: LCARSActivityAttributes.self) { context in
            let theme = theme(context.state)
            HStack(spacing: 16) {
                LCARSElbow(metrics: .compact).fill(theme.primary.color).frame(width: 64, height: 48)
                VStack(alignment: .leading, spacing: 3) {
                    Text(context.state.themeName).font(LCARSTypography.display(30))
                    Text("Tap to change franchise").font(.caption)
                }
                Spacer()
                Image(systemName: "chevron.down")
            }
            .foregroundStyle(theme.primary.color).padding(18)
            .activityBackgroundTint(.black)
            .activitySystemActionForegroundColor(theme.primary.color)
            .widgetURL(pickerURL)
        } dynamicIsland: { context in
            let theme = theme(context.state)
            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    LCARSElbow(metrics: .compact).fill(theme.primary.color).frame(width: 64, height: 40)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("LCARS").font(LCARSTypography.display(28)).foregroundStyle(theme.secondary.color)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        Text(context.state.themeName).font(.headline)
                        Spacer()
                        Link(destination: pickerURL) { Label("Change franchise", systemImage: "chevron.down") }
                            .font(.callout)
                    }.foregroundStyle(theme.primary.color).padding(.top, 8)
                }
            } compactLeading: {
                Text("LC").font(LCARSTypography.display(24)).foregroundStyle(theme.primary.color)
                    .accessibilityLabel("LCARS")
            } compactTrailing: {
                Circle().fill(theme.secondary.color).frame(width: 12, height: 12)
                    .accessibilityLabel(context.state.themeName)
            } minimal: {
                Text("LC").font(LCARSTypography.display(24)).foregroundStyle(theme.primary.color)
                    .accessibilityLabel("LCARS. Change franchise")
            }
            .widgetURL(pickerURL)
            .keylineTint(theme.primary.color)
        }
    }
}
