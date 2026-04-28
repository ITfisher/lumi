import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    titleVisibility = .hidden
    titlebarAppearsTransparent = true
    styleMask.insert(.fullSizeContentView)

    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)
    let clipboardChannel = FlutterMethodChannel(
      name: "com.lumi/clipboard_image",
      binaryMessenger: flutterViewController.engine.binaryMessenger
    )
    clipboardChannel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else {
        result(nil)
        return
      }

      switch call.method {
      case "readImageBytes":
        result(self.readClipboardImageBytes())
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    super.awakeFromNib()
  }

  private func readClipboardImageBytes() -> FlutterStandardTypedData? {
    let pasteboard = NSPasteboard.general

    if let fileURLs = pasteboard.readObjects(
      forClasses: [NSURL.self],
      options: [.urlReadingFileURLsOnly: true]
    ) as? [URL] {
      for url in fileURLs where isSupportedImageFile(url) {
        if let image = NSImage(contentsOf: url), let data = pngData(from: image) {
          return FlutterStandardTypedData(bytes: data)
        }
      }
    }

    if let image = NSImage(pasteboard: pasteboard), let data = pngData(from: image) {
      return FlutterStandardTypedData(bytes: data)
    }

    return nil
  }

  private func pngData(from image: NSImage) -> Data? {
    guard
      let tiffData = image.tiffRepresentation,
      let bitmap = NSBitmapImageRep(data: tiffData)
    else {
      return nil
    }

    return bitmap.representation(using: .png, properties: [:])
  }

  private func isSupportedImageFile(_ url: URL) -> Bool {
    let supportedExtensions = ["png", "jpg", "jpeg", "gif", "webp", "heic", "heif", "tiff"]
    return supportedExtensions.contains(url.pathExtension.lowercased())
  }
}
