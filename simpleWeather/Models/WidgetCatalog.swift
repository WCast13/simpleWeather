//
//  WidgetCatalog.swift  (NEW — Phase 4b)
//  simpleWeather
//
//  Source of truth for the Detail-view widget library:
//   - WidgetKind        — typed identifier; matches WidgetSpec.kindRaw
//   - WidgetSize        — typed grid size; matches WidgetSpec.sizeRaw
//   - WidgetCatalogEntry — display metadata (name, group, allowed sizes)
//   - WidgetCatalog.all  — the 17-entry catalog ported from
//                          design_handoff_simpleweather_v2/design-references/proto-data.jsx
//

import Foundation

// MARK: - WidgetKind ---------------------------------------------------------

/// A widget kind. Raw values match the catalog ids used in the design refs
/// and stored in `WidgetSpec.kindRaw`. Unknown kinds (from a future build
/// downgraded to an older one) fall back to `.headline` in the accessor.
enum WidgetKind: String, CaseIterable, Codable, Sendable, Hashable {
    case headline       = "headline"
    case hourlyStrip    = "hourly-strip"
    case daily10        = "daily-10"
    case feelsLike      = "feels-like"
    case humidity       = "humidity"
    case dewPoint       = "dew-point"
    case pressure       = "pressure"
    case visibility     = "visibility"
    case cloudCover     = "cloud-cover"
    case uvIndex        = "uv-index"
    case sunTimes       = "sun-times"
    case moonPhase      = "moon-phase"
    case airQuality     = "air-quality"
    case wind           = "wind"
    case hourlyChart    = "hourly-chart"
    case precipChance   = "precip-chance"
    case tide           = "tide"
}

// MARK: - WidgetSize ---------------------------------------------------------

/// A widget's footprint in the Detail grid, in (column × row) units.
/// Raw values match `WidgetSpec.sizeRaw`.
enum WidgetSize: String, CaseIterable, Codable, Sendable, Hashable {
    case oneByOne   = "1x1"
    case twoByOne   = "2x1"
    case twoByTwo   = "2x2"
    case fourByOne  = "4x1"
    case fourByTwo  = "4x2"

    var width: Int {
        switch self {
        case .oneByOne:                       return 1
        case .twoByOne, .twoByTwo:            return 2
        case .fourByOne, .fourByTwo:          return 4
        }
    }

    var height: Int {
        switch self {
        case .oneByOne, .twoByOne, .fourByOne: return 1
        case .twoByTwo, .fourByTwo:            return 2
        }
    }

    var area: Int { width * height }
}

// MARK: - WidgetCatalogEntry -------------------------------------------------

/// Display metadata for a widget kind — what shows in the library sheet,
/// which sizes the user can pick, and the default size on add.
struct WidgetCatalogEntry: Identifiable, Sendable, Hashable {
    let kind: WidgetKind
    let displayName: String
    let group: String
    /// SF Symbol name for the library row. Per-widget actual rendering
    /// (Phase 4d) can use different symbols depending on data (e.g. moon
    /// phase varies with date).
    let symbolName: String
    let allowedSizes: [WidgetSize]
    let defaultSize: WidgetSize
    let summary: String
    /// `true` when the widget needs data we don't have in WeatherKit
    /// (currently only `tide` — needs NOAA CO-OPS). The catalog still lists
    /// it so presets can include it; the renderer (Phase 4d) shows a
    /// "Coming soon" placeholder until the data source lands.
    let isDeferred: Bool

    var id: WidgetKind { kind }
}

// MARK: - WidgetCatalog ------------------------------------------------------

