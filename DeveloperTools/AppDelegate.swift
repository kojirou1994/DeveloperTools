import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {

  func applicationDidFinishLaunching(_ aNotification: Notification) {
    // Create the SwiftUI view that provides the window contents.
//    let contentView = ContentView()
//
//    // Create the window and set the content view.
//    window = NSWindow(
//      contentRect: NSRect(x: 0, y: 0, width: 480, height: 300),
//      styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
//      backing: .buffered, defer: false)
//    window.center()
//    window.title = "Developer Tools"
//    window.titlebarAppearsTransparent = true
//    window.setFrameAutosaveName("Main Window")
  }

  func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    true
  }

}

