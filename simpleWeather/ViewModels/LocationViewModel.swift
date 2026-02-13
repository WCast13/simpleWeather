//
//  LocationViewModel.swift
//  simpleWeather
//
//  Created by William Castellano on 11/5/25.
//

import Foundation
import SwiftData

/// ViewModel for managing location operations
@MainActor
@Observable
final class LocationViewModel {
    private let repository: LocationRepository

    // State
    var locations: [WeatherLocation] = []
    var isLoading = false
    var errorMessage: String?

    init(repository: LocationRepository) {
        self.repository = repository
    }

    /// Load all locations
    func loadLocations() {
        do {
            locations = try repository.fetchAllLocations()
        } catch {
            errorMessage = "Failed to load locations"
        }
    }

    /// Load favorite locations only
    func loadFavorites() {
        do {
            locations = try repository.fetchFavoriteLocations()
        } catch {
            errorMessage = "Failed to load favorite locations"
        }
    }

    /// Add a new location
    func addLocation(query: String) async -> Bool {
        isLoading = true
        errorMessage = nil

        do {
            let newLocation = try await repository.addLocation(query: query)
            locations.append(newLocation)
            isLoading = false
            return true
        } catch let error as LocationError {
            errorMessage = error.errorDescription
            isLoading = false
            return false
        } catch {
            errorMessage = "An unexpected error occurred"
            isLoading = false
            return false
        }
    }

    /// Delete locations at specified offsets
    func deleteLocations(at offsets: IndexSet) {
        do {
            try repository.delete(at: offsets, from: locations)
            loadLocations() // Refresh
        } catch {
            errorMessage = "Failed to delete location"
        }
    }

    /// Delete a specific location
    func deleteLocation(_ location: WeatherLocation) {
        do {
            try repository.delete(location)
            loadLocations() // Refresh
        } catch {
            errorMessage = "Failed to delete location"
        }
    }

    /// Toggle favorite status
    func toggleFavorite(_ location: WeatherLocation) {
        do {
            try repository.toggleFavorite(location)
            loadLocations()
        } catch {
            errorMessage = "Failed to update favorite status"
        }
    }

    /// Reorder locations
    func moveLocations(from source: IndexSet, to destination: Int) {
        locations.move(fromOffsets: source, toOffset: destination)
        do {
            try repository.reorder(locations: locations)
        } catch {
            errorMessage = "Failed to reorder locations"
        }
    }

    /// Update last updated timestamp
    func updateLastUpdated(_ location: WeatherLocation) {
        do {
            try repository.updateLastUpdated(location)
        } catch {
            errorMessage = "Failed to update timestamp"
        }
    }

    /// Clear error message
    func clearError() {
        errorMessage = nil
    }
}
