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
    
    func fetchWeather(latitude: Double, longitude: Double) async throws -> Weather {
        let location = CLLocation(latitude: latitude, longitude: longitude)
        print("Fetching weather for \(location)")
        return try await service.weather(for: location)
    }
}

/*
 let (dailyPrecipitationStatistics, dailyTemperatureStatistics) = try await service.dailyStatistics(for: newYork, forDaysIn: timeInterval, including: .precipitation, .temperature)
 
 let (dailyPrecipitationSummary, dailyTemperatureSummary) = try await service.dailySummary(for: newYork, forDaysIn: timeInterval, including: .precipitation, .temperature)

 let (dailyPrecipitationStatistics, dailyTemperatureStatistics) = try await service.dailyStatistics(for: newYork, including: .precipitation, .temperature)

 let (dailyPrecipitationStatistics, dailyTemperatureStatistics) = try await service.dailyStatistics(for: newYork, startDay: 365, endDay: 2, including: .precipitation, .temperature)
 
 let (dailyPrecipitationSummary, dailyTemperatureSummary) = try await service.dailySummary(for: newYork, forDaysIn: timeInterval, including: .precipitation, .temperature)
 
 let (dailyPrecipitationSummary, dailyTemperatureSummary) = try await service.dailySummary(for: newYork, including: .precipitation, .temperature)

 let hourlyTemperatureStatistics = try await service.hourlyStatistics(for: newYork, forHoursIn: interval, including: .temperature)

 let hourlyTemperatureStatistics = try await service.hourlyStatistics(for: newYork, including: .temperature)

 let hourlyTemperatureStatistics = try await service.hourlyStatistics(for: newYork, startHour: 1, endHour: 24, including: .temperature)
 Precondition - startHour in 1...8784 && endHour in 1...8784

 let (monthlyPrecipitationStatistics, monthlyTemperatureStatistics) = try await service.monthlyStatistics(for: newYork, forMonthsIn: interval, including: .precipitation, .temperature)

 let (monthlyPrecipitationStatistics, monthlyTemperatureStatistics) = try await service.monthlyStatistics(for: newYork, including: .precipitation, .temperature)

 let (monthlyPrecipitationStatistics, monthlyTemperatureStatistics) = try await service.monthlyStatistics(for: newYork, startMonth: 1, endMonth: 12, including: .precipitation, .temperature)

 let (monthlyPrecipitationStatistics, monthlyTemperatureStatistics) = try await service.monthlyStatistics(for: newYork, startMonth: 11, endMonth: 2, including: .precipitation, .temperature)
 Precondition - startMonth in 1...12 && endMonth in 1...12

 let (current, minute, hourly, daily, alerts) = try await service.weather(for: newYork, including: .current, .minute, .hourly, .daily, .alerts)
 */

