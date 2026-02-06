//
//  WeatherModulesView.swift
//  simpleWeather
//
//  Created by William Castellano on 2/19/25.
//

import SwiftUI
import WeatherKit

struct WeatherModulesView: View {
    let weather: Weather
    let dataType: WeatherDataType
    let hourlyIndex: Int
    let dailyIndex: Int

    var currentWeather: CurrentWeather {
        weather.currentWeather
    }

    var displayWeather: (wind: Wind, humidity: Double, cloudCover: Double, uvIndex: UVIndex, visibility: Measurement<UnitLength>, pressure: Measurement<UnitPressure>, pressureTrend: PressureTrend) {
        switch dataType {
        case .current:
            let current = currentWeather
            return (current.wind, current.humidity, current.cloudCover, current.uvIndex, current.visibility, current.pressure, current.pressureTrend)
        case .hourly:
            guard hourlyIndex < weather.hourlyForecast.count else {
                let current = currentWeather
                return (current.wind, current.humidity, current.cloudCover, current.uvIndex, current.visibility, current.pressure, current.pressureTrend)
            }
            let hourWeather = weather.hourlyForecast[hourlyIndex]
            return (hourWeather.wind, hourWeather.humidity, hourWeather.cloudCover, hourWeather.uvIndex, hourWeather.visibility, hourWeather.pressure, hourWeather.pressureTrend)
        case .daily:
            // Daily doesn't have detailed current conditions, use current weather
            let current = currentWeather
            return (current.wind, current.humidity, current.cloudCover, current.uvIndex, current.visibility, current.pressure, current.pressureTrend)
        }
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                // Wind Module
                VStack(spacing: 4) {
                    Text("Wind")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    WindModuleView(wind: displayWeather.wind, size: 120)
                }
                .padding()
                .background(Color.secondary.opacity(0.08))
                .cornerRadius(12)

                // Humidity Module
                VStack(spacing: 4) {
                    Text("Humidity")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    HumidityModuleView(humidity: displayWeather.humidity, size: 120)
                }
                .padding()
                .background(Color.secondary.opacity(0.08))
                .cornerRadius(12)

                // Pressure Module
                VStack(spacing: 4) {
                    Text("Pressure")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    PressureTrendModuleView(
                        pressure: displayWeather.pressure,
                        pressureTrend: displayWeather.pressureTrend,
                        size: 120
                    )
                }
                .padding()
                .background(Color.secondary.opacity(0.08))
                .cornerRadius(12)

                // UV Index Module
                VStack(spacing: 4) {
                    Text("UV Index")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    UVIndexModuleView(uvIndex: displayWeather.uvIndex.value, size: 120)
                }
                .padding()
                .background(Color.secondary.opacity(0.08))
                .cornerRadius(12)

                // Visibility Module
                VStack(spacing: 4) {
                    Text("Visibility")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    VisibilityModuleView(visibility: displayWeather.visibility, size: 120)
                }
                .padding()
                .background(Color.secondary.opacity(0.08))
                .cornerRadius(12)

                // Cloud Cover Module
                VStack(spacing: 4) {
                    Text("Cloud Cover")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    CloudCoverByHeightModuleView(cloudCover: displayWeather.cloudCover, size: 120)
                }
                .padding()
                .background(Color.secondary.opacity(0.08))
                .cornerRadius(12)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }
}

// MARK: - Previews
#Preview("Weather Modules - Current") {
    WeatherModulesViewPreview()
}

#Preview("Weather Modules - Hourly") {
    WeatherModulesViewPreview(dataType: .hourly, hourlyIndex: 3)
}

#Preview("Weather Modules - Daily") {
    WeatherModulesViewPreview(dataType: .daily, dailyIndex: 1)
}

// MARK: - Preview Helper
private struct WeatherModulesViewPreview: View {
    @State private var weather: Weather?
    let dataType: WeatherDataType
    let hourlyIndex: Int
    let dailyIndex: Int

    init(dataType: WeatherDataType = .current, hourlyIndex: Int = 0, dailyIndex: Int = 0) {
        self.dataType = dataType
        self.hourlyIndex = hourlyIndex
        self.dailyIndex = dailyIndex
    }

    var body: some View {
        Group {
            if let weather = weather {
                VStack {
                    Text("Weather Modules Preview")
                        .font(.title2)
                        .bold()
                        .padding()

                    WeatherModulesView(
                        weather: weather,
                        dataType: dataType,
                        hourlyIndex: hourlyIndex,
                        dailyIndex: dailyIndex
                    )
                }
            } else {
                ProgressView("Loading weather modules...")
            }
        }
        .task {
            do {
                weather = try await WeatherKitManager.shared.fetchWeather(
                    latitude: 37.7749,
                    longitude: -122.4194
                )
            } catch {
                print("Preview error: \(error)")
            }
        }
    }
}
