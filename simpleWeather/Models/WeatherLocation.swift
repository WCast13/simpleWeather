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
    @Attribute(.unique) var id: UUID
    var city: String?
    var state: String?
    var zipCode: String?
    var latitude: Double
    var longitude: Double

    // Metadata
    var dateAdded: Date
    var lastUpdated: Date?
    var displayOrder: Int
    var isFavorite: Bool

    init(city: String? = nil,
         state: String? = nil,
         zipCode: String? = nil,
         latitude: Double,
         longitude: Double,
         displayOrder: Int = 0,
         isFavorite: Bool = false) {
        self.id = UUID()
        self.city = city
        self.state = state
        self.zipCode = zipCode
        self.latitude = latitude
        self.longitude = longitude
        self.dateAdded = Date()
        self.displayOrder = displayOrder
        self.isFavorite = isFavorite
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

    /// Check if location is close to another (within threshold meters)
    func isNear(_ other: WeatherLocation, threshold: CLLocationDistance = 1000) -> Bool {
        let location1 = CLLocation(latitude: latitude, longitude: longitude)
        let location2 = CLLocation(latitude: other.latitude, longitude: other.longitude)
        return location1.distance(from: location2) < threshold
    }
}
