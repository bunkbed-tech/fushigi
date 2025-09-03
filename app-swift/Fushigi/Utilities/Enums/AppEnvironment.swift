//
//  AppEnvironment.swift
//  Fushigi
//
//  Created by Tahoe Schrader on 2025/09/03.
//

import Foundation

enum AppEnvironment: String {
    case demo
    case prod

    static var current: AppEnvironment {
        guard let value = ProcessInfo.processInfo.environment["APP_ENV"]?.lowercased() else {
            return .demo
        }
        return AppEnvironment(rawValue: value) ?? .demo
    }
}
