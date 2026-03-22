import SwiftUI

@main
struct RouteToneApp: App {
    @NSApplicationDelegateAdaptor(ApplicationDelegate.self) private var appDelegate
    @StateObject private var model: AudioPriorityModel

    init() {
        let model = AudioPriorityModel()
        _model = StateObject(wrappedValue: model)
        ApplicationDelegate.sharedModel = model
    }

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
