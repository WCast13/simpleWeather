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

    var body: some View {
        VStack(alignment: .leading) {
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

            AdaptiveWeatherRowView(
                location: location,
                temperature: displayData.temperature,
                condition: displayData.condition,
                high: displayData.high,
                low: displayData.low,
                symbolName: displayData.symbolName,
                date: dateLabel
            )

            if showGrid {
                let gridData = WeatherDataTransformer.gridWeatherData(
                    weather,
                    dataType: dataType,
                    hourlyIndex: hourlyIndex
                )

                AdaptiveWeatherGridView(
                    wind: gridData.wind,
                    humidity: gridData.humidity,
                    cloudCover: gridData.cloudCover,
                    uvIndex: gridData.uvIndex,
                    visibility: gridData.visibility,
                    pressure: gridData.pressure,
                    apparentTemperature: gridData.currentWeather.apparentTemperature
                )
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .top)),
                    removal: .opacity.combined(with: .move(edge: .top))
                ))
            }
        }
    }
}
