import SwiftUI
import SwiftLCARS

@main
struct CatalogApp: App {
    var body: some Scene {
        WindowGroup("LCARS Catalog") {
            CatalogView()
                .preferredColorScheme(.dark)
                #if os(macOS)
                .frame(minWidth: 540, minHeight: 640)
                #endif
        }
        #if os(macOS)
        .defaultSize(width: 1280, height: 920)
        #endif
    }
}
