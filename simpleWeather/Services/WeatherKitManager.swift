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
    private let service = WeatherService()
    
    static let epcotCoordinates: CLLocation = CLLocation(latitude: 28.3747, longitude: -81.5494)
    
    func fetchWeather(latitude: Double, longitude: Double) async throws -> Weather {
        let location = CLLocation(latitude: latitude, longitude: longitude)
        print("Fetching weather for \(location)")
        return try await service.weather(for: location)
    }
    
    /// Fetch daily weather summary for the past 30 days
    /// - Parameters:
    ///   - latitude: Location latitude
    ///   - longitude: Location longitude
    /// - Note: WeatherKit daily summary only supports ~30 days of historical data
    func fetchWeatherSummary(latitude: Double, longitude: Double) async {
        let location = CLLocation(latitude: latitude, longitude: longitude)
        let epcotCoordinates: CLLocation = CLLocation(latitude: 28.3747, longitude: -81.5494)
        
        

        // WeatherKit daily summary typically supports only 30 days of historical data
        let thirtyDaysAgo = Date(timeIntervalSinceNow: (-60 * 60 * 24 * 90))
        let yesterday = Date(timeIntervalSinceNow: (-60 * 60 * 24))
        let dateInterval = DateInterval(start: thirtyDaysAgo, end: yesterday)

        print("Requesting daily summary from \(thirtyDaysAgo.formatted(date: .abbreviated, time: .omitted)) to \(yesterday.formatted(date: .abbreviated, time: .omitted))")

        do {
            let (dailyPrecipitationSummary, dailyTemperatureSummary) = try await service.dailySummary(
                for: epcotCoordinates,
                forDaysIn: dateInterval,
                including: .precipitation, .temperature
            )

            print("\n=== Daily Weather Summary ===")
            print("Temperature Data:")
            print("First: \(dailyTemperatureSummary.first?.date.formatted(date: .abbreviated, time: .omitted) ?? "N/A")")
            print("Last: \(dailyTemperatureSummary.last?.date.formatted(date: .abbreviated, time: .omitted) ?? "N/A")")
            print("Total days: \(dailyTemperatureSummary.count)\n")

            // Print first 10 days
            for day in dailyTemperatureSummary {
                print("\(day.date.formatted(date: .abbreviated, time: .omitted)): \(Int((day.lowTemperature.converted(to: .fahrenheit).value)))°F - \(Int((day.highTemperature.converted(to: .fahrenheit).value)))°F")
            }

            print("\nPrecipitation Data:")
            print("Total days: \(dailyPrecipitationSummary.count)")
            print("\(dailyPrecipitationSummary.days.first?.precipitationAmount.converted(to: .inches).description ?? "")")

            // Print days with precipitation
            let daysWithPrecip = dailyPrecipitationSummary.filter { $0.precipitationAmount.value > 0.2 }
            print("Days with precipitation: \(daysWithPrecip.count)")

            for day in daysWithPrecip {
                print("\(day.date.formatted(date: .abbreviated, time: .omitted)): \(day.precipitationAmount.converted(to: .inches).value.formatted(.number.precision(.fractionLength(2)))) in")
            }

            print("===========================\n")

        } catch {
            print("Error fetching weather summary: \(error)")
        }
    }
}
