//
//  WeatherViewModel.swift
//  simpleWeather
//
//  Created by William Castellano on 2/12/26.
//

import Foundation
import WeatherKit
import SwiftData

/// ViewModel for managing weather data fetching and state
@MainActor
@Observable
final class WeatherViewModel {
    // MARK: - Properties

    /// Weather data for each location, keyed by location ID
    private(set) var weatherData: [UUID: Weather] = [:]

    /// Loading states for individual locations
    private(set) var loadingStates: [UUID: Bool] = [:]

    /// Error messages for individual locations
    private(set) var errorMessages: [UUID: String] = [:]

    /// General loading state
    var isLoading = false

    /// General error message
    var errorMessage: String?

    private let weatherManager: WeatherKitManager

    // MARK: - Initialization

    init(weatherManager: WeatherKitManager = .shared) {
        self.weatherManager = weatherManager
    }

    // MARK: - Public Methods

    /// Fetch weather for a specific location
    func fetchWeather(for location: WeatherLocation) async {
        guard let latitude = location.latitude,
              let longitude = location.longitude else {
            errorMessages[location.id] = "Invalid coordinates"
            return
        }

        loadingStates[location.id] = true
        errorMessages[location.id] = nil

        do {
            let weather = try await weatherManager.fetchWeather(
                latitude: latitude,
                longitude: longitude
            )
            weatherData[location.id] = weather
            loadingStates[location.id] = false
        } catch {
            errorMessages[location.id] = "Failed to fetch weather: \(error.localizedDescription)"
            loadingStates[location.id] = false
        }
    }

    /// Fetch weather for multiple locations in parallel
    func fetchWeather(for locations: [WeatherLocation]) async {
        isLoading = true
        errorMessage = nil

        await withTaskGroup(of: Void.self) { group in
            for location in locations {
                group.addTask {
                    await self.fetchWeather(for: location)
                }
            }
        }

        isLoading = false
    }

    /// Refresh weather for a specific location
    func refreshWeather(for location: WeatherLocation) async {
        await fetchWeather(for: location)
    }

    /// Refresh weather for all locations
    func refreshAllWeather(for locations: [WeatherLocation]) async {
        await fetchWeather(for: locations)
    }

    /// Get weather for a specific location
    func weather(for locationId: UUID) -> Weather? {
        return weatherData[locationId]
    }

    /// Check if weather is loading for a location
    func isLoading(for locationId: UUID) -> Bool {
        return loadingStates[locationId] ?? false
    }

    /// Get error message for a location
    func errorMessage(for locationId: UUID) -> String? {
        return errorMessages[locationId]
    }

    /// Clear weather data for a specific location
    func clearWeather(for locationId: UUID) {
        weatherData.removeValue(forKey: locationId)
        loadingStates.removeValue(forKey: locationId)
        errorMessages.removeValue(forKey: locationId)
    }

    /// Clear all weather data
    func clearAllWeather() {
        weatherData.removeAll()
        loadingStates.removeAll()
        errorMessages.removeAll()
    }

    /// Clear error for a specific location
    func clearError(for locationId: UUID) {
        errorMessages.removeValue(forKey: locationId)
    }

    /// Clear general error
    func clearError() {
        errorMessage = nil
    }
}
