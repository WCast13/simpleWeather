//
//  LocationError.swift
//  simpleWeather
//
//  Created by William Castellano on 11/5/25.
//

import Foundation

/// Custom error types for location operations
enum LocationError: LocalizedError {
    case emptyQuery
    case invalidInput
    case noResults
    case geocodingFailed(String)
    case duplicateLocation
    case saveFailed
    case locationUnavailable

    var errorDescription: String? {
        switch self {
        case .emptyQuery:
            return "Please enter a city name or ZIP code"
        case .invalidInput:
            return "Invalid input. Please enter a valid location."
        case .noResults:
            return "No location found. Please try again."
        case .geocodingFailed(let message):
            return "Geocoding failed: \(message)"
        case .duplicateLocation:
            return "This location is already added"
        case .saveFailed:
            return "Failed to save location"
        case .locationUnavailable:
            return "Location data is unavailable for this result"
        }
    }
}
