//
//  DetailsScrollView.swift
//  simpleWeather
//
//  Created by William Castellano on 2/11/25.
//

import SwiftUI
import WeatherKit

// MARK: - Weather Data Grid Item Model
struct WeatherGridItem: Identifiable {
    let id = UUID()
    let title: String
    let value: String
    let icon: String?

    init(title: String, value: String, icon: String? = nil) {
        self.title = title
        self.value = value
        self.icon = icon
    }
}

struct StandaredRowDetailsView: View {
    var weather: Weather

    // Dynamically build grid items from available weather data
    private var gridItems: [WeatherGridItem] {
        var items: [WeatherGridItem] = []

        let current = weather.currentWeather

        // Always available items
        items.append(WeatherGridItem(
            title: "Feels Like",
            value: "\(String(format: "%.0f", current.apparentTemperature.converted(to: .fahrenheit).value))°",
            icon: "thermometer"
        ))

        items.append(WeatherGridItem(
            title: "Humidity",
            value: "\(String(format: "%.0f", current.humidity * 100))%",
            icon: "humidity"
        ))

        items.append(WeatherGridItem(
            title: "Wind",
            value: "\(String(format: "%.0f", current.wind.speed.converted(to: .milesPerHour).value)) mph",
            icon: "wind"
        ))

        items.append(WeatherGridItem(
            title: "Direction",
            value: current.wind.compassDirection.abbreviation,
            icon: "location.north.circle"
        ))

        items.append(WeatherGridItem(
            title: "Clouds",
            value: "\(String(format: "%.0f", current.cloudCover * 100))%",
            icon: "cloud"
        ))

        items.append(WeatherGridItem(
            title: "UV Index",
            value: "\(current.uvIndex.value)",
            icon: "sun.max"
        ))

        items.append(WeatherGridItem(
            title: "Visibility",
            value: String(format: "%.1f mi", current.visibility.converted(to: .miles).value),
            icon: "eye"
        ))

        items.append(WeatherGridItem(
            title: "Pressure",
            value: String(format: "%.2f", current.pressure.converted(to: .inchesOfMercury).value),
            icon: "gauge"
        ))

        // Optional: Add wind gust if available
        if let gust = current.wind.gust {
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

// MARK: - Preview
#Preview {
    StandaredRowDetailsViewPreview()
}

private struct StandaredRowDetailsViewPreview: View {
    @State private var weather: Weather?

    var body: some View {
        Group {
            if let weather = weather {
                StandaredRowDetailsView(weather: weather)
                    .padding()
            } else {
                ProgressView("Loading weather data...")
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
