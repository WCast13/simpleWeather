//
//  WeatherLocation.swift
//  simpleWeather
//
//  Canonical SwiftData migration pattern: every schema version declares a
//  class named `WeatherLocation` (nested in its schema enum via extension).
//  Top-level typealiases at the bottom of the file point at the active
//  schema (currently v3). Renaming the per-version classes
//  (`WeatherLocationV1`/`V2`) is what broke ModelContainer init at runtime —
//  SwiftData uses the simple class name to identify entities, so renaming
//  drops the identity that lets it walk a v2 store forward into v3.
//
//  Read CLOUDKIT-RULES.md before changing this file.
//

import Foundation
import SwiftData
import CoreLocation

// MARK: - Public types (version-independent) -----------------------------------

/// How a saved location relates to the user's life.
enum LocationType: Int, Codable, CaseIterable, Sendable {
    case permanent     = 0
    case temporary     = 1
    case calendarEvent = 2  // reserved — not used in v1

    var displayName: String {
        switch self {
        case .permanent:     return "Permanent"
        case .temporary:     return "Temporary"
        case .calendarEvent: return "Event"
        }
    }
}

/// Per-location card size on the Home view.
enum CardSize: Int, Codable, CaseIterable, Sendable {
    case compact  = 0
    case expanded = 1

    var displayName: String {
        switch self {
        case .compact:  return "Compact"
        case .expanded: return "Expanded"
        }
    }
}

// MARK: - SchemaV1 (frozen) ----------------------------------------------------

enum SchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)
    static var models: [any PersistentModel.Type] {
        [WeatherLocation.self]
    }
}

extension SchemaV1 {
    /// The original v1 model. All-optional bag — that's what's on disk for
    /// any user who shipped before the v2 migration ran.
    @Model
    final class WeatherLocation {
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

        // Added in commit 5c4064d (per-location display customization).
        @Attribute(.externalStorage)
        var displayPreferencesData: Data?

        init() {}
    }
}

// MARK: - SchemaV2 (frozen) ----------------------------------------------------

enum SchemaV2: VersionedSchema {
    static var versionIdentifier = Schema.Version(2, 0, 0)
    static var models: [any PersistentModel.Type] {
        [WeatherLocation.self]
    }
}

extension SchemaV2 {
    /// v2 model exactly as it shipped in Phase 1 (commit a803cc6). Stored
    /// properties only — computed accessors aren't needed for migration.
    @Model
    final class WeatherLocation {
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

// MARK: - SchemaV3 (active) ----------------------------------------------------

enum SchemaV3: VersionedSchema {
    static var versionIdentifier = Schema.Version(3, 0, 0)
    static var models: [any PersistentModel.Type] {
        [WeatherLocation.self, WidgetSpec.self]
    }
}

extension SchemaV3 {

    /// v3 active model. Adds a cascade-delete `widgets` relationship.
    @Model
    final class WeatherLocation {

        // MARK: Identity
        var id: UUID = UUID()

        // MARK: Place
        var city: String = ""
        var state: String = ""
        var zipCode: String = ""
        var latitude: Double = 0
        var longitude: Double = 0

        // MARK: Lifecycle
        var dateAdded: Date = Date()
        /// `nil` means "never updated".
        var lastUpdated: Date?
        var displayOrder: Int = 0
        var isFavorite: Bool = false

        // MARK: Home view behavior (v2)
        /// Literal default (must match `CardSize.compact.rawValue`); the
        /// `@Model` macro can't resolve enum `.rawValue` at expansion time.
        var cardSizeRaw: Int = 0

        // MARK: Lifecycle classification (v2)
        /// Literal default (must match `LocationType.permanent.rawValue`).
        var locationTypeRaw: Int = 0
        var removeAt: Date?

        // MARK: Per-location display preferences (v1, commit 5c4064d)
        @Attribute(.externalStorage)
        var displayPreferencesData: Data?

        // MARK: Detail-view layout (v3)
        /// Cascade-delete: removing the location removes its widgets.
        /// Inverse declared on `WidgetSpec.location` (CloudKit RULE 03).
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

        /// Per-location display preferences (encoded as JSON in
        /// `displayPreferencesData`). Defaults to `.default` when nothing
        /// has been persisted yet.
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

    /// v3 active widget. Owned by WeatherLocation via the inverse relationship
    /// declared above. Every property has a default + the inverse to-one is
    /// optional, satisfying CloudKit Rules 1, 3, and 5.
    @Model
    final class WidgetSpec {
        var id: UUID = UUID()
        var kindRaw: String = ""
        var sizeRaw: String = "1x1"
        var displayOrder: Int = 0
        var location: WeatherLocation?

        init() {}

        init(kind: WidgetKind, size: WidgetSize, displayOrder: Int = 0) {
            self.id = UUID()
            self.kindRaw = kind.rawValue
            self.sizeRaw = size.rawValue
            self.displayOrder = displayOrder
        }
    }
}

// MARK: - Active typealiases ---------------------------------------------------

/// Call sites use these unqualified names; they resolve to the active v3
/// classes nested inside `SchemaV3`. When v4 lands, redefine these to point
/// at `SchemaV4` and freeze v3 with the same nested-extension pattern.
typealias WeatherLocation = SchemaV3.WeatherLocation
typealias WidgetSpec      = SchemaV3.WidgetSpec
