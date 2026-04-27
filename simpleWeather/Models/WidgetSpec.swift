//
//  WidgetSpec.swift  (NEW — SchemaV3)
//  simpleWeather
//
//  A user-placed widget on a location's Detail layout. Owned by
//  WeatherLocation via a cascade-delete relationship; see
//  CLOUDKIT-RULES.md for why every property defaults and why the
//  inverse-side `location` is optional.
//

import Foundation
import SwiftData

@Model
final class WidgetSpec {
    /// Stable identifier across devices.
    var id: UUID = UUID()

    /// Catalog identifier — matches a `WidgetKind.rawValue` from the catalog,
    /// e.g. "headline", "hourly-chart". Stored as String so we can extend the
    /// catalog without forcing a schema migration each time.
    var kindRaw: String = ""

    /// Grid size key like "1x1" / "2x1" / "2x2" / "4x1" / "4x2". Same
    /// rationale: storing as raw String keeps the catalog editable.
    var sizeRaw: String = "1x1"

    /// Position in the location's Detail grid. Sort on read.
    /// CloudKit ordered relationships aren't safe (RULE 04); we own the order.
    var displayOrder: Int = 0

    /// Inverse side of the relationship. Optional per RULE 05 (no required
    /// to-one relationships across the CloudKit boundary).
    var location: WeatherLocation?

    init() {}

    init(kind: WidgetKind, size: WidgetSize, displayOrder: Int = 0) {
        self.id = UUID()
        self.kindRaw = kind.rawValue
        self.sizeRaw = size.rawValue
        self.displayOrder = displayOrder
    }

    // MARK: Computed accessors

    var kind: WidgetKind {
        get { WidgetKind(rawValue: kindRaw) ?? .headline }
        set { kindRaw = newValue.rawValue }
    }

    var size: WidgetSize {
        get { WidgetSize(rawValue: sizeRaw) ?? .oneByOne }
        set { sizeRaw = newValue.rawValue }
    }

    /// Catalog metadata for this widget — name, group, allowed sizes, etc.
    /// Falls back to `nil` only if `kindRaw` is something not in the catalog,
    /// which shouldn't happen in normal flow.
    var catalogEntry: WidgetCatalogEntry? {
        WidgetCatalog.entry(for: kind)
    }
}
