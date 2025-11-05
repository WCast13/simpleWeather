//
//  GeocodingService.swift
//  simpleWeather
//
//  Created by William Castellano on 11/5/25.
//

import Foundation
import MapKit
import CoreLocation

/// Result of a geocoding search
struct GeocodingResult {
    let coordinate: CLLocationCoordinate2D
    let city: String?
    let state: String?
    let country: String?
    let formattedAddress: String
}

/// Protocol for geocoding services (allows testing with mock)
protocol GeocodingServiceProtocol {
    func geocode(_ query: String) async throws -> GeocodingResult
}

/// Modern geocoding service using MKLocalSearch (iOS 26+)
@MainActor
final class GeocodingService: GeocodingServiceProtocol {

    /// Geocode a location query into coordinates and address components
    /// - Parameter query: The search query (city name, state, or ZIP code)
    /// - Returns: GeocodingResult with coordinates and address information
    /// - Throws: LocationError if geocoding fails
    func geocode(_ query: String) async throws -> GeocodingResult {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmed.isEmpty else {
            throw LocationError.emptyQuery
        }

        guard trimmed.count >= 2, trimmed.count <= 100 else {
            throw LocationError.invalidInput
        }

        // iOS 26+: Use MKLocalSearch for modern, natural language queries
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = trimmed
        request.resultTypes = [.address]

        let search = MKLocalSearch(request: request)

        do {
            let response = try await search.start()

            guard let item = response.mapItems.first else {
                throw LocationError.noResults
            }

            // iOS 26+: Use location property instead of deprecated placemark
            guard let location = item.location else {
                throw LocationError.locationUnavailable
            }

            var city: String?
            var state: String?
            var country: String?
            var formattedAddress = trimmed

            // iOS 26+: Extract city and state from addressRepresentations (CNPostalAddress)
            if let postalAddress = item.addressRepresentations {
                city = postalAddress.city.isEmpty ? nil : postalAddress.city
                state = postalAddress.state.isEmpty ? nil : postalAddress.state
                country = postalAddress.country.isEmpty ? nil : postalAddress.country

                // Create formatted address
                var parts: [String] = []
                if let city = city { parts.append(city) }
                if let state = state { parts.append(state) }
                if !parts.isEmpty {
                    formattedAddress = parts.joined(separator: ", ")
                }
            }

            return GeocodingResult(
                coordinate: location.coordinate,
                city: city,
                state: state,
                country: country,
                formattedAddress: formattedAddress
            )
        } catch {
            if let locationError = error as? LocationError {
                throw locationError
            }
            throw LocationError.geocodingFailed(error.localizedDescription)
        }
    }
}
