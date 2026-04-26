//
//  WeatherLocation.swift  (SchemaV2 — drop-in replacement)
//  simpleWeather
//
//  v1 → v2 migration: collapse optionals, add locationType + removeAt + cardSize,
//  prepare for CloudKit sync. Read CLOUDKIT-RULES.md before changing this file.
//

import Foundation
import SwiftData
import CoreLocation

// MARK: - Schema versioning -----------------------------------------------------

/// Old schema, kept around so SwiftData can read existing on-device stores
/// during the migration. DO NOT edit — it must match what shipped.
enum SchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)
    static var models: [any PersistentModel.Type] {
        [WeatherLocationV1.self]
    }

    /// The original v1 model. Note the all-optional bag — that's what's on disk today.
    @Model
    final class WeatherLocationV1 {
        var id: UUID = UUID()
        var city: String?
        var state: String?
        var zipCode: String?
        var latitude: Double?
        var longitude: Double?
        var dateAdded: Date?
        var lastUpdated: Date?
        var displayOrder: Int?
        var isFavorite: Bool?

        // Added in commit 5c4064d (per-location display customization). Declared
        // here so SwiftData can match the on-disk schema during v1 → v2 migration.
        @Attribute(.externalStorage)
        var displayPreferencesData: Data?

        init() {}
    }
}

/// New schema. This is the one you'll write code against.
enum SchemaV2: VersionedSchema {
    static var versionIdentifier = Schema.Version(2, 0, 0)
    static var models: [any PersistentModel.Type] {
        [WeatherLocation.self]
    }
}

// MARK: - Public types ----------------------------------------------------------

/// How a saved location relates to the user's life.
/// - permanent:     Home, work, favorite city — sticks around forever.
/// - temporary:     Trip / vacation. Auto-removed when removeAt < today.
/// - calendarEvent: v2+. Promoted from a WeatherEvent (Sarah's wedding, etc.).
enum LocationType: Int, Codable, CaseIterable, Sendable {
    case permanent = 0
    case temporary = 1
    case calendarEvent = 2  // reserved — not used in v1

    var displayName: String {
        switch self {
        case .permanent:     return "Permanent"
        case .temporary:     return "Temporary"
        case .calendarEvent: return "Event"
        }
    }
}

/// Per-location card size on the Home view. Independent of which widgets are bound
/// in the Detail canvas — this only controls how much shows on Home.
enum CardSize: Int, Codable, CaseIterable, Sendable {
    case compact  = 0  // single row, temp + condition
    case expanded = 1  // adds the 4-col grid digest

    var displayName: String {
        switch self {
        case .compact:  return "Compact"
        case .expanded: return "Expanded"
        }
    }
}

// MARK: - The model itself ------------------------------------------------------

/// A saved place the user wants weather for.
///
/// CloudKit constraints encoded here (do not break these):
/// 1. Every stored property has a default value. CloudKit can't represent
///    "required, no default" — first sync will fail without one.
/// 2. No `@Attribute(.unique)`. CloudKit doesn't enforce uniqueness; SwiftData
///    refuses to add the constraint when the container is CloudKit-backed.
/// 3. Relationships (none yet, but coming for `widgets`) must have an explicit
///    inverse. Add `@Relationship(deleteRule: .cascade, inverse: \.location)`
///    when you wire WidgetSpec.
@Model
final class WeatherLocation {

    // MARK: Identity
    /// Stable across devices. Set once at insert; never mutated.
    var id: UUID = UUID()

    // MARK: Place
    /// Display name; falls back to coords or zip if missing.
    var city: String = ""
    var state: String = ""
    var zipCode: String = ""
    var latitude: Double = 0
    var longitude: Double = 0

    // MARK: Lifecycle
    /// When the user added this location. Used as a stable secondary sort.
    var dateAdded: Date = Date()
    /// Last successful WeatherKit fetch. `nil` means "never updated".
    /// Optional rather than `.distantPast` because SwiftData's `@Model` macro
    /// doesn't accept static-property-access defaults; the optional satisfies
    /// CloudKit Rule 1 (the optional itself is the default).
    var lastUpdated: Date?
    /// Manual order in the list. CloudKit ordered relationships are a pain;
    /// roll our own with an Int and sort on read.
    var displayOrder: Int = 0
    /// Pinned by user.
    var isFavorite: Bool = false

    // MARK: New in v2 — Home view behavior
    /// Stored as Int for CloudKit-friendliness. Use the computed `cardSize`
    /// accessor below instead of touching this directly.
    /// Literal default (must match `CardSize.compact.rawValue`); SwiftData's
    /// `@Model` macro can't resolve enum `.rawValue` at expansion time.
    var cardSizeRaw: Int = 0

    // MARK: New in v2 — Lifecycle classification
    /// Literal default (must match `LocationType.permanent.rawValue`).
    var locationTypeRaw: Int = 0
    /// Auto-purge target for temporary locations. Sweep on launch.
    /// `nil` for permanent locations.
    var removeAt: Date?

    // MARK: Per-location display preferences (carried over from v1, commit 5c4064d)
    /// Encoded `WeatherDisplayPreferences`. Phase 4 may supersede this with
    /// `WidgetSpec`; until then, keep it working. Optional, so Rule 1 satisfied.
    @Attribute(.externalStorage)
    var displayPreferencesData: Data?

    // MARK: Init

    init(
        city: String = "",
        state: String = "",
        zipCode: String = "",
        latitude: Double = 0,
        longitude: Double = 0,
        displayOrder: Int = 0,
        isFavorite: Bool = false,
        cardSize: CardSize = .compact,
        locationType: LocationType = .permanent,
        removeAt: Date? = nil
    ) {
        self.id = UUID()
        self.city = city
        self.state = state
        self.zipCode = zipCode
        self.latitude = latitude
        self.longitude = longitude
        self.dateAdded = Date()
        self.lastUpdated = nil
        self.displayOrder = displayOrder
        self.isFavorite = isFavorite
        self.cardSizeRaw = cardSize.rawValue
        self.locationTypeRaw = locationType.rawValue
        self.removeAt = removeAt
        self.displayPreferencesData = nil
    }

    // MARK: Computed accessors

    var cardSize: CardSize {
        get { CardSize(rawValue: cardSizeRaw) ?? .compact }
        set { cardSizeRaw = newValue.rawValue }
    }

    var locationType: LocationType {
        get { LocationType(rawValue: locationTypeRaw) ?? .permanent }
        set { locationTypeRaw = newValue.rawValue }
    }

    var displayName: String {
        if !city.isEmpty && !state.isEmpty { return "\(city), \(state)" }
        if !city.isEmpty                   { return city }
        if !zipCode.isEmpty                { return zipCode }
        return "Unknown Location"
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    /// True when this location should be auto-purged on next launch.
    var isExpired: Bool {
        guard let removeAt else { return false }
        return removeAt < Date()
    }

    /// Per-location display preferences (encoded as JSON in `displayPreferencesData`).
    /// Defaults to `.default` when nothing has been persisted yet.
    var displayPreferences: WeatherDisplayPreferences {
        get {
            guard let data = displayPreferencesData else { return .default }
            return (try? JSONDecoder().decode(WeatherDisplayPreferences.self, from: data)) ?? .default
        }
        set {
            displayPreferencesData = try? JSONEncoder().encode(newValue)
        }
    }
}
