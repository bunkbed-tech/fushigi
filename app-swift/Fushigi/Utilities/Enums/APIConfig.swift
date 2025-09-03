//
//  APIConfig.swift
//  Fushigi
//
//  Created by Tahoe Schrader on 2025/09/03.
//

import Foundation

enum APIConfig {
    static var baseURL: String {
        // Run
        if let env = ProcessInfo.processInfo.environment["API_BASE_URL"], !env.isEmpty {
            return env
        }

        // Build
        if let plist = Bundle.main.infoDictionary?["API_BASE_URL"] as? String, !plist.isEmpty {
            return plist
        }

        // Fallback to demo to be safe
        return "https://demo.fushigi.bunkbed.tech"
    }

    static var mode: String {
        // Run
        if let env = ProcessInfo.processInfo.environment["APP_ENVIRONMENT"], !env.isEmpty {
            return env
        }

        // Build
        if let plist = Bundle.main.infoDictionary?["APP_ENVIRONMENT"] as? String, !plist.isEmpty {
            return plist
        }

        // Fallback to demo to be safe
        return "DEMO"
    }
}
