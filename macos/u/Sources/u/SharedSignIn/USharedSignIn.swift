// Shared by ios/ and macos/: keep the two copies identical.
import Foundation
import Security
#if os(iOS)
import Flutter
#else
import FlutterMacOS
#endif

/// Native side of USharedSignIn ("u/shared_sign_in"): one keychain item per app in a keychain access group
/// that every app of the publisher lists in its entitlements, so sibling apps read each other's record.
final class USharedSignInHandler: NSObject {
    private let channel: FlutterMethodChannel
    private let service = "u.sharedsignin"

    init(messenger: FlutterBinaryMessenger) {
        channel = FlutterMethodChannel(name: "u/shared_sign_in", binaryMessenger: messenger)
        super.init()
        channel.setMethodCallHandler { [weak self] call, result in self?.handle(call, result: result) }
    }

    private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments as? [String: Any] ?? [:]
        guard let group = args["accessGroup"] as? String, !group.isEmpty else {
            result(call.method == "read" ? [String]() : false)
            return
        }
        let account = args["appId"] as? String ?? ""
        switch call.method {
        case "write":
            let data = (args["json"] as? String ?? "").data(using: .utf8) ?? Data()
            SecItemDelete(base(group, account) as CFDictionary)
            var item = base(group, account)
            item[kSecValueData as String] = data
            item[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
            result(SecItemAdd(item as CFDictionary, nil) == errSecSuccess)
        case "clear":
            result(SecItemDelete(base(group, account) as CFDictionary) == errSecSuccess)
        case "read":
            var query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrAccessGroup as String: group,
                kSecMatchLimit as String: kSecMatchLimitAll,
                kSecReturnAttributes as String: true,
                kSecReturnData as String: true,
            ]
            #if os(macOS)
            query[kSecUseDataProtectionKeychain as String] = true
            #endif
            var items: CFTypeRef?
            guard SecItemCopyMatching(query as CFDictionary, &items) == errSecSuccess, let list = items as? [[String: Any]] else {
                result([String]())
                return
            }
            let records: [String] = list.compactMap { item -> String? in
                guard (item[kSecAttrAccount as String] as? String) != account, let data = item[kSecValueData as String] as? Data else { return nil }
                return String(data: data, encoding: .utf8)
            }
            result(records)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func base(_ group: String, _ account: String) -> [String: Any] {
        var item: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecAttrAccessGroup as String: group,
        ]
        #if os(macOS)
        item[kSecUseDataProtectionKeychain as String] = true
        #endif
        return item
    }
}
