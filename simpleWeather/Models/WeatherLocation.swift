//
//  WeatherLocation.swift  (SchemaV3 — active)
//  simpleWeather
//
//  Schema versioning evolution:
//   v1 — original optional bag (frozen as SchemaV1.WeatherLocationV1)
//   v2 — collapsed optionals + cardSize / locationType / removeAt + CloudKit
//        (frozen as SchemaV2.WeatherLocationV2)
//   v3 — adds the `widgets` relationship for per-location Detail layouts
//        (active, this file's `WeatherLocation`)
//
//  Read CLOUDKIT-RULES.md before changing this file.
//

import Foundation
import SwiftData
import CoreLocation

// MARK: - Schema versioning -----------------------------------------------------

/// Frozen v1 schema. Kept around so SwiftData can read existing on-device v1
/// stores during the migration. DO NOT edit — must match what shipped.
enum SchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)
    static var models: [any PersistentModel.Type] {
        [WeatherLocationV1.self]
    }

    /// The original v1 model. All-optional bag — that's what's on disk for
    /// any user who shipped before the v2 migration ran.
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

/// Frozen v2 schema. Kept around so SwiftData can read v2 stores during the
/// v2 → v3 migration. DO NOT edit — must match what shipped in Phase 1.
enum SchemaV2: VersionedSchema {
    static var versionIdentifier = Schema.Version(2, 0, 0)
    static var models: [any PersistentModel.Type] {
        [WeatherLocationV2.self]
    }

    /// The v2 model exactly as it shipped. No `widgets` relationship — that's
    /// what v3 adds. Stored properties only; computed accessors are not needed
    /// for migration purposes.
    @Model
    final class WeatherLocationV2 {
        var id: UUID = UUID()
        var city: String = ""
        var state: String = ""
        var zipCode: String = ""
        var latitude: Double = 0
        var longitude: Double = 0
        var dateAdded: Date = Date()
        var lastUpdated: Date?
        var displayOrder: Int = 0
        var isFavorite: Bool = false
        var cardSizeRaw: Int = 0
        var locationTypeRaw: Int = 0
        var removeAt: Date?

        @Attribute(.externalStorage)
        var displayPreferencesData: Data?

        init() {}
    }
}

/// Active v3 schema. Adds `widgets` relationship to WeatherLocation; introduces
/// the WidgetSpec model. The v2 → v3 migration is lightweight (a relationship-add
/// with a default-empty array on the parent side, no row-level work).
enum SchemaV3: VersionedSchema {
    static var versionIdentifier = Schema.Version(3, 0, 0)
    static var models: [any PersistentModel.Type] {
        [WeatherLocation.self, WidgetSpec.self]
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

// MARK: - The active model (v3) -------------------------------------------------

/// A saved place the user wants weather for.
///
/// CloudKit constraints encoded here (do not break these):
/// 1. Every stored property has a default value. CloudKit can't represent
///    "required, no default" — first sync will fail without one.
/// 2. No `@Attribute(.unique)`. CloudKit doesn't enforce uniqueness; SwiftData
///    refuses to add the constraint when the container is CloudKit-backed.
/// 3. Relationships have an explicit inverse (see `widgets` below).
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

    // MARK: Home view behavior (v2)
    /// Stored as Int for CloudKit-friendliness. Use the computed `cardSize`
    /// accessor below instead of touching this directly.
    /// Literal default (must match `CardSize.compact.rawValue`); SwiftData's
    /// `@Model` macro can't resolve enum `.rawValue` at expansion time.
    var cardSizeRaw: Int = 0

    // MARK: Lifecycle classification (v2)
    /// Literal default (must match `LocationType.permanent.rawValue`).
    var locationTypeRaw: Int = 0
    /// Auto-purge target for temporary locations. Sweep on launch.
    /// `nil` for permanent locations.
    var removeAt: Date?

    // MARK: Per-location display preferences (carried over from v1, commit 5c4064d)
    /// Encoded `WeatherDisplayPreferences`. Optional, so Rule 1 satisfied.
    @Attribute(.externalStorage)
    var displayPreferencesData: Data?

    // MARK: Detail-view layout (v3, NEW)
    /// Per-location ordered list of widgets shown on the Detail screen.
    /// Cascade-delete: removing a location removes its widgets.
    /// Inverse points back at `WidgetSpec.location` (RULE 03).
    @Relationship(deleteRule: .cascade, inverse: \WidgetSpec.location)
    var widgets: [WidgetSpec] = []

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
        // `widgets` defaults to [] from the property declaration.
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

    /// `widgets` sorted by `displayOrder`. Use this when rendering the Detail grid.
    var widgetsInOrder: [WidgetSpec] {
        widgets.sorted { $0.displayOrder < $1.displayOrder }
    }
}
