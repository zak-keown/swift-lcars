#if os(iOS)
import ActivityKit

struct LCARSActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var themeID: String
        var themeName: String
    }
    var sessionName: String
}
#endif
