//
//  WidgetSpec.swift
//  simpleWeather
//
//  The `@Model` class declaration moved to WeatherLocation.swift (nested in
//  the SchemaV3 extension, alongside the active `WeatherLocation` model)
//  when the schema was restructured to the canonical SwiftData migration
//  pattern. This file now holds the type-safe accessors that wrap the raw
//  storage strings (`kindRaw`, `sizeRaw`).
//

import Foundation

extension WidgetSpec {

    /// Type-safe widget kind. Falls back to `.headline` if `kindRaw` was
    /// written by a build that knows kinds we don't.
    var kind: WidgetKind {
        get { WidgetKind(rawValue: kindRaw) ?? .headline }
        set { kindRaw = newValue.rawValue }
    }

    /// Type-safe widget size. Falls back to `.oneByOne` for unknown sizes.
    var size: WidgetSize {
        get { WidgetSize(rawValue: sizeRaw) ?? .oneByOne }
        set { sizeRaw = newValue.rawValue }
    }

    /// Catalog metadata for this widget — name, group, allowed sizes, etc.
    /// Returns `nil` only if `kindRaw` is something not in the catalog.
    var catalogEntry: WidgetCatalogEntry? {
        WidgetCatalog.entry(for: kind)
    }
}
