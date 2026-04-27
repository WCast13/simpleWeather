//
//  LocationRepository.swift  (drop-in replacement — v2)
//  simpleWeather
//
//  Diffs vs current:
//  - Returns concrete WeatherLocation everywhere (no optionals on stored fields).
//  - Adds purgeExpired() for the auto-remove sweep on launch.
//  - addLocation now takes locationType + optional removeAt.
//  - reorder is unchanged but documented: this is what makes drag-to-reorder
//    sync deterministically across devices (CloudKit ordered relationships
//    are not safe; we use an Int.).
//

import Foundation
import SwiftData

@MainActor
final class LocationRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    /// Convenience factory to construct a repository on the main actor.
    /// Ensures main-actor-isolated dependencies are created safely.
    @MainActor
    static func make(modelContext: ModelContext) -> LocationRepository {
        LocationRepository(modelContext: modelContext)
    }

    // MARK: - Fetch

    func fetchAllLocations() throws -> [WeatherLocation] {
        let descriptor = FetchDescriptor<WeatherLocation>(
            sortBy: [
                SortDescriptor(\.displayOrder),
                SortDescriptor(\.dateAdded),
            ]
        )
        return try modelContext.fetch(descriptor)
    }

    func fetchFavoriteLocations() throws -> [WeatherLocation] {
        let descriptor = FetchDescriptor<WeatherLocation>(
            predicate: #Predicate { $0.isFavorite == true },
            sortBy: [SortDescriptor(\.displayOrder)]
        )
        return try modelContext.fetch(descriptor)
    }

    // MARK: - Add

    func addLocation(
        query: String,
        locationType: LocationType = .permanent,
        removeAt: Date? = nil
    ) async throws -> WeatherLocation {
        let result = await GeocodeManager(address: query).forwardGeocode(address: query)

        let zipCode = isZipCode(query) ? query : ""
        let city    = result?.addressRepresentations?.cityName ?? ""
        let lat     = result?.location.coordinate.latitude  ?? 0
        let lon     = result?.location.coordinate.longitude ?? 0

        // Place at end of list — caller can reorder after.
        let nextOrder = (try? fetchAllLocations().last?.displayOrder ?? -1) ?? -1

        let new = WeatherLocation(
            city: city,
            state: "",          // TODO: pull from result.region once region API is sorted
            zipCode: zipCode,
            latitude: lat,
            longitude: lon,
            displayOrder: nextOrder + 1,
            isFavorite: false,
            cardSize: .compact,
            locationType: locationType,
            removeAt: removeAt
        )

        modelContext.insert(new)
        do {
            try modelContext.save()
            return new
        } catch {
            throw LocationError.saveFailed
        }
    }

    // MARK: - Update

    func updateLastUpdated(_ location: WeatherLocation) {
        location.lastUpdated = Date()
        try? modelContext.save()
    }

    func toggleFavorite(_ location: WeatherLocation) {
        location.isFavorite.toggle()
        try? modelContext.save()
    }

    func setCardSize(_ location: WeatherLocation, _ size: CardSize) {
        location.cardSize = size
        try? modelContext.save()
    }

    func reorder(locations: [WeatherLocation]) {
        for (index, location) in locations.enumerated() {
            location.displayOrder = index
        }
        try? modelContext.save()
    }

    // MARK: - Delete

    func delete(_ location: WeatherLocation) throws {
        modelContext.delete(location)
        try modelContext.save()
    }

    func delete(at offsets: IndexSet, from locations: [WeatherLocation]) throws {
        for index in offsets {
            modelContext.delete(locations[index])
        }
        try modelContext.save()
    }

    // MARK: - Auto-purge (Aspen-style temporary locations)

    /// Call once on app launch. Removes any temporary location whose
    /// `removeAt` is in the past. Returns count removed (for logging / a toast).
    @discardableResult
    func purgeExpired(now: Date = Date()) throws -> Int {
        // SwiftData's `#Predicate` macro doesn't support enum-case `.rawValue`
        // lookups or force-unwrap of optionals, so the predicate filters only
        // on the (literal) raw type and the date check happens in Swift.
        // `1` here MUST stay in sync with `LocationType.temporary.rawValue`.
        let descriptor = FetchDescriptor<WeatherLocation>(
            predicate: #Predicate { loc in
                loc.locationTypeRaw == 1
            }
        )
        let candidates = try modelContext.fetch(descriptor)
        let expired = candidates.filter { loc in
            guard let removeAt = loc.removeAt else { return false }
            return removeAt < now
        }
        for loc in expired { modelContext.delete(loc) }
        if !expired.isEmpty { try modelContext.save() }
        return expired.count
    }

    // MARK: - Helpers

    private func isZipCode(_ input: String) -> Bool {
        input.range(of: #"^\d{5}(-\d{4})?$"#, options: .regularExpression) != nil
    }

    // MARK: - Widgets (Phase 4)

    /// Replace the location's widgets with the contents of a preset.
    /// Existing widgets are deleted (cascade — they're WidgetSpec rows owned
    /// by `location.widgets`).
    func applyPreset(_ preset: LayoutPreset, to location: WeatherLocation) {
        for widget in location.widgets ?? [] {
            modelContext.delete(widget)
        }
        for (index, item) in preset.items.enumerated() {
            let spec = WidgetSpec(kind: item.kind, size: item.size, displayOrder: index)
            spec.location = location
            modelContext.insert(spec)
        }
        try? modelContext.save()
    }

    /// Append a widget at the end of the location's grid using the catalog's
    /// default size for that kind.
    @discardableResult
    func addWidget(_ kind: WidgetKind, to location: WeatherLocation) -> WidgetSpec {
        let defaultSize = WidgetCatalog.entry(for: kind)?.defaultSize ?? .oneByOne
        let nextOrder = ((location.widgets ?? []).map(\.displayOrder).max() ?? -1) + 1
        let spec = WidgetSpec(kind: kind, size: defaultSize, displayOrder: nextOrder)
        spec.location = location
        modelContext.insert(spec)
        try? modelContext.save()
        return spec
    }

    /// Remove a widget. Caller usually animates the row out before invoking.
    func removeWidget(_ widget: WidgetSpec) {
        modelContext.delete(widget)
        try? modelContext.save()
    }

    /// Set the size of a widget. Caller is responsible for ensuring the size
    /// is in the catalog's `allowedSizes` for that kind — repository doesn't
    /// validate (the edit-mode resize gesture in Phase 4e will).
    func setWidgetSize(_ widget: WidgetSpec, _ size: WidgetSize) {
        widget.sizeRaw = size.rawValue
        try? modelContext.save()
    }

    /// Rewrite `displayOrder` on every widget in `widgets` to match its
    /// position in the array. Used by drag-to-reorder once Phase 4e wires it.
    func reorderWidgets(_ widgets: [WidgetSpec]) {
        for (index, widget) in widgets.enumerated() {
            widget.displayOrder = index
        }
        try? modelContext.save()
    }
}
