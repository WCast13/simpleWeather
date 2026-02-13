//
//  WeatherRowContainer.swift
//  simpleWeather
//
//  Created by William Castellano on 2/12/26.
//

import SwiftUI
import WeatherKit

/// Container view for weather row with optional grid
struct WeatherRowContainer: View {
    let location: WeatherLocation
    let weather: Weather
    let dataType: WeatherDataType
    let hourlyIndex: Int
    let dailyIndex: Int
    let showGrid: Bool

    private var preferences: WeatherDisplayPreferences {
        location.displayPreferences
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            let displayData = WeatherDataTransformer.weatherForDisplay(
                weather,
                dataType: dataType,
                hourlyIndex: hourlyIndex,
                dailyIndex: dailyIndex
            )
            let dateLabel = dataType != .current ? WeatherDataTransformer.timeLabel(
                for: dataType == .hourly ? hourlyIndex : dailyIndex,
                dataType: dataType,
                weather: weather
            ) : nil

            // Main weather row
            AdaptiveWeatherRowView(
                location: location,
                temperature: displayData.temperature,
                condition: displayData.condition,
                high: preferences.showHighLow ? displayData.high : "",
                low: preferences.showHighLow ? displayData.low : "",
                symbolName: preferences.showConditionIcon ? displayData.symbolName : "",
                date: dateLabel
            )

            // Show last updated if enabled
            if preferences.showLastUpdated, let lastUpdated = location.lastUpdated {
                Text("Updated \(lastUpdated, format: .relative(presentation: .named))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            // Grid with customizable metrics
            if showGrid && preferences.showGrid {
                let gridData = WeatherDataTransformer.gridWeatherData(
                    weather,
                    dataType: dataType,
                    hourlyIndex: hourlyIndex
                )

                CustomizableWeatherGridView(
                    gridData: gridData,
                    preferences: preferences
                )
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .top)),
                    removal: .opacity.combined(with: .move(edge: .top))
                ))
            }
        }
    }
}

/// Grid view that respects display preferences
struct CustomizableWeatherGridView: View {
    let gridData: GridWeatherData
    let preferences: WeatherDisplayPreferences

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(visibleMetrics, id: \.self) { metric in
                metricView(for: metric)
            }
        }
        .padding(.top, 4)
    }

    private var visibleMetrics: [WeatherMetric] {
        // Use custom order if available, otherwise use visible metrics
        let orderedMetrics = preferences.metricsOrder.filter { preferences.visibleMetrics.contains($0) }
        return orderedMetrics.isEmpty ? preferences.visibleMetrics : orderedMetrics
    }

    @ViewBuilder
    private func metricView(for metric: WeatherMetric) -> some View {
        switch metric {
        case .feelsLike:
            WeatherDataItem(
                title: "Feels Like",
                dataItem: "\(Int(gridData.currentWeather.apparentTemperature.converted(to: .fahrenheit).value))°"
            )
        case .humidity:
            WeatherDataItem(
                title: "Humidity",
                dataItem: "\(Int(gridData.humidity * 100))%"
            )
        case .wind:
            WeatherDataItem(
                title: "Wind",
                dataItem: "\(Int(gridData.wind.speed.converted(to: .milesPerHour).value)) mph"
            )
        case .cloudCover:
            WeatherDataItem(
                title: "Cloud Cover",
                dataItem: "\(Int(gridData.cloudCover * 100))%"
            )
        case .uvIndex:
            WeatherDataItem(
                title: "UV Index",
                dataItem: "\(gridData.uvIndex.value)"
            )
        case .visibility:
            WeatherDataItem(
                title: "Visibility",
                dataItem: String(format: "%.1f mi", gridData.visibility.converted(to: .miles).value)
            )
        case .pressure:
            WeatherDataItem(
                title: "Pressure",
                dataItem: String(format: "%.2f inHg", gridData.pressure.converted(to: .inchesOfMercury).value)
            )
        case .windGust:
            if let gust = gridData.wind.gust {
                WeatherDataItem(
                    title: "Wind Gust",
                    dataItem: "\(Int(gust.converted(to: .milesPerHour).value)) mph"
                )
            }
        }
    }
}
