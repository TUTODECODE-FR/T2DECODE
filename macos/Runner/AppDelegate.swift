import Cocoa
import FlutterMacOS

/// Queues `.tdc` paths from Finder until Dart calls `getPendingFiles`.
/// The Dart side validates the TDC Studio hierarchy before import.
final class TdcOpenFileCenter: NSObject {
  static let channelName = "org.t2decode.app/open_files"
  private static var channel: FlutterMethodChannel?
  private static var pendingPaths: [String] = []
  private static var lastDelivery: [String: TimeInterval] = [:]

  static func register(with registrar: FlutterPluginRegistrar) {
    let methodChannel = FlutterMethodChannel(
      name: channelName,
      binaryMessenger: registrar.messenger)
    methodChannel.setMethodCallHandler { call, result in
      if call.method == "getPendingFiles" {
        let paths = pendingPaths
        pendingPaths.removeAll()
        result(paths)
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
    channel = methodChannel
    if !pendingPaths.isEmpty {
      methodChannel.invokeMethod("openFiles", arguments: nil)
    }
  }

  /// Kept so a sandboxed build can read the file Dart opens by path.
  private static var scopedURLs: [URL] = []

  static func enqueue(_ path: String) {
    enqueueURL(URL(fileURLWithPath: path))
  }

  static func enqueueURL(_ url: URL) {
    guard url.isFileURL else { return }
    let normalized = url.standardizedFileURL.path
    let name = (normalized as NSString).lastPathComponent
    if name.isEmpty || name == "." || name == ".." { return }
    if !name.lowercased().hasSuffix(".tdc") { return }
    let now = Date().timeIntervalSince1970
    if let previous = lastDelivery[normalized], now - previous < 1.0 {
      return
    }
    lastDelivery[normalized] = now
    if url.startAccessingSecurityScopedResource() {
      scopedURLs.append(url)
      if scopedURLs.count > 32 {
        scopedURLs.removeFirst(scopedURLs.count - 32)
      }
    }
    if !pendingPaths.contains(normalized) {
      pendingPaths.append(normalized)
    }
    channel?.invokeMethod("openFiles", arguments: nil)
  }
}

@main
class AppDelegate: FlutterAppDelegate {
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }

  override func applicationDidFinishLaunching(_ notification: Notification) {
    for arg in CommandLine.arguments.dropFirst() {
      TdcOpenFileCenter.enqueue(arg)
    }
  }

  /// Finder, `open`, and Launch Services. `.tdc` paths are queued for Dart.
  /// Other URLs stay on Flutter's plugin forwarder.
  override func application(_ application: NSApplication, open urls: [URL]) {
    var forwarded: [URL] = []
    var openedCourse = false
    for url in urls {
      if url.isFileURL && url.pathExtension.lowercased() == "tdc" {
        TdcOpenFileCenter.enqueueURL(url)
        openedCourse = true
      } else {
        forwarded.append(url)
      }
    }
    if openedCourse {
      revealWindow()
    }
    if !forwarded.isEmpty {
      super.application(application, open: forwarded)
    }
  }

  /// Legacy single-file open.
  override func application(_ sender: NSApplication, openFile filename: String) -> Bool {
    guard (filename as NSString).pathExtension.lowercased() == "tdc" else {
      return false
    }
    TdcOpenFileCenter.enqueue(filename)
    revealWindow()
    return true
  }

  private func revealWindow() {
    if #available(macOS 14.0, *) {
      NSApp.activate()
    } else {
      NSApp.activate(ignoringOtherApps: true)
    }
    mainFlutterWindow?.makeKeyAndOrderFront(nil)
  }
}