enum WidgetCatalog {
    /// All known widgets, in library-display order. Groups appear in the order
    /// of their first entry below. Don't reorder casually — the library sheet
    /// renders sections in this same order.
    static let all: [WidgetCatalogEntry] = [
        // Headline
        .init(kind: .headline, displayName: "Now", group: "Headline",
              symbolName: "sun.max.fill",
              allowedSizes: [.fourByTwo], defaultSize: .fourByTwo,
              summary: "Big temp + condition + hi/lo",
              isDeferred: false),
        .init(kind: .hourlyStrip, displayName: "Hourly strip", group: "Headline",
              symbolName: "clock",
              allowedSizes: [.fourByOne], defaultSize: .fourByOne,
              summary: "Next 12 hours, scrollable",
              isDeferred: false),
        .init(kind: .daily10, displayName: "10-day forecast", group: "Headline",
              symbolName: "calendar",
              allowedSizes: [.fourByOne, .fourByTwo], defaultSize: .fourByTwo,
              summary: "Day · symbol · low/high",
              isDeferred: false),

        // Conditions
        .init(kind: .feelsLike, displayName: "Feels like", group: "Conditions",
              symbolName: "thermometer.medium",
              allowedSizes: [.oneByOne], defaultSize: .oneByOne,
              summary: "Apparent temperature",
              isDeferred: false),
        .init(kind: .humidity, displayName: "Humidity", group: "Conditions",
              symbolName: "humidity.fill",
              allowedSizes: [.oneByOne], defaultSize: .oneByOne,
              summary: "",
              isDeferred: false),
        .init(kind: .dewPoint, displayName: "Dew point", group: "Conditions",
              symbolName: "drop.fill",
              allowedSizes: [.oneByOne], defaultSize: .oneByOne,
              summary: "",
              isDeferred: false),
        .init(kind: .pressure, displayName: "Pressure", group: "Conditions",
              symbolName: "gauge.with.dots.needle.bottom.50percent",
              allowedSizes: [.oneByOne], defaultSize: .oneByOne,
              summary: "",
              isDeferred: false),
        .init(kind: .visibility, displayName: "Visibility", group: "Conditions",
              symbolName: "eye.fill",
              allowedSizes: [.oneByOne], defaultSize: .oneByOne,
              summary: "",
              isDeferred: false),
        .init(kind: .cloudCover, displayName: "Cloud cover", group: "Conditions",
              symbolName: "cloud.fill",
              allowedSizes: [.oneByOne], defaultSize: .oneByOne,
              summary: "",
              isDeferred: false),

        // Sky
        .init(kind: .uvIndex, displayName: "UV index", group: "Sky",
              symbolName: "sun.max.fill",
              allowedSizes: [.oneByOne, .twoByOne], defaultSize: .oneByOne,
              summary: "",
              isDeferred: false),
        .init(kind: .sunTimes, displayName: "Sunrise & sunset", group: "Sky",
              symbolName: "sunrise.fill",
              allowedSizes: [.twoByOne, .twoByTwo], defaultSize: .twoByOne,
              summary: "",
              isDeferred: false),
        .init(kind: .moonPhase, displayName: "Moon phase", group: "Sky",
              symbolName: "moon.fill",
              allowedSizes: [.oneByOne, .twoByOne], defaultSize: .oneByOne,
              summary: "",
              isDeferred: false),
        .init(kind: .airQuality, displayName: "Air quality", group: "Sky",
              symbolName: "leaf.fill",
              allowedSizes: [.oneByOne, .twoByOne], defaultSize: .oneByOne,
              summary: "",
              isDeferred: false),

        // Wind
        .init(kind: .wind, displayName: "Wind", group: "Wind",
              symbolName: "wind",
              allowedSizes: [.oneByOne, .twoByOne, .twoByTwo], defaultSize: .twoByOne,
              summary: "Speed · direction · gusts",
              isDeferred: false),

        // Charts
        .init(kind: .hourlyChart, displayName: "Hourly chart", group: "Charts",
              symbolName: "chart.line.uptrend.xyaxis",
              allowedSizes: [.twoByTwo, .fourByTwo], defaultSize: .fourByTwo,
              summary: "Temperature curve · 24h",
              isDeferred: false),
        .init(kind: .precipChance, displayName: "Precip chance", group: "Charts",
              symbolName: "cloud.rain.fill",
              allowedSizes: [.twoByOne, .twoByTwo], defaultSize: .twoByTwo,
              summary: "Hourly probability of precip",
              isDeferred: false),

        // Deferred to v3
        .init(kind: .tide, displayName: "Tide chart", group: "Deferred",
              symbolName: "water.waves",
              allowedSizes: [.twoByTwo, .fourByTwo], defaultSize: .twoByTwo,
              summary: "NOAA CO-OPS · coming in v3",
              isDeferred: true),
    ]

    /// Look up an entry by kind. Returns nil only for kinds not in the catalog
    /// (i.e. WidgetSpec rows written by a future build that knows kinds we don't).
    static func entry(for kind: WidgetKind) -> WidgetCatalogEntry? {
        all.first { $0.kind == kind }
    }

    /// Catalog grouped by group, preserving the order of first appearance in `.all`.
    /// Used by the library sheet (Phase 4f) to render section headers.
    static var byGroup: [(group: String, entries: [WidgetCatalogEntry])] {
        var result: [(group: String, entries: [WidgetCatalogEntry])] = []
        for entry in all {
            if let idx = result.firstIndex(where: { $0.group == entry.group }) {
                result[idx].entries.append(entry)
            } else {
                result.append((group: entry.group, entries: [entry]))
            }
        }
        return result
    }
}
