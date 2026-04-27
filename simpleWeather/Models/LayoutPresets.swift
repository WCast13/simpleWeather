//
//  LayoutPresets.swift  (NEW — Phase 4b)
//  simpleWeather
//
//  Reapplyable starting layouts for the Detail view, ported from
//  design_handoff_simpleweather_v2/design-references/proto-data.jsx
//
//  Decision (per the handoff): presets are reapplyable templates — the user
//  can re-apply a preset later from Detail edit mode, replacing the current
//  layout. `LocationRepository.applyPreset(_:to:)` does the swap.
//

import Foundation

struct LayoutPreset: Identifiable, Sendable, Hashable {
    /// Stable id used by the "Apply preset…" Detail menu and (eventually) by
    /// `WeatherLocation.lastAppliedPresetId` if we wire that in Phase 4f.
    let id: String
    let displayName: String
    let symbolName: String
    let summary: String
    let items: [Item]

    struct Item: Sendable, Hashable {
        let kind: WidgetKind
        let size: WidgetSize
    }
}

enum LayoutPresets {
    static let justWeather = LayoutPreset(
        id: "just-weather",
        displayName: "Just weather",
        symbolName: "sun.max.fill",
        summary: "A clean default — what most people want.",
        items: [
            .init(kind: .headline,    size: .fourByTwo),
            .init(kind: .hourlyStrip, size: .fourByOne),
            .init(kind: .daily10,     size: .fourByTwo),
            .init(kind: .feelsLike,   size: .oneByOne),
            .init(kind: .humidity,    size: .oneByOne),
            .init(kind: .wind,        size: .twoByOne),
            .init(kind: .uvIndex,     size: .oneByOne),
            .init(kind: .visibility,  size: .oneByOne),
            .init(kind: .sunTimes,    size: .twoByOne),
        ]
    )

    static let boating = LayoutPreset(
        id: "boating",
        displayName: "Boating",
        symbolName: "ferry.fill",
        summary: "Wind, tide, visibility, sun — the things that matter on the water.",
        items: [
            .init(kind: .headline,     size: .fourByTwo),
            .init(kind: .wind,         size: .twoByTwo),
            .init(kind: .visibility,   size: .oneByOne),
            .init(kind: .cloudCover,   size: .oneByOne),
            .init(kind: .tide,         size: .fourByTwo),
            .init(kind: .sunTimes,     size: .twoByTwo),
            .init(kind: .uvIndex,      size: .twoByOne),
            .init(kind: .precipChance, size: .twoByTwo),
            .init(kind: .hourlyStrip,  size: .fourByOne),
        ]
    )

    static let photography = LayoutPreset(
        id: "photography",
        displayName: "Photography",
        symbolName: "camera.fill",
        summary: "Golden hour, cloud cover, moon phase, UV.",
        items: [
            .init(kind: .sunTimes,    size: .twoByTwo),
            .init(kind: .moonPhase,   size: .twoByOne),
            .init(kind: .cloudCover,  size: .oneByOne),
            .init(kind: .uvIndex,     size: .oneByOne),
            .init(kind: .headline,    size: .fourByTwo),
            .init(kind: .hourlyStrip, size: .fourByOne),
            .init(kind: .humidity,    size: .oneByOne),
            .init(kind: .visibility,  size: .oneByOne),
            .init(kind: .wind,        size: .twoByOne),
        ]
    )

    static let all: [LayoutPreset] = [justWeather, boating, photography]

    static func preset(id: String) -> LayoutPreset? {
        all.first { $0.id == id }
    }
}
