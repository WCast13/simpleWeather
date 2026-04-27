//
//  WeatherCache.swift
//  simpleWeather
//
//  Created by William Castellano on 2/12/26.
//

import Foundation
import WeatherKit

/// Persisted cache metadata
struct CacheMetadata: Codable {
    var locationId: UUID
    var timestamp: Date
    var expirationDate: Date

    var isExpired: Bool {
        return Date() > expirationDate
    }
}

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

/// Cache manager for weather data with persistence and analytics
@MainActor
@Observable
final class WeatherCache {
    // Singleton instance
    static let shared = WeatherCache()

    // Cache storage keyed by location ID (in-memory)
    private var cache: [UUID: CachedWeather] = [:]

    // Cache metadata (persisted)
    private var metadata: [UUID: CacheMetadata] = [:]

    // Analytics
    private(set) var analytics = CacheAnalytics()

    // Configuration
    private let expirationMinutes: Int
    private let maxCacheSize: Int
    private let fileManager = FileManager.default
    private let metadataURL: URL
    private let analyticsURL: URL

    // MARK: - Initialization

    init(expirationMinutes: Int = 30, maxCacheSize: Int = 50) {
        self.expirationMinutes = expirationMinutes
        self.maxCacheSize = maxCacheSize

        // Initialize file paths
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.metadataURL = documentsPath.appendingPathComponent("weatherCacheMetadata.json")
        self.analyticsURL = documentsPath.appendingPathComponent("cacheAnalytics.json")

        loadPersistedData()
    }

    // MARK: - Public Methods

    /// Get cached weather for a location if valid
    func get(for locationId: UUID) -> Weather? {
        // Check in-memory cache first
        if let cached = cache[locationId] {
            if !cached.isExpired(expirationMinutes: expirationMinutes) {
                analytics.recordHit()
                return cached.weather
            } else {
                // Expired, remove from cache
                cache.removeValue(forKey: locationId)
                metadata.removeValue(forKey: locationId)
                analytics.recordEviction()
                persistMetadata()
            }
        }

        analytics.recordMiss()
        return nil
    }

    /// Store weather data in cache
    func set(_ weather: Weather, for locationId: UUID) {
        // Enforce cache size limit
        if cache.count >= maxCacheSize && cache[locationId] == nil {
            evictOldestEntry()
        }

        let timestamp = Date()
        let expirationDate = timestamp.addingTimeInterval(TimeInterval(expirationMinutes * 60))

        cache[locationId] = CachedWeather(weather: weather, timestamp: timestamp)
        metadata[locationId] = CacheMetadata(
            locationId: locationId,
            timestamp: timestamp,
            expirationDate: expirationDate
        )

        analytics.recordWrite()
        persistMetadata()
        persistAnalytics()
    }

    /// Clear cache for a specific location
    func clear(for locationId: UUID) {
        cache.removeValue(forKey: locationId)
        metadata.removeValue(forKey: locationId)
        persistMetadata()
    }

    /// Clear all cached data
    func clearAll() {
        cache.removeAll()
        metadata.removeAll()
        persistMetadata()
    }

    /// Get the timestamp of cached data for a location
    func getCacheTimestamp(for locationId: UUID) -> Date? {
        return metadata[locationId]?.timestamp
    }

    /// Check if cache exists and is valid for a location
    func isValid(for locationId: UUID) -> Bool {
        guard let meta = metadata[locationId] else {
            return false
        }
        return !meta.isExpired
    }

    /// Remove expired cache entries
    func cleanupExpired() {
        let expiredKeys = metadata.filter { $0.value.isExpired }.map { $0.key }
        expiredKeys.forEach { locationId in
            cache.removeValue(forKey: locationId)
            metadata.removeValue(forKey: locationId)
            analytics.recordEviction()
        }

        if !expiredKeys.isEmpty {
            persistMetadata()
            persistAnalytics()
        }
    }

    /// Get current cache size
    var currentSize: Int {
        return cache.count
    }

    /// Reset analytics
    func resetAnalytics() {
        analytics.reset()
        persistAnalytics()
    }

    // MARK: - Private Methods

    /// Load persisted metadata and analytics
    private func loadPersistedData() {
        loadMetadata()
        loadAnalytics()
        cleanupExpired()
    }

    /// Load cache metadata from disk
    private func loadMetadata() {
        guard fileManager.fileExists(atPath: metadataURL.path) else {
            return
        }

        do {
            let data = try Data(contentsOf: metadataURL)
            let decoder = JSONDecoder()
            let metadataArray = try decoder.decode([CacheMetadata].self, from: data)

            metadata = Dictionary(uniqueKeysWithValues: metadataArray.map { ($0.locationId, $0) })
        } catch {
            print("Failed to load cache metadata: \(error.localizedDescription)")
        }
    }

    /// Persist cache metadata to disk
    private func persistMetadata() {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let metadataArray = Array(metadata.values)
            let data = try encoder.encode(metadataArray)
            try data.write(to: metadataURL, options: .atomic)
        } catch {
            print("Failed to persist cache metadata: \(error.localizedDescription)")
        }
    }

    /// Load analytics from disk
    private func loadAnalytics() {
        guard fileManager.fileExists(atPath: analyticsURL.path) else {
            return
        }

        do {
            let data = try Data(contentsOf: analyticsURL)
            let decoder = JSONDecoder()
            analytics = try decoder.decode(CacheAnalytics.self, from: data)
        } catch {
            print("Failed to load analytics: \(error.localizedDescription)")
        }
    }

    /// Persist analytics to disk
    private func persistAnalytics() {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(analytics)
            try data.write(to: analyticsURL, options: .atomic)
        } catch {
            print("Failed to persist analytics: \(error.localizedDescription)")
        }
    }

    /// Evict the oldest cache entry
    private func evictOldestEntry() {
        guard let oldestEntry = metadata.min(by: { $0.value.timestamp < $1.value.timestamp }) else {
            return
        }

        cache.removeValue(forKey: oldestEntry.key)
        metadata.removeValue(forKey: oldestEntry.key)
        analytics.recordEviction()
    }
}
