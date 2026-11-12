import UIKit
import React
import React_RCTAppDelegate
import ReactAppDependencyProvider

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
  var window: UIWindow?

  var reactNativeDelegate: ReactNativeDelegate?
  var reactNativeFactory: RCTReactNativeFactory?

  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
  ) -> Bool {
    let delegate = ReactNativeDelegate()
    let factory = RCTReactNativeFactory(delegate: delegate)
    delegate.dependencyProvider = RCTAppDependencyProvider()

    reactNativeDelegate = delegate
    reactNativeFactory = factory

    window = UIWindow(frame: UIScreen.main.bounds)

    factory.startReactNative(
      withModuleName: "MyCoins",
      in: window,
      launchOptions: launchOptions
    )

    excludeDocumentsFromBackup()
    observePrivacyCover()
    return true
  }

  /// The keystore lives in Documents. Android ships with allowBackup="false";
  /// this is the same promise here: encrypted keys do not travel to iCloud or
  /// to a computer backup. Marking the directory covers everything inside it.
  private func excludeDocumentsFromBackup() {
    guard var documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
      return
    }
    var values = URLResourceValues()
    values.isExcludedFromBackup = true
    try? documents.setResourceValues(values)
  }

  // MARK: - Privacy cover

  /// Android blocks screenshots with FLAG_SECURE. iOS has no such switch, but
  /// it photographs the app for the app switcher when it leaves the
  /// foreground; a cover over the window keeps balances and keys out of that
  /// picture.
  private var privacyCover: UIView?

  private func observePrivacyCover() {
    let center = NotificationCenter.default
    center.addObserver(
      self, selector: #selector(showPrivacyCover),
      name: UIApplication.willResignActiveNotification, object: nil)
    center.addObserver(
      self, selector: #selector(hidePrivacyCover),
      name: UIApplication.didBecomeActiveNotification, object: nil)
  }

  @objc private func showPrivacyCover() {
    guard privacyCover == nil, let window else { return }
    let cover = UIView(frame: window.bounds)
    cover.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    cover.backgroundColor = UIColor(red: 0x1E / 255.0, green: 0x1B / 255.0, blue: 0x5E / 255.0, alpha: 1)
    let title = UILabel()
    title.text = "MyCoins"
    title.textColor = .white
    title.font = .systemFont(ofSize: 34, weight: .bold)
    title.sizeToFit()
    title.center = CGPoint(x: cover.bounds.midX, y: cover.bounds.midY)
    title.autoresizingMask = [.flexibleLeftMargin, .flexibleRightMargin, .flexibleTopMargin, .flexibleBottomMargin]
    cover.addSubview(title)
    window.addSubview(cover)
    privacyCover = cover
  }

  @objc private func hidePrivacyCover() {
    privacyCover?.removeFromSuperview()
    privacyCover = nil
  }
}

class ReactNativeDelegate: RCTDefaultReactNativeFactoryDelegate {
  override func sourceURL(for bridge: RCTBridge) -> URL? {
    self.bundleURL()
  }

  override func bundleURL() -> URL? {
#if DEBUG
    RCTBundleURLProvider.sharedSettings().jsBundleURL(forBundleRoot: "index")
#else
    Bundle.main.url(forResource: "main", withExtension: "jsbundle")
#endif
  }
}
