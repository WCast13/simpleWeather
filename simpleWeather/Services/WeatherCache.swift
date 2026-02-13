//
//  WeatherCache.swift
//  simpleWeather
//
//  Created by William Castellano on 2/12/26.
//

import Foundation
import WeatherKit

/// Cached weather data with timestamp
struct CachedWeather {
    let weather: Weather
    let timestamp: Date

    /// Check if cache is expired
    func isExpired(expirationMinutes: Int = 30) -> Bool {
        let expirationInterval = TimeInterval(expirationMinutes * 60)
        return Date().timeIntervalSince(timestamp) > expirationInterval
    }
}

/// Cache manager for weather data
@MainActor
final class WeatherCache {
    // Singleton instance
    static let shared = WeatherCache()

    // Cache storage keyed by location ID
    private var cache: [UUID: CachedWeather] = [:]

    // Configurable expiration time in minutes
    private let expirationMinutes: Int

    // MARK: - Initialization

    init(expirationMinutes: Int = 30) {
        self.expirationMinutes = expirationMinutes
    }

    // MARK: - Public Methods

    /// Get cached weather for a location if valid
    func get(for locationId: UUID) -> Weather? {
        guard let cached = cache[locationId] else {
            return nil
        }

        // Check if cache is expired
        if cached.isExpired(expirationMinutes: expirationMinutes) {
            cache.removeValue(forKey: locationId)
            return nil
        }

        return cached.weather
    }

    /// Store weather data in cache
    func set(_ weather: Weather, for locationId: UUID) {
        cache[locationId] = CachedWeather(weather: weather, timestamp: Date())
    }

    /// Clear cache for a specific location
    func clear(for locationId: UUID) {
        cache.removeValue(forKey: locationId)
    }

    /// Clear all cached data
    func clearAll() {
        cache.removeAll()
    }

    /// Get the timestamp of cached data for a location
    func getCacheTimestamp(for locationId: UUID) -> Date? {
        return cache[locationId]?.timestamp
    }

    /// Check if cache exists and is valid for a location
    func isValid(for locationId: UUID) -> Bool {
        guard let cached = cache[locationId] else {
            return false
        }
        return !cached.isExpired(expirationMinutes: expirationMinutes)
    }

    /// Get time remaining until cache expires (in seconds)
    func timeUntilExpiration(for locationId: UUID) -> TimeInterval? {
        guard let cached = cache[locationId] else {
            return nil
        }

        let expirationInterval = TimeInterval(expirationMinutes * 60)
        let elapsed = Date().timeIntervalSince(cached.timestamp)
        let remaining = expirationInterval - elapsed

        return remaining > 0 ? remaining : nil
    }

    /// Remove expired cache entries
    func cleanupExpired() {
        let expiredKeys = cache.filter { $0.value.isExpired(expirationMinutes: expirationMinutes) }.map { $0.key }
        expiredKeys.forEach { cache.removeValue(forKey: $0) }
    }
}
