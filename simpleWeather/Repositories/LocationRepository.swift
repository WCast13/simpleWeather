//
//  LocationRepository.swift
//  simpleWeather
//
//  Created by William Castellano on 11/5/25.
//

import Foundation
import SwiftData

/// Repository for managing location persistence and business logic
@MainActor
final class LocationRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext){
        self.modelContext = modelContext
    }

    /// Convenience factory to construct a repository on the main actor
    /// Ensures main-actor-isolated dependencies are created safely.
    @MainActor
    static func make(modelContext: ModelContext) -> LocationRepository {
        LocationRepository(modelContext: modelContext)
    }

    // MARK: - Fetch Operations

    /// Fetch all locations sorted by display order
    func fetchAllLocations() throws -> [WeatherLocation] {
        let descriptor = FetchDescriptor<WeatherLocation>(
            sortBy: [SortDescriptor(\.displayOrder), SortDescriptor(\.dateAdded)]
        )
        return try modelContext.fetch(descriptor)
    }

    /// Fetch favorite locations only
    func fetchFavoriteLocations() throws -> [WeatherLocation] {
        let descriptor = FetchDescriptor<WeatherLocation>(
            predicate: #Predicate { $0.isFavorite == true },
            sortBy: [SortDescriptor(\.displayOrder)]
        )
        return try modelContext.fetch(descriptor)
    }

    // MARK: - Add Location

    /// Add a new location from a search query
    /// - Parameter query: City name or ZIP code
    /// - Returns: The newly created location
    /// - Throws: LocationError if geocoding or saving fails
    func addLocation(query: String) async throws -> WeatherLocation {
        // 1. Geocode the query
        let result = await GeocodeManager(address: query).forwardGeocode(address: query)
        print(result ?? "No result")
        
        // 3. Determine if input was a ZIP code
        let zipCode = isZipCode(query) ? query : nil

        // 4. Create new location
        let newLocation = WeatherLocation(
            city: result?.addressRepresentations?.cityName,
            state: result?.placemark.administrativeArea,
            zipCode: zipCode,
            latitude: result?.location.coordinate.latitude ?? 0.0,
            longitude: result?.location.coordinate.longitude ?? 0.0,
        )

        // 5. Save to database
        modelContext.insert(newLocation)

        do {
            try modelContext.save()
            return newLocation
        } catch {
            throw LocationError.saveFailed
        }
    }

    // MARK: - Update Operations

    /// Update location metadata (last updated time)
    func updateLastUpdated(_ location: WeatherLocation) throws {
        location.lastUpdated = Date()
        do {
            try modelContext.save()
        } catch {
            throw LocationError.saveFailed
        }
    }

    /// Toggle favorite status
    func toggleFavorite(_ location: WeatherLocation) throws {
        location.isFavorite?.toggle()
        do {
            try modelContext.save()
        } catch {
            throw LocationError.saveFailed
        }
    }

    /// Reorder locations
    func reorder(locations: [WeatherLocation]) throws {
        for (index, location) in locations.enumerated() {
            location.displayOrder = index
        }
        do {
            try modelContext.save()
        } catch {
            throw LocationError.saveFailed
        }
    }

    // MARK: - Delete Operations

    /// Delete a location
    func delete(_ location: WeatherLocation) throws {
        modelContext.delete(location)
        try modelContext.save()
    }

    /// Delete multiple locations
    func delete(at offsets: IndexSet, from locations: [WeatherLocation]) throws {
        for index in offsets {
            modelContext.delete(locations[index])
        }
        try modelContext.save()
    }

    // MARK: - Helper Methods

    /// Determines if the input is a ZIP code
    private func isZipCode(_ input: String) -> Bool {
        // Simple check: 5 digits, optionally followed by dash and 4 more digits
        let zipPattern = "^\\d{5}(-\\d{4})?$"
        return input.range(of: zipPattern, options: .regularExpression) != nil
    }
}

