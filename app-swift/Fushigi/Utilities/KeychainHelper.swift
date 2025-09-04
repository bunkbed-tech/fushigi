//
//  KeychainHelper.swift
//  Fushigi
//
//  Created by Tahoe Schrader on 2025/09/01.
//

import Foundation
import Security

// TODO: Need to understand this file better

/// Simple helper for storing/retrieving strings in Keychain
final class KeychainHelper {
    static let shared = KeychainHelper()
    private init() {}

    /// Save a string to Keychain for a given key
    func save(_ value: String, forKey key: String) {
        guard let data = value.data(using: .utf8) else { return }
        // Delete any existing item
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
        ]
        SecItemDelete(query as CFDictionary)

        // Add new item
        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
        ]
        SecItemAdd(addQuery as CFDictionary, nil)
    }

    /// Load a string from Keychain for a given key
    func load(forKey key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess, let data = item as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    /// Delete a string from Keychain for a given key
    func delete(forKey key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
        ]
        SecItemDelete(query as CFDictionary)
    }
}
