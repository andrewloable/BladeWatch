import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    // BladeWatch-sjz4: black from the first frame, like every other launch screen of the
    // companion, so the window never flashes white before the animated intro draws.
    flutterViewController.backgroundColor = .black
    self.backgroundColor = .black
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
