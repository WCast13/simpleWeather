//
//  WeatherLocation.swift
//  simpleWeather
//
//  Created by William Castellano on 2/3/25.
//

import Foundation
import SwiftData
import CoreLocation

@Model
class WeatherLocation: Identifiable {
    var id: UUID = UUID()
    var city: String?
    var state: String?
    var zipCode: String?
    var latitude: Double?
    var longitude: Double?

    // Metadata
    var dateAdded: Date?
    var lastUpdated: Date?
    var displayOrder: Int?
    var isFavorite: Bool?

    // Display preferences (stored as encoded Data)
    @Attribute(.externalStorage)
    var displayPreferencesData: Data?

    init(date: Date? = Date(),
        city: String? = nil,
         state: String? = nil,
         zipCode: String? = nil,
         latitude: Double? = 0.0,
         longitude: Double? = 0.0,
         displayOrder: Int? = 0,
         isFavorite: Bool? = false) {
        self.id = UUID()
        self.city = city
        self.state = state
        self.zipCode = zipCode
        self.latitude = latitude ?? 0.0
        self.longitude = longitude ?? 00
        self.dateAdded = Date()
        self.displayOrder = displayOrder
        self.isFavorite = isFavorite
        self.displayPreferencesData = nil
    }

    // MARK: - Display Preferences

    /// Get display preferences for this location
    var displayPreferences: WeatherDisplayPreferences {
        get {
            guard let data = displayPreferencesData else {
                return .default
            }
            return (try? JSONDecoder().decode(WeatherDisplayPreferences.self, from: data)) ?? .default
        }
        set {
            displayPreferencesData = try? JSONEncoder().encode(newValue)
        }
    }

    /// Computed property for display name
    var displayName: String {
        if let city = city, let state = state {
            return "\(city), \(state)"
        } else if let city = city {
            return city
        } else if let zipCode = zipCode {
            return zipCode
        } else {
            return "Unknown Location"
        }
    }

//    /// Check if location is close to another (within threshold meters)
//    func isNear(_ other: WeatherLocation, threshold: CLLocationDistance = 1000) -> Bool {
//        let location1 = CLLocation(latitude: latitude ?? 0.0, longitude: longitude ?? 0.0)
//        let location2 = CLLocation(latitude: other.latitude ?? 0.0, longitude: other.longitude ?? 0.0)
//        return location1.distance(from: location2) < threshold
//    }
}
