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
    private let geocodingService: GeocodingServiceProtocol

    init(modelContext: ModelContext,
         geocodingService: GeocodingServiceProtocol = GeocodingService()) {
        self.modelContext = modelContext
        self.geocodingService = geocodingService
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
        let result = try await geocodingService.geocode(query)

        // 2. Check for duplicates (within 1km)
        let existingLocations = try fetchAllLocations()
        for existing in existingLocations {
            let tempLocation = WeatherLocation(
                latitude: result.coordinate.latitude,
                longitude: result.coordinate.longitude
            )
            if tempLocation.isNear(existing, threshold: 1000) {
                throw LocationError.duplicateLocation
            }
        }

        // 3. Determine if input was a ZIP code
        let zipCode = isZipCode(query) ? query : nil

        // 4. Create new location
        let nextOrder = existingLocations.count
        let newLocation = WeatherLocation(
            city: result.city,
            state: result.state,
            zipCode: zipCode,
            latitude: result.coordinate.latitude,
            longitude: result.coordinate.longitude,
            displayOrder: nextOrder
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
    func updateLastUpdated(_ location: WeatherLocation) {
        location.lastUpdated = Date()
        try? modelContext.save()
    }

    /// Toggle favorite status
    func toggleFavorite(_ location: WeatherLocation) {
        location.isFavorite.toggle()
        try? modelContext.save()
    }

    /// Reorder locations
    func reorder(locations: [WeatherLocation]) {
        for (index, location) in locations.enumerated() {
            location.displayOrder = index
        }
        try? modelContext.save()
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
