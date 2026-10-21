import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)
    // Register before the first open event so a cold start can queue the path.
    TdcOpenFileCenter.register(
      with: flutterViewController.registrar(forPlugin: "TdcOpenFileCenter"))

    super.awakeFromNib()
  }
}
