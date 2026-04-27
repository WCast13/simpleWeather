//
//  WeatherDisplayPreferences.swift
//  simpleWeather
//
//  Created by William Castellano on 2/13/26.
//

import Foundation

/// Available weather metrics that can be displayed
enum WeatherMetric: String, Codable, CaseIterable, Identifiable {
    case feelsLike = "Feels Like"
    case humidity = "Humidity"
    case wind = "Wind"
    case cloudCover = "Cloud Cover"
    case uvIndex = "UV Index"
    case visibility = "Visibility"
    case pressure = "Pressure"
    case windGust = "Wind Gust"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .feelsLike:
            return "thermometer.medium"
        case .humidity:
            return "humidity.fill"
        case .wind:
            return "wind"
        case .cloudCover:
            return "cloud.fill"
        case .uvIndex:
            return "sun.max.fill"
        case .visibility:
            return "eye.fill"
        case .pressure:
            return "gauge.with.dots.needle.bottom.50percent"
        case .windGust:
            return "wind.circle.fill"
        }
    }
}

/// Display style for the main weather row
enum WeatherRowStyle: String, Codable, CaseIterable {
    case standard = "Standard"
    case compact = "Compact"
    case detailed = "Detailed"
}

/// User preferences for how weather data is displayed
struct WeatherDisplayPreferences: Codable {
    // Main row preferences
    var rowStyle: WeatherRowStyle = .standard
    var showConditionIcon: Bool = true
    var showHighLow: Bool = true

    // Grid preferences
    var showGrid: Bool = true
    var visibleMetrics: [WeatherMetric] = WeatherMetric.allCases
    var metricsOrder: [WeatherMetric] = WeatherMetric.allCases

    // Additional options
    var showLastUpdated: Bool = false
    var use12HourFormat: Bool = true

    // MARK: - Default Preferences

    static var `default`: WeatherDisplayPreferences {
        return WeatherDisplayPreferences()
    }

    // MARK: - Preset Configurations

    static var minimal: WeatherDisplayPreferences {
        var prefs = WeatherDisplayPreferences()
        prefs.rowStyle = .compact
        prefs.showGrid = false
        prefs.showHighLow = true
        return prefs
    }

    static var detailed: WeatherDisplayPreferences {
        var prefs = WeatherDisplayPreferences()
        prefs.rowStyle = .detailed
        prefs.showGrid = true
        prefs.showLastUpdated = true
        prefs.visibleMetrics = WeatherMetric.allCases
        return prefs
    }

    static var essential: WeatherDisplayPreferences {
        var prefs = WeatherDisplayPreferences()
        prefs.rowStyle = .standard
        prefs.showGrid = true
        prefs.visibleMetrics = [.feelsLike, .humidity, .wind, .uvIndex]
        prefs.metricsOrder = [.feelsLike, .humidity, .wind, .uvIndex]
        return prefs
    }

    // MARK: - Helper Methods

    /// Check if a metric is visible
    func isMetricVisible(_ metric: WeatherMetric) -> Bool {
        return visibleMetrics.contains(metric)
    }

    /// Reset to default preferences
    mutating func reset() {
        self = .default
    }
}
