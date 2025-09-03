//
//  APIConfig.swift
//  Fushigi
//
//  Created by Tahoe Schrader on 2025/09/03.
//

enum APIConfig {
    static var baseURL: String {
        switch AppEnvironment.current {
        case .demo:
            "https://demo.fushigi.bunkbed.tech"
        case .prod:
            "https://fushigi.bunkbed.tech"
        }
    }
}
