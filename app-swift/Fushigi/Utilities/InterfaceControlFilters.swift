//
//  InterfaceControlFilters.swift
//  fushigi
//
//  Created by Tahoe Schrader on 2025/08/09.
//

// MARK: - Grammar Usage Context

/// Usage context filter options
enum Context: String, CaseIterable, Identifiable {
    case all = "All Contexts"
    case spoken = "Spoken"
    case written = "Written"
    case business = "Business"

    var id: String { rawValue }

    /// User-friendly display name for the usage context
    var displayName: String {
        switch self {
        case .all: "All Contexts"
        case .written: "Written"
        case .spoken: "Spoken"
        case .business: "Business"
        }
    }
}

// MARK: - Japanese Politeness Level

/// Politeness level filter options
enum Level: String, CaseIterable, Identifiable {
    case all = "All Levels"
    case casual = "Casual"
    case polite = "Polite"
    case keigo = "Keigo"
    case sonkeigo = "Sonkeigo"
    case kenjougo = "Kenjougo"

    var id: String { rawValue }

    /// User-friendly display name for the politeness level
    var displayName: String {
        switch self {
        case .all: "All Levels"
        case .casual: "Casual"
        case .polite: "Polite"
        case .keigo: "Keigo"
        case .sonkeigo: "Sonkeigo"
        case .kenjougo: "Kenjougo"
        }
    }
}

// MARK: - Japanese Language Variants

/// Language variant filter options
enum LanguageVariants: String, CaseIterable, Identifiable {
    case none = "No Extras"
    case slang = "Slang"
    case kansai = "Kansai"

    var id: String { rawValue }

    /// User-friendly display name for the language variant
    var displayName: String {
        switch self {
        case .none: "Standard Japanese"
        case .slang: "Slang & Colloquial"
        case .kansai: "Kansai Dialect"
        }
    }
}

// MARK: - Study Mode

/// Grammar sourcing algorithm options
enum SourceMode: String, CaseIterable, Identifiable {
    case random = "Random"
    case srs = "SRS"

    var id: String { rawValue }

    /// User-friendly display name for the source mode
    var displayName: String {
        switch self {
        case .random: "Random"
        case .srs: "SRS"
        }
    }

    /// Icon representing the source mode concept
    var icon: String {
        switch self {
        case .random: "shuffle"
        case .srs: "brain.head.profile"
        }
    }
}

// MARK: - Grammar Source

/// User filter control for currently displayed grammar source
enum GrammarQuickFilter: String, CaseIterable {
    /// Show all grammar items
    case all = "All"

    /// Show grammar items provided by me for "Free"
    case defaults = "Default"

    /// Show user generated grammar items
    case custom = "Custom"

    /// Show grammar items that have an SRS record attached
    case inSRS = "SRS"

    /// Show grammar items that do not have an SRS record attached yet (or previously deleted)
    case available = "Available"

    /// Whether this filter requires SRS data
    var requiresSRSData: Bool {
        switch self {
        case .inSRS, .available:
            true
        case .all, .defaults, .custom:
            false
        }
    }
}

// MARK: - Journal Sort

/// Filter control for sort order of journal entries
enum JournalSort: String, CaseIterable {
    case newest = "Newest First"
    case oldest = "Oldest First"
    case title = "By Title"
}

// MARK: - Journal Privacy

/// Display control for journal entry privacy
enum JournalQuickFilter: String, CaseIterable {
    case all = "All Entries"
    case isPrivate = "Private Only"
    case isPublic = "Public Only"
}
