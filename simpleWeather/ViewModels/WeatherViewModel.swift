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

    /// Offline mode indicator
    private(set) var isOffline: Bool = false

    private let weatherManager: WeatherKitManager
    private let cache: WeatherCache
    private let networkMonitor: NetworkMonitor

    // MARK: - Initialization

    init(weatherManager: WeatherKitManager = .shared, cache: WeatherCache = .shared, networkMonitor: NetworkMonitor = .shared) {
        self.weatherManager = weatherManager
        self.cache = cache
        self.networkMonitor = networkMonitor
        self.isOffline = networkMonitor.isOffline
    }

    // MARK: - Public Methods

    /// Fetch weather for a specific location
    /// - Parameters:
    ///   - location: The weather location to fetch data for
    ///   - forceRefresh: If true, bypass cache and fetch fresh data
    func fetchWeather(for location: WeatherLocation, forceRefresh: Bool = false) async {
        guard let latitude = location.latitude,
              let longitude = location.longitude else {
            errorMessages[location.id] = "Invalid coordinates for \(location.city ?? "unknown location")"
            return
        }

        // Update offline status
        isOffline = networkMonitor.isOffline

        // Check cache first unless force refresh is requested
        if !forceRefresh, let cachedWeather = cache.get(for: location.id) {
            weatherData[location.id] = cachedWeather
            errorMessages[location.id] = nil
            return
        }

        // If offline and no valid cache, show offline message
        if networkMonitor.isOffline {
            // Check if we have expired cache we can show
            if let cachedWeather = cache.get(for: location.id) {
                weatherData[location.id] = cachedWeather
                errorMessages[location.id] = "Showing cached data (offline mode)"
            } else {
                errorMessages[location.id] = "No internet connection. Weather data not available."
            }
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
            cache.set(weather, for: location.id)
            loadingStates[location.id] = false
            errorMessages[location.id] = nil
        } catch {
            // On error, try to show cached data as fallback
            if let cachedWeather = cache.get(for: location.id) {
                weatherData[location.id] = cachedWeather
                errorMessages[location.id] = "Using cached data (\(weatherErrorMessage(for: error, location: location)))"
            } else {
                errorMessages[location.id] = weatherErrorMessage(for: error, location: location)
            }
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

    /// Refresh weather for a specific location (bypasses cache)
    func refreshWeather(for location: WeatherLocation) async {
        await fetchWeather(for: location, forceRefresh: true)
    }

    /// Refresh weather for all locations (bypasses cache)
    func refreshAllWeather(for locations: [WeatherLocation]) async {
        isLoading = true
        errorMessage = nil

        await withTaskGroup(of: Void.self) { group in
            for location in locations {
                group.addTask {
                    await self.fetchWeather(for: location, forceRefresh: true)
                }
            }
        }

        isLoading = false
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
        cache.clear(for: locationId)
    }

    /// Clear all weather data
    func clearAllWeather() {
        weatherData.removeAll()
        loadingStates.removeAll()
        errorMessages.removeAll()
        cache.clearAll()
    }

    /// Clear error for a specific location
    func clearError(for locationId: UUID) {
        errorMessages.removeValue(forKey: locationId)
    }

    /// Clear general error
    func clearError() {
        errorMessage = nil
    }

    /// Check if cached data is available for a location
    func isCached(for locationId: UUID) -> Bool {
        return cache.isValid(for: locationId)
    }

    /// Get cache timestamp for a location
    func cacheTimestamp(for locationId: UUID) -> Date? {
        return cache.getCacheTimestamp(for: locationId)
    }

    /// Background refresh for all locations (non-blocking)
    func backgroundRefreshAll(for locations: [WeatherLocation]) {
        Task(priority: .background) {
            await withTaskGroup(of: Void.self) { group in
                for location in locations {
                    group.addTask {
                        await self.fetchWeather(for: location, forceRefresh: true)
                    }
                }
            }
        }
    }

    /// Background refresh for locations with expired cache
    func backgroundRefreshExpired(for locations: [WeatherLocation]) {
        Task(priority: .background) {
            let expiredLocations = locations.filter { !cache.isValid(for: $0.id) }

            await withTaskGroup(of: Void.self) { group in
                for location in expiredLocations {
                    group.addTask {
                        await self.fetchWeather(for: location)
                    }
                }
            }
        }
    }

    /// Schedule periodic background refresh (call from app delegate or scene)
    func schedulePeriodicRefresh(for locations: [WeatherLocation], intervalMinutes: Int = 15) {
        Task {
            while true {
                try? await Task.sleep(for: .seconds(intervalMinutes * 60))

                // Only refresh if online
                guard !networkMonitor.isOffline else { continue }

                await backgroundRefreshExpired(for: locations)
            }
        }
    }

    // MARK: - Private Methods

    /// Create a user-friendly error message
    private func weatherErrorMessage(for error: Error, location: WeatherLocation) -> String {
        let cityName = location.city ?? "this location"

        // Check for common error types
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet:
                return "No internet connection. Please check your network and try again."
            case .timedOut:
                return "Request timed out. Please try again."
            case .cannotFindHost, .cannotConnectToHost:
                return "Cannot connect to weather service. Please try again later."
            default:
                return "Network error for \(cityName). Please check your connection."
            }
        }

        // Generic error message
        let errorDescription = (error as NSError).localizedDescription
        return "Unable to fetch weather for \(cityName): \(errorDescription)"
    }
}
