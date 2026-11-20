import SwiftUI
import WebKit

private let brand = Color("BrandColor")

struct ContentView: View {
    @StateObject private var model = WebViewModel()
    @State private var splashTimedOut = false

    var body: some View {
        ZStack(alignment: .top) {
            WebViewContainer(webView: model.webView)
                .ignoresSafeArea(.container, edges: .bottom)

            if model.isLoading && model.progress < 1 {
                ProgressView(value: model.progress)
                    .progressViewStyle(.linear)
                    .tint(brand)
            }

            if model.showError {
                OfflineView(retry: model.retry)
            }

            if !model.hasLoadedOnce && !model.showError && !splashTimedOut {
                SplashView()
                    .transition(.opacity)
            }
        }
        .animation(.easeOut(duration: 0.25), value: model.hasLoadedOnce)
        .onAppear {
            if model.webView.url == nil { model.loadHome() }
        }
        .task {
            // Never keep the splash longer than 3 seconds on slow networks
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            splashTimedOut = true
        }
    }
}

struct WebViewContainer: UIViewRepresentable {
    let webView: WKWebView
    func makeUIView(context: Context) -> WKWebView { webView }
    func updateUIView(_ uiView: WKWebView, context: Context) {}
}

struct SplashView: View {
    var body: some View {
        ZStack {
            brand.ignoresSafeArea()
            Text("Pay101")
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }
    }
}

struct OfflineView: View {
    let retry: () -> Void
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 56))
                .foregroundColor(.secondary)
            Text("You're offline")
                .font(.title2.bold())
            Text("Check your internet connection and try again.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Button("Retry", action: retry)
                .buttonStyle(.borderedProminent)
                .tint(brand)
                .padding(.top, 12)
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground).ignoresSafeArea())
    }
}
