/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import RxSwift
import PureLayout
import WebKit
import EonilFileSystemEvents

fileprivate let fileSystemEventsLatency = 1.0
fileprivate let monitorDispatchQueue = DispatchQueue.global(qos: .userInitiated)

class HtmlPreviewTool: NSView, UiComponent, WKNavigationDelegate {

  enum Action {

    case selectHtmlFile(URL)
  }

  typealias StateType = MainWindow.State

  let innerCustomToolbar = InnerCustomToolbar()

  required init(source: Observable<StateType>, emitter: ActionEmitter, state: StateType) {
    self.emit = emitter.typedEmit()
    self.uuid = state.uuid

    let configuration = WKWebViewConfiguration()
    self.webview = WKWebView(frame: CGRect.zero, configuration: configuration)

    super.init(frame: .zero)
    self.configureForAutoLayout()

    self.webview.navigationDelegate = self
    self.innerCustomToolbar.htmlPreviewTool = self

    self.addViews()

    if let serverUrl = state.htmlPreview.server?.payload {
      self.webview.load(URLRequest(url: serverUrl))
    }

    source
      .observeOn(MainScheduler.instance)
      .subscribe(onNext: { [unowned self] state in
        guard let serverUrl = state.htmlPreview.server, let htmlFileUrl = state.htmlPreview.htmlFile else {
          self.monitor = nil
          return
        }

        if serverUrl.mark == self.mark {
          return
        }

        self.monitor = FileSystemEventMonitor(pathsToWatch: [htmlFileUrl.path],
                                              latency: fileSystemEventsLatency,
                                              watchRoot: false,
                                              queue: monitorDispatchQueue)
        { [unowned self] events in
          self.reloadWebview(with: serverUrl.payload)
        }

        self.innerCustomToolbar.selectHtmlFile.toolTip = (htmlFileUrl.path as NSString).abbreviatingWithTildeInPath
        self.mark = serverUrl.mark
        self.reloadWebview(with: serverUrl.payload)
      })
      .disposed(by: self.disposeBag)
  }

  fileprivate func reloadWebview(with url: URL) {
    self.webview.evaluateJavaScript("document.body.scrollTop") { (result, error) in
      self.scrollTop = result as? Int ?? 0

      self.webview.load(URLRequest(url: url))
    }
  }

  fileprivate func addViews() {
    self.webview.configureForAutoLayout()

    self.addSubview(self.webview)
    self.webview.autoPinEdgesToSuperviewEdges()
  }

  fileprivate let emit: (UuidAction<Action>) -> Void
  fileprivate let uuid: String

  fileprivate var mark = Token()
  fileprivate var scrollTop = 0

  fileprivate let webview: WKWebView
  fileprivate var monitor: FileSystemEventMonitor?

  fileprivate let disposeBag = DisposeBag()

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func selectHtmlFile(sender: Any?) {
    let panel = NSOpenPanel()
    panel.canChooseDirectories = false
    panel.allowsMultipleSelection = false
    panel.beginSheetModal(for: self.window!) { result in
      guard result == NSFileHandlingPanelOKButton else {
        return
      }

      let urls = panel.urls
      guard urls.count == 1 else {
        return
      }

      self.emit(UuidAction(uuid: self.uuid, action: .selectHtmlFile(urls[0])))
    }
  }

  func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
    self.webview.evaluateJavaScript("document.body.scrollTop = \(self.scrollTop)")
  }
}

extension HtmlPreviewTool {

  class InnerCustomToolbar: CustomToolBar {

    fileprivate weak var htmlPreviewTool: HtmlPreviewTool? {
      didSet {
        self.selectHtmlFile.target = self.htmlPreviewTool
      }
    }

    let selectHtmlFile = NSButton(forAutoLayout: ())

    init() {
      super.init(frame: .zero)
      self.configureForAutoLayout()

      self.addViews()
    }

    override func repaint(with: Workspace.Theme) {

    }

    fileprivate func addViews() {
      let selectHtmlFile = self.selectHtmlFile
      InnerToolBar.configureToStandardIconButton(button: selectHtmlFile, iconName: .fileCodeO)
      selectHtmlFile.toolTip = "Select the HTML file"
      selectHtmlFile.action = #selector(HtmlPreviewTool.selectHtmlFile)

      self.addSubview(selectHtmlFile)

      selectHtmlFile.autoPinEdge(toSuperviewEdge: .top)
      selectHtmlFile.autoPinEdge(toSuperviewEdge: .right)
    }

    required init?(coder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
    }
  }
}
