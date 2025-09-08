//
//  APIConfig.swift
//  Fushigi
//
//  Created by Tahoe Schrader on 2025/09/03.
//

import Foundation

/// Configuration flags used for turning on/off features depending on the build
enum APIConfig {
    /// Location of database
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

    /// Desired run mode for current build of the app
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
