//
//  MockedData.swift
//  Fushigi
//
//  Created by Tahoe Schrader on 2025/08/27.
//

import Foundation
@testable import Fushigi

@MainActor
struct MockedData {
    static func createMockGrammarPoints() -> [GrammarPointLocal] {
        [
            GrammarPointLocal(id: UUID(), context: "casual", usage: "Hello", meaning: "こんにちは", tags: ["greeting"]),
            GrammarPointLocal(id: UUID(), context: "casual", usage: "Goodbye", meaning: "さようなら", tags: ["farewell"]),
            GrammarPointLocal(id: UUID(), context: "casual", usage: "I", meaning: "私は", tags: ["context"]),
            GrammarPointLocal(id: UUID(), context: "casual", usage: "Cool", meaning: "かっこいい", tags: ["adjective"]),
            GrammarPointLocal(id: UUID(), context: "casual", usage: "Am", meaning: "desu", tags: ["sentence-ender"]),
            GrammarPointLocal(
                id: UUID(),
                context: "formal",
                usage: "Pleased to meet you.",
                meaning: "よろしくお願いします",
                tags: ["greeting"],
            ),
        ]
    }
}
