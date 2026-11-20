import SwiftUI
import WebKit

/// Owns the WKWebView and mirrors the Android app's behaviour:
/// pay101 domains load in-app over HTTPS, everything else opens in Safari or the right app.
@MainActor
final class WebViewModel: NSObject, ObservableObject, WKNavigationDelegate, WKUIDelegate {

    static let homeURL = URL(string: "https://pay101.io/")!
    /// Hosts that load inside the app (subdomains included).
    static let allowedHosts = ["pay101.io", "pay101.uk"]

    @Published var progress: Double = 0
    @Published var isLoading = false
    @Published var showError = false
    @Published var hasLoadedOnce = false

    let webView: WKWebView
    private let refreshControl = UIRefreshControl()
    private var observations: [NSKeyValueObservation] = []

    override init() {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .default()          // keeps login cookies between launches
        config.allowsInlineMediaPlayback = true
        config.applicationNameForUserAgent = "Mobile/15E148 Pay101iOS/1.0"
        webView = WKWebView(frame: .zero, configuration: config)
        super.init()

        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.allowsBackForwardNavigationGestures = true   // swipe to go back/forward
        webView.isOpaque = false
        webView.backgroundColor = .systemBackground

        refreshControl.addTarget(self, action: #selector(pulledToRefresh), for: .valueChanged)
        webView.scrollView.refreshControl = refreshControl

        observations = [
            webView.observe(\.estimatedProgress, options: [.new]) { [weak self] wv, _ in
                let value = wv.estimatedProgress
                Task { @MainActor in self?.progress = value }
            },
            webView.observe(\.isLoading, options: [.new]) { [weak self] wv, _ in
                let value = wv.isLoading
                Task { @MainActor in self?.isLoading = value }
            }
        ]
    }

    // MARK: - Public actions

    static func isAllowed(_ url: URL?) -> Bool {
        guard let url, url.scheme?.lowercased() == "https",
              let host = url.host?.lowercased() else { return false }
        return allowedHosts.contains { host == $0 || host.hasSuffix("." + $0) }
    }

    func loadHome() { load(Self.homeURL) }

    func load(_ url: URL) {
        showError = false
        webView.load(URLRequest(url: url))
    }

    func retry() {
        showError = false
        if webView.url == nil { loadHome() } else { webView.reload() }
    }

    @objc private func pulledToRefresh() { retry() }

    private func openExternally(_ url: URL) {
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }

    // MARK: - Navigation policy

    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.cancel); return
        }
        let scheme = url.scheme?.lowercased() ?? ""

        if ["about", "blob", "data"].contains(scheme) || Self.isAllowed(url) {
            decisionHandler(.allow); return
        }
        // Embedded frames (payment widgets, captchas) may come from other HTTPS hosts
        if scheme == "https", let frame = navigationAction.targetFrame, !frame.isMainFrame {
            decisionHandler(.allow); return
        }
        // Other websites, plain http, mailto:, tel:, UPI apps, etc.
        openExternally(url)
        decisionHandler(.cancel)
    }

    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationResponse: WKNavigationResponse,
                 decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        // Files the web view can't display (downloads) are handed to Safari
        if !navigationResponse.canShowMIMEType, let url = navigationResponse.response.url {
            openExternally(url)
            decisionHandler(.cancel); return
        }
        decisionHandler(.allow)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        hasLoadedOnce = true
        showError = false
        refreshControl.endRefreshing()
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        handle(error)
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        handle(error)
    }

    private func handle(_ error: Error) {
        refreshControl.endRefreshing()
        let ns = error as NSError
        if ns.domain == NSURLErrorDomain && ns.code == NSURLErrorCancelled { return }
        if ns.domain == "WebKitErrorDomain" && ns.code == 102 { return } // we cancelled it ourselves
        showError = true
    }

    // MARK: - Pop-ups and JS dialogs

    /// Links with target="_blank" / window.open
    func webView(_ webView: WKWebView,
                 createWebViewWith configuration: WKWebViewConfiguration,
                 for navigationAction: WKNavigationAction,
                 windowFeatures: WKWindowFeatures) -> WKWebView? {
        if let url = navigationAction.request.url {
            if Self.isAllowed(url) { webView.load(navigationAction.request) } else { openExternally(url) }
        }
        return nil
    }

    func webView(_ webView: WKWebView,
                 runJavaScriptAlertPanelWithMessage message: String,
                 initiatedByFrame frame: WKFrameInfo,
                 completionHandler: @escaping () -> Void) {
        presentAlert(message, cancellable: false) { _ in completionHandler() }
    }

    func webView(_ webView: WKWebView,
                 runJavaScriptConfirmPanelWithMessage message: String,
                 initiatedByFrame frame: WKFrameInfo,
                 completionHandler: @escaping (Bool) -> Void) {
        presentAlert(message, cancellable: true, completion: completionHandler)
    }

    private func presentAlert(_ message: String, cancellable: Bool, completion: @escaping (Bool) -> Void) {
        let root = UIApplication.shared.connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.keyWindow }
            .first?.rootViewController
        guard var top = root else { completion(false); return }
        while let presented = top.presentedViewController { top = presented }

        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        if cancellable {
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in completion(false) })
        }
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in completion(true) })
        top.present(alert, animated: true)
    }
}
