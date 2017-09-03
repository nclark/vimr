import Cocoa
import PureLayout

fileprivate let gap = CGFloat(4.0)

class WindowController: NSWindowController, NSWindowDelegate {

  fileprivate var titlebarThemed = false
  fileprivate var repIcon: NSButton?
  fileprivate var titleView: NSTextField?

  fileprivate func themeTitlebar() {
    guard let window = self.window else {
      return
    }

    if window.styleMask.contains(.fullScreen) {
      return
    }

    self.root.removeFromSuperview()

    self.set(repUrl: window.representedURL, themed: true)

    window.contentView?.addSubview(self.root)
    self.root.autoPinEdge(toSuperviewEdge: .top, withInset: 22)
    self.root.autoPinEdge(toSuperviewEdge: .right)
    self.root.autoPinEdge(toSuperviewEdge: .bottom)
    self.root.autoPinEdge(toSuperviewEdge: .left)

    self.titlebarThemed = true
  }

  fileprivate func unthemeTitlebar(dueFullScreen: Bool) {
    self.repIcon?.removeFromSuperview()
    self.titleView?.removeFromSuperview()

    self.repIcon = nil
    self.titleView = nil

    self.root.removeFromSuperview()

    guard let window = self.window, let contentView = window.contentView else {
      return
    }

    window.titleVisibility = .visible
    window.styleMask.remove(.fullSizeContentView)

    self.set(repUrl: window.representedURL, themed: false)

    contentView.addSubview(self.root)
    self.root.autoPinEdgesToSuperviewEdges()

    if !dueFullScreen {
      self.titlebarThemed = false
    }
  }

  func windowWillEnterFullScreen(_: Notification) {
    self.unthemeTitlebar(dueFullScreen: true)
  }

  func windowDidExitFullScreen(_: Notification) {
    if self.titlebarThemed {
      self.themeTitlebar(nil)
    }
  }

  fileprivate func set(repUrl url: URL?, themed: Bool) {
    guard let window = self.window else {
      return
    }

    if window.styleMask.contains(.fullScreen) || themed == false {
      window.representedURL = nil
      window.representedURL = url

      window.title = url?.lastPathComponent ?? "Title"
      return
    }

    self.titleView?.removeFromSuperview()
    self.repIcon?.removeFromSuperview()

    window.titleVisibility = .visible
    window.representedURL = nil
    window.representedURL = url
    window.title = url?.lastPathComponent ?? "Title"

    guard let button = window.standardWindowButton(.documentIconButton), let contentView = window.contentView else {
      NSLog("No button or content view!")
      return
    }

    window.titleVisibility = .hidden
    window.styleMask.insert(.fullSizeContentView)

    button.removeFromSuperview() // remove the rep icon from the original superview and add it to content view
    contentView.addSubview(button)
    button.autoSetDimension(.width, toSize: 16)
    button.autoSetDimension(.height, toSize: 16)
    button.autoPinEdge(toSuperviewEdge: .top, withInset: 3)

    let title = NSTextField(labelWithString: window.title)
    title.configureForAutoLayout()
    contentView.addSubview(title)
    title.autoPinEdge(toSuperviewEdge: .top, withInset: 2)

    // Center the rep icon and the title side by side in the content view:
    // rightView.left = leftView.right + gap
    // rightView.right = parentView.centerX + (leftView.width + gap + rightView.width) / 2
    contentView.addConstraint(NSLayoutConstraint(item: title, attribute: .left,
                                                 relatedBy: .equal,
                                                 toItem: button, attribute: .right,
                                                 multiplier: 1,
                                                 constant: gap))
    contentView.addConstraint(NSLayoutConstraint(item: title, attribute: .right,
                                                 relatedBy: .equal,
                                                 toItem: contentView, attribute: .centerX,
                                                 multiplier: 1,
                                                 constant: (button.frame.width + gap + title.frame.width) / 2))

    self.repIcon = button
    self.titleView = title
  }

  // ====== >8 ======

  fileprivate let root = ColorView(bg: .green)

  override func windowDidLoad() {
    super.windowDidLoad()

    guard let window = self.window else {
      return
    }

    window.delegate = self
    window.backgroundColor = .yellow
    window.titlebarAppearsTransparent = true

    guard let contentView = window.contentView else {
      return
    }

    contentView.addSubview(self.root)
    self.root.autoPinEdgesToSuperviewEdges()
  }

  @IBAction func setRepUrl1(_: Any?) {
    self.set(repUrl: URL(fileURLWithPath: "/Users/hat/big.txt"), themed: self.titlebarThemed)
  }

  @IBAction func setRepUrl2(_: Any?) {
    self.set(repUrl: URL(fileURLWithPath: "/Users/hat/greek.tex"), themed: self.titlebarThemed)
  }

  @IBAction func themeTitlebar(_: Any?) {
    self.themeTitlebar()
  }

  @IBAction func unthemeTitlebar(_: Any?) {
    self.unthemeTitlebar(dueFullScreen: false)
  }
}

class ColorView: NSView {

  fileprivate let color: NSColor

  init(bg: NSColor) {
    self.color = bg

    super.init(frame: .zero)
    self.configureForAutoLayout()

    self.wantsLayer = true
    self.layer?.backgroundColor = bg.cgColor
  }

  override func draw(_ dirtyRect: NSRect) {
    super.draw(dirtyRect)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
