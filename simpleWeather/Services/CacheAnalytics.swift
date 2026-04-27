//
//  CacheAnalytics.swift
//  simpleWeather
//
//  Created by William Castellano on 2/12/26.
//

import Foundation

/// Analytics data for cache performance
struct CacheAnalytics: Codable {
    var totalHits: Int = 0
    var totalMisses: Int = 0
    var totalEvictions: Int = 0
    var totalWrites: Int = 0
    var lastReset: Date = Date()

    // MARK: - Computed Properties

    /// Cache hit rate as a percentage
    var hitRate: Double {
        let total = totalHits + totalMisses
        guard total > 0 else { return 0.0 }
        return Double(totalHits) / Double(total) * 100.0
    }

    /// Total cache operations
    var totalOperations: Int {
        return totalHits + totalMisses
    }

    // MARK: - Methods

    /// Record a cache hit
    mutating func recordHit() {
        totalHits += 1
    }

    /// Record a cache miss
    mutating func recordMiss() {
        totalMisses += 1
    }

    /// Record a cache eviction
    mutating func recordEviction() {
        totalEvictions += 1
    }

    /// Record a cache write
    mutating func recordWrite() {
        totalWrites += 1
    }

    /// Reset all analytics
    mutating func reset() {
        totalHits = 0
        totalMisses = 0
        totalEvictions = 0
        totalWrites = 0
        lastReset = Date()
    }
}
