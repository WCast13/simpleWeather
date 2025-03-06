//
//  WeatherManager.swift
//  simpleWeather
//
//  Created by William Castellano on 2/3/25.
//

import Foundation
import WeatherKit
import CoreLocation

@MainActor
class WeatherKitManager: ObservableObject {
    
    static let shared = WeatherKitManager()
    private let weatherService = WeatherService()
    
    func fetchWeather(latitude: Double, longitude: Double) async throws -> Weather {
        let location = CLLocation(latitude: latitude, longitude: longitude)
        print("Fetching weather for \(location)")
        return try await weatherService.weather(for: location)
    }
}
