//
//  WeatherDataTransformer.swift
//  simpleWeather
//
//  Created by William Castellano on 2/12/26.
//

import Foundation
import WeatherKit

/// Utility for transforming weather data for display
enum WeatherDataType: String, CaseIterable {
    case current = "Current"
    case hourly = "Hourly"
    case daily = "Daily"
}

/// Structure for display weather data
struct DisplayWeatherData {
    let temperature: String
    let condition: String
    let high: String
    let low: String
    let symbolName: String
}

/// Structure for grid weather data
struct GridWeatherData {
    let currentWeather: CurrentWeather
    let wind: Wind
    let humidity: Double
    let cloudCover: Double
    let uvIndex: UVIndex
    let visibility: Measurement<UnitLength>
    let pressure: Measurement<UnitPressure>
}

struct WeatherDataTransformer {
    // MARK: - Display Data Transformation

    /// Transform weather data for display based on selected type and index
    static func weatherForDisplay(
        _ weather: Weather,
        dataType: WeatherDataType,
        hourlyIndex: Int = 0,
        dailyIndex: Int = 0
    ) -> DisplayWeatherData {
        switch dataType {
        case .current:
            return currentWeatherForDisplay(weather)
        case .hourly:
            return hourlyWeatherForDisplay(weather, at: hourlyIndex)
        case .daily:
            return dailyWeatherForDisplay(weather, at: dailyIndex)
        }
    }

    private static func currentWeatherForDisplay(_ weather: Weather) -> DisplayWeatherData {
        let current = weather.currentWeather
        let high = weather.dailyForecast.first?.highTemperature.converted(to: .fahrenheit).value ?? 0
        let low = weather.dailyForecast.first?.lowTemperature.converted(to: .fahrenheit).value ?? 0

        return DisplayWeatherData(
            temperature: "\(Int(current.temperature.converted(to: .fahrenheit).value))°",
            condition: current.condition.description,
            high: "H: \(Int(high))°",
            low: "L: \(Int(low))°",
            symbolName: current.symbolName
        )
    }

    private static func hourlyWeatherForDisplay(_ weather: Weather, at index: Int) -> DisplayWeatherData {
        guard index < weather.hourlyForecast.count else {
            return DisplayWeatherData(
                temperature: "--°",
                condition: "No data",
                high: "H: --°",
                low: "L: --°",
                symbolName: "questionmark"
            )
        }

        let hourWeather = weather.hourlyForecast[index]
        return DisplayWeatherData(
            temperature: "\(Int(hourWeather.temperature.converted(to: .fahrenheit).value))°",
            condition: hourWeather.condition.description,
            high: "Precip: \(Int(hourWeather.precipitationChance * 100))%",
            low: "",
            symbolName: hourWeather.symbolName
        )
    }

    private static func dailyWeatherForDisplay(_ weather: Weather, at index: Int) -> DisplayWeatherData {
        guard index < weather.dailyForecast.count else {
            return DisplayWeatherData(
                temperature: "--°",
                condition: "No data",
                high: "H: --°",
                low: "L: --°",
                symbolName: "questionmark"
            )
        }

        let dayWeather = weather.dailyForecast[index]
        return DisplayWeatherData(
            temperature: "\(Int(dayWeather.highTemperature.converted(to: .fahrenheit).value))°",
            condition: dayWeather.condition.description,
            high: "H: \(Int(dayWeather.highTemperature.converted(to: .fahrenheit).value))°",
            low: "L: \(Int(dayWeather.lowTemperature.converted(to: .fahrenheit).value))°",
            symbolName: dayWeather.symbolName
        )
    }

    // MARK: - Grid Data Transformation

    /// Transform weather data for grid display based on selected type and index
    static func gridWeatherData(
        _ weather: Weather,
        dataType: WeatherDataType,
        hourlyIndex: Int = 0
    ) -> GridWeatherData {
        switch dataType {
        case .current:
            return currentGridWeatherData(weather)
        case .hourly:
            return hourlyGridWeatherData(weather, at: hourlyIndex)
        case .daily:
            return currentGridWeatherData(weather) // Daily uses current data
        }
    }

    private static func currentGridWeatherData(_ weather: Weather) -> GridWeatherData {
        let current = weather.currentWeather
        return GridWeatherData(
            currentWeather: current,
            wind: current.wind,
            humidity: current.humidity,
            cloudCover: current.cloudCover,
            uvIndex: current.uvIndex,
            visibility: current.visibility,
            pressure: current.pressure
        )
    }

    private static func hourlyGridWeatherData(_ weather: Weather, at index: Int) -> GridWeatherData {
        guard index < weather.hourlyForecast.count else {
            return currentGridWeatherData(weather)
        }

        let hourWeather = weather.hourlyForecast[index]
        // HourWeather doesn't have all properties, so we return a mix
        return GridWeatherData(
            currentWeather: weather.currentWeather,
            wind: hourWeather.wind,
            humidity: hourWeather.humidity,
            cloudCover: hourWeather.cloudCover,
            uvIndex: hourWeather.uvIndex,
            visibility: hourWeather.visibility,
            pressure: hourWeather.pressure
        )
    }

    // MARK: - Time Label Formatting

    /// Get time label for a specific index and data type
    static func timeLabel(
        for index: Int,
        dataType: WeatherDataType,
        weather: Weather
    ) -> String {
        switch dataType {
        case .hourly:
            guard index < weather.hourlyForecast.count else { return "" }
            let hourWeather = weather.hourlyForecast[index]
            return hourWeather.date.formatted(.dateTime.weekday(.wide).hour())
        case .daily:
            guard index < weather.dailyForecast.count else { return "" }
            let dayWeather = weather.dailyForecast[index]
            return dayWeather.date.formatted(.dateTime.weekday(.wide))
        case .current:
            return "Current"
        }
    }

    /// Format date for button display
    static func formatButtonDate(_ date: Date, isHourly: Bool) -> String {
        if isHourly {
            return date.formatted(.dateTime.hour())
        } else {
            return date.formatted(.dateTime.weekday(.wide))
        }
    }

    // MARK: - Hourly Picker Helpers

    /// Get unique days from hourly forecast
    static func getUniqueDays(from weather: Weather) -> [Date] {
        let calendar = Calendar.current
        var uniqueDays: [Date] = []
        var seenDays: Set<DateComponents> = []

        for hourWeather in weather.hourlyForecast {
            let dayComponents = calendar.dateComponents([.year, .month, .day], from: hourWeather.date)
            if !seenDays.contains(dayComponents) {
                seenDays.insert(dayComponents)
                if let dayStart = calendar.date(from: dayComponents) {
                    uniqueDays.append(dayStart)
                }
            }
        }

        return uniqueDays
    }

    /// Get hours for a specific day
    static func getHoursForDay(_ day: Date, from weather: Weather) -> [WeatherKit.HourWeather] {
        let calendar = Calendar.current
        let targetDay = calendar.dateComponents([.year, .month, .day], from: day)

        return weather.hourlyForecast.filter { hourWeather in
            let hourDay = calendar.dateComponents([.year, .month, .day], from: hourWeather.date)
            return hourDay == targetDay
        }
    }
}
