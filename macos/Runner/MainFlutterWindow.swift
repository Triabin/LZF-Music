import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    flutterViewController.backgroundColor = NSColor.clear
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)
    let visualEffectView = NSVisualEffectView(frame: self.contentView!.bounds)
    visualEffectView.autoresizingMask = [.width, .height]
    visualEffectView.material = .hudWindow  // 或 .fullScreenUI, .sidebar, .menu 等
    visualEffectView.blendingMode = .behindWindow
    visualEffectView.state = .active
    self.contentView?.addSubview(visualEffectView, positioned: .below, relativeTo: nil)
    super.awakeFromNib()
  }
}
