//
//  AdaptiveWeatherRowView.swift
//  simpleWeather
//
//  Created by William Castellano on 2/19/25.
//

import SwiftUI
import WeatherKit

struct AdaptiveWeatherRowView: View {
    let location: WeatherLocation
    let temperature: String
    let condition: String
    let high: String
    let low: String
    let symbolName: String
    let date: String?

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(location.city)
                    .font(.headline)

                if let date = date {
                    Text(date)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Text(condition)
                .font(.caption)
                .multilineTextAlignment(.trailing)

            Spacer()

            HStack(spacing: 8) {
                // Weather icon
                if !symbolName.isEmpty {
                    Image(systemName: symbolName)
                        .font(.title)
                        .symbolRenderingMode(.multicolor)
                }

                VStack(alignment: .trailing, spacing: 4) {
                    Text(temperature)
                        .font(.system(size: 44, weight: .light))

                    HStack(spacing: 4) {
                        Text(high)
                            .font(.caption)
                        if !low.isEmpty {
                            Text(low)
                                .font(.caption)
                        }
                    }
                }
            }
        }
    }
}

struct AdaptiveWeatherGridView: View {
    let wind: Wind
    let humidity: Double
    let cloudCover: Double
    let uvIndex: UVIndex
    let visibility: Measurement<UnitLength>
    let pressure: Measurement<UnitPressure>
    let apparentTemperature: Measurement<UnitTemperature>

    private var gridItems: [WeatherGridItem] {
        var items: [WeatherGridItem] = []

        items.append(WeatherGridItem(
            title: "Feels Like",
            value: "\(String(format: "%.0f", apparentTemperature.converted(to: .fahrenheit).value))°",
            icon: "thermometer"
        ))

        items.append(WeatherGridItem(
            title: "Humidity",
            value: "\(String(format: "%.0f", humidity * 100))%",
            icon: "humidity"
        ))

        items.append(WeatherGridItem(
            title: "Wind",
            value: "\(String(format: "%.0f", wind.speed.converted(to: .milesPerHour).value)) mph",
            icon: "wind"
        ))

        items.append(WeatherGridItem(
            title: "Direction",
            value: wind.compassDirection.abbreviation,
            icon: "location.north.circle"
        ))

        items.append(WeatherGridItem(
            title: "Clouds",
            value: "\(String(format: "%.0f", cloudCover * 100))%",
            icon: "cloud"
        ))

        items.append(WeatherGridItem(
            title: "UV Index",
            value: "\(uvIndex.value)",
            icon: "sun.max"
        ))

        items.append(WeatherGridItem(
            title: "Visibility",
            value: String(format: "%.1f mi", visibility.converted(to: .miles).value),
            icon: "eye"
        ))

        items.append(WeatherGridItem(
            title: "Pressure",
            value: "\(String(format: "%.0f", pressure.converted(to: .millibars).value)) mb",
            icon: "gauge"
        ))

        if let gust = wind.gust {
            items.append(WeatherGridItem(
                title: "Gusts",
                value: "\(String(format: "%.0f", gust.converted(to: .milesPerHour).value)) mph",
                icon: "wind"
            ))
        }

        return items
    }

    var body: some View {
        let columns = [
            GridItem(.flexible(), spacing: 4),
            GridItem(.flexible(), spacing: 4),
            GridItem(.flexible(), spacing: 4),
            GridItem(.flexible(), spacing: 4)
        ]

        LazyVGrid(columns: columns, spacing: 6) {
            ForEach(gridItems) { item in
                VStack(spacing: 2) {
                    if let icon = item.icon {
                        Image(systemName: icon)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    Text(item.title)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)

                    Text(item.value)
                        .font(.caption)
                        .bold()
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
                .padding(.horizontal, 2)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(6)
            }
        }
        .padding(.horizontal, 4)
        .padding(.top, 4)
    }
}

// MARK: - Combined Preview - Row + Grid
#Preview("Adaptive Row + Grid") {
    CombinedPreviewHelper(
        city: "San Francisco",
        state: "CA",
        latitude: 37.7749,
        longitude: -122.4194
    )
}
