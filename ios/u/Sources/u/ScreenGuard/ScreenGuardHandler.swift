import Flutter
import UIKit

public final class ScreenGuardHandler: NSObject {

    private let channel: FlutterMethodChannel

    private var enabled = false

    private let secureField = UITextField()

    private weak var flutterView: UIView?

    private var recordingCover: UIView?

    public init(messenger: FlutterBinaryMessenger) {
        channel = FlutterMethodChannel(
            name: "u/screen_guard",
            binaryMessenger: messenger
        )

        super.init()

        channel.setMethodCallHandler { [weak self] call, result in
            guard let self else {
                result(nil)
                return
            }

            switch call.method {
            case "enable":
                self.enable()
                result(nil)

            case "disable":
                self.disable()
                result(nil)

            default:
                result(FlutterMethodNotImplemented)
            }
        }

        let center = NotificationCenter.default

        center.addObserver(
            self,
            selector: #selector(screenshotTaken),
            name: UIApplication.userDidTakeScreenshotNotification,
            object: nil
        )

        center.addObserver(
            self,
            selector: #selector(captureStateChanged),
            name: UIScreen.capturedDidChangeNotification,
            object: nil
        )

        center.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Window

    private var keyWindow: UIWindow? {
        if #available(iOS 13.0, *) {
            return UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
                .first(where: { $0.isKeyWindow })
        }

        return UIApplication.shared.windows.first {
            $0.isKeyWindow
        }
    }

    // MARK: - Flutter View

    private func findFlutterView() -> UIView? {
        guard let window = keyWindow else {
            return nil
        }

        return findFlutterView(
            in: window.rootViewController
        )
    }

    private func findFlutterView(
        in viewController: UIViewController?
    ) -> UIView? {

        guard let viewController else {
            return nil
        }

        if viewController is FlutterViewController {
            return viewController.view
        }

        for child in viewController.children {
            if let view = findFlutterView(in: child) {
                return view
            }
        }

        if let presented = viewController.presentedViewController {
            if let view = findFlutterView(in: presented) {
                return view
            }
        }

        return nil
    }

    // MARK: - Enable

    private func enable() {
        DispatchQueue.main.async { [weak self] in
            guard let self else {
                return
            }

            enabled = true

            protectFlutterView()
            captureStateChanged()
        }
    }

    // MARK: - Disable

    private func disable() {
        DispatchQueue.main.async { [weak self] in
            guard let self else {
                return
            }

            enabled = false

            restoreFlutterView()
            removeRecordingCover()
        }
    }

    // MARK: - Secure Flutter View

    private func protectFlutterView() {

        guard let window = keyWindow else {
            return
        }

        guard let flutterView = findFlutterView() else {
            return
        }

        self.flutterView = flutterView

        secureField.isSecureTextEntry = true
        secureField.isUserInteractionEnabled = false
        secureField.backgroundColor = .clear
        secureField.textColor = .clear

        /*
         The secure UITextField must exist in the normal UIKit hierarchy.
         */

        if secureField.superview == nil {

            secureField.translatesAutoresizingMaskIntoConstraints = false

            window.addSubview(secureField)

            NSLayoutConstraint.activate([
                secureField.leadingAnchor.constraint(
                    equalTo: window.leadingAnchor
                ),
                secureField.trailingAnchor.constraint(
                    equalTo: window.trailingAnchor
                ),
                secureField.topAnchor.constraint(
                    equalTo: window.topAnchor
                ),
                secureField.bottomAnchor.constraint(
                    equalTo: window.bottomAnchor
                )
            ])
        }

        guard let secureLayer = secureContentLayer() else {
            return
        }

        /*
         Already protected.
         */
        if flutterView.layer.superlayer === secureLayer {
            flutterView.layer.frame = secureLayer.bounds
            return
        }

        /*
         IMPORTANT:

         Move ONLY Flutter's layer.

         Never move UIWindow.layer.
         */

        flutterView.layer.removeFromSuperlayer()

        secureLayer.addSublayer(flutterView.layer)

        flutterView.layer.frame = secureLayer.bounds
    }

    private func secureContentLayer() -> CALayer? {

        guard let sublayers = secureField.layer.sublayers,
              !sublayers.isEmpty else {
            return nil
        }

        if #available(iOS 17.0, *) {
            return sublayers.last
        }

        return sublayers.first
    }

    // MARK: - Restore

    private func restoreFlutterView() {

        guard let flutterView else {
            return
        }

        /*
         Remove it from the secure CALayer.
         */

        flutterView.layer.removeFromSuperlayer()

        /*
         Put it back into the Flutter UIView hierarchy.

         Normally the FlutterViewController already owns this view,
         so this should only be needed if its superview was lost.
         */

        if flutterView.superview == nil,
           let viewController = keyWindow?.rootViewController {

            viewController.view.addSubview(flutterView)
        }

        flutterView.translatesAutoresizingMaskIntoConstraints = false

        if let superview = flutterView.superview {

            NSLayoutConstraint.activate([
                flutterView.leadingAnchor.constraint(
                    equalTo: superview.leadingAnchor
                ),
                flutterView.trailingAnchor.constraint(
                    equalTo: superview.trailingAnchor
                ),
                flutterView.topAnchor.constraint(
                    equalTo: superview.topAnchor
                ),
                flutterView.bottomAnchor.constraint(
                    equalTo: superview.bottomAnchor
                )
            ])
        }
    }

    // MARK: - Screenshot

    @objc private func screenshotTaken() {

        guard enabled else {
            return
        }

        channel.invokeMethod(
            "onScreenshot",
            arguments: nil
        )
    }

    // MARK: - Recording

    @objc private func captureStateChanged() {

        DispatchQueue.main.async { [weak self] in
            guard let self else {
                return
            }

            let captured = UIScreen.main.isCaptured

            channel.invokeMethod(
                "onScreenRecording",
                arguments: captured
            )

            guard enabled else {
                removeRecordingCover()
                return
            }

            if captured {
                showRecordingCover()
            } else {
                removeRecordingCover()
            }
        }
    }

    private func showRecordingCover() {

        guard recordingCover == nil,
              let window = keyWindow else {
            return
        }

        let cover = UIView(frame: window.bounds)

        cover.backgroundColor = .black

        cover.autoresizingMask = [
            .flexibleWidth,
            .flexibleHeight
        ]

        window.addSubview(cover)

        recordingCover = cover
    }

    private func removeRecordingCover() {

        recordingCover?.removeFromSuperview()
        recordingCover = nil
    }

    // MARK: - Lifecycle

    @objc private func appDidBecomeActive() {

        guard enabled else {
            return
        }

        DispatchQueue.main.async { [weak self] in
            guard let self else {
                return
            }

            protectFlutterView()
            captureStateChanged()
        }
    }
}