//
//  WeatherLocation.swift
//  simpleWeather
//
//  Created by William Castellano on 2/3/25.
//

import Foundation
import SwiftData

@Model
class WeatherLocation: Identifiable {
    @Attribute var id: UUID = UUID()
    var city: String?
    var state: String?
    var zipCode: String?
    var latitude: Double = 0.0
    var longitude: Double = 0.0
    
   init (city: String? = nil, state: String? = nil, zipCode: String? = nil, latitude: Double, longitude: Double) {
        self.city = city
        self.state = state
        self.zipCode = zipCode
        self.latitude = latitude
        self.longitude = longitude
    }
}
