import SwiftUI

@main
struct DeveloperTools: App {

  @NSApplicationDelegateAdaptor
  private var delegate: AppDelegate

  var body: some Scene {
    WindowGroup {
      ContentView()
    }
    .windowToolbarStyle(DefaultWindowToolbarStyle())
  }
}
