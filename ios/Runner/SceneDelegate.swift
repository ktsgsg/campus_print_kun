import Flutter
import UIKit

class SceneDelegate: FlutterSceneDelegate {

    private static let channelName = "com.example.campusPrintKun/sharing"
    private var channel: FlutterMethodChannel?
    private var pendingPdfPath: String?

    override func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        super.scene(scene, willConnectTo: session, options: connectionOptions)
        // エンジン未初期化のため、起動時 URL はバッファしておく
        if let url = connectionOptions.urlContexts.first?.url,
           url.pathExtension.lowercased() == "pdf" {
            pendingPdfPath = url.path
        }
    }

    override func sceneDidBecomeActive(_ scene: UIScene) {
        super.sceneDidBecomeActive(scene)
        setupChannelIfNeeded()
    }

    override func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        super.scene(scene, openURLContexts: URLContexts)
        guard let url = URLContexts.first?.url,
              url.pathExtension.lowercased() == "pdf" else { return }
        if let ch = channel {
            ch.invokeMethod("sharedPdfReceived", arguments: url.path)
        } else {
            pendingPdfPath = url.path
        }
    }

    private func setupChannelIfNeeded() {
        guard channel == nil else { return }
        guard let windowScene = UIApplication.shared.connectedScenes
                .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
              let flutterVC = windowScene.windows.first?.rootViewController as? FlutterViewController else { return }

        let ch = FlutterMethodChannel(name: Self.channelName, binaryMessenger: flutterVC.engine.binaryMessenger)
        ch.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: FlutterResult) in
            if call.method == "getInitialSharedPdf" {
                result(self?.pendingPdfPath)
                self?.pendingPdfPath = nil
            } else {
                result(FlutterMethodNotImplemented)
            }
        }
        channel = ch

        // エンジン初期化前に届いていた URL があれば即座に送信
        if let path = pendingPdfPath {
            pendingPdfPath = nil
            ch.invokeMethod("sharedPdfReceived", arguments: path)
        }
    }
}
