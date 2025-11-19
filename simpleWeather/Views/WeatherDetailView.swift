//
//  WeatherDetailView.swift
//  simpleWeather
//
//  Created by William Castellano on 2/7/25.
//

import SwiftUI
import WeatherKit

struct WeatherDetailView: View {
    let weather: Weather
    let location: WeatherLocation

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Current Weather Section
                VStack(alignment: .leading, spacing: 8) {
                    Text(location.city ?? "Unknown Location")
                        .font(.title)
                        .bold()

                    HStack {
                        Image(systemName: weather.currentWeather.symbolName)
                            .font(.system(size: 60))
                            .symbolRenderingMode(.multicolor)

                        VStack(alignment: .leading) {
                            Text("\(Int(weather.currentWeather.temperature.converted(to: .fahrenheit).value))°F")
                                .font(.system(size: 48, weight: .bold))

                            Text(weather.currentWeather.condition.description)
                                .font(.title3)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()
                    }
                    .padding(.vertical)
                }
                .padding(.horizontal)

                Divider()

                // Hourly Forecast Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Hourly Forecast")
                        .font(.headline)
                        .padding(.horizontal)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(Array(weather.hourlyForecast), id: \.date) { hourWeather in
                                HourlyForecastCard(hourWeather: hourWeather)
                            }
                        }
                        .padding(.horizontal)
                    }
                }

                Divider()

                // Current Conditions Details
                VStack(alignment: .leading, spacing: 12) {
                    Text("Current Conditions")
                        .font(.headline)
                        .padding(.horizontal)

                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        WeatherMetricCard(
                            title: "Feels Like",
                            value: "\(Int(weather.currentWeather.apparentTemperature.converted(to: .fahrenheit).value))°F",
                            icon: "thermometer"
                        )

                        WeatherMetricCard(
                            title: "Humidity",
                            value: "\(Int(weather.currentWeather.humidity * 100))%",
                            icon: "humidity"
                        )

                        WeatherMetricCard(
                            title: "Wind",
                            value: "\(Int(weather.currentWeather.wind.speed.converted(to: .milesPerHour).value)) mph",
                            icon: "wind"
                        )

                        WeatherMetricCard(
                            title: "UV Index",
                            value: "\(weather.currentWeather.uvIndex.value)",
                            icon: "sun.max"
                        )

                        WeatherMetricCard(
                            title: "Visibility",
                            value: String(format: "%.1f mi", weather.currentWeather.visibility.converted(to: .miles).value),
                            icon: "eye"
                        )

                        WeatherMetricCard(
                            title: "Pressure",
                            value: String(format: "%.2f inHg", weather.currentWeather.pressure.converted(to: .inchesOfMercury).value),
                            icon: "gauge"
                        )
                    }
                    .padding(.horizontal)
                }

                Divider()

                // Daily Forecast Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("10-Day Forecast")
                        .font(.headline)
                        .padding(.horizontal)

                    ForEach(Array(weather.dailyForecast.prefix(10)), id: \.date) { dailyWeather in
                        DailyForecastRow(dailyWeather: dailyWeather)
                            .padding(.horizontal)
                    }
                }

                Spacer(minLength: 20)
            }
            .padding(.vertical)
        }
        .onAppear() {
            print(weather.currentWeather.cloudCoverByAltitude.high.description)
            print(weather.currentWeather.cloudCoverByAltitude.medium.description)
            print(weather.currentWeather.cloudCoverByAltitude.low.description)
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Hourly Forecast Card
struct HourlyForecastCard: View {
    let hourWeather: HourWeather

    private var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "ha"
        return formatter.string(from: hourWeather.date)
    }

    var body: some View {
        VStack(spacing: 8) {
            Text(timeString)
                .font(.caption)
                .foregroundStyle(.secondary)

            Image(systemName: hourWeather.symbolName)
                .font(.title2)
                .symbolRenderingMode(.multicolor)

            Text("\(Int(hourWeather.temperature.converted(to: .fahrenheit).value))°")
                .font(.body)
                .bold()

            if hourWeather.precipitationChance > 0 {
                HStack(spacing: 2) {
                    Image(systemName: "drop.fill")
                        .font(.caption2)
                        .foregroundStyle(.blue)
                    Text("\(Int(hourWeather.precipitationChance * 100))%")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(width: 60)
        .padding(.vertical, 8)
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Weather Metric Card
struct WeatherMetricCard: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(.secondary)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(value)
                .font(.title3)
                .bold()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Daily Forecast Row
struct DailyForecastRow: View {
    let dailyWeather: DayWeather

    private var dayString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: dailyWeather.date)
    }

    var body: some View {
        HStack {
            Text(dayString)
                .font(.body)
                .frame(width: 100, alignment: .leading)

            Image(systemName: dailyWeather.symbolName)
                .font(.title3)
                .symbolRenderingMode(.multicolor)
                .frame(width: 40)

            if dailyWeather.precipitationChance > 0 {
                HStack(spacing: 2) {
                    Image(systemName: "drop.fill")
                        .font(.caption)
                        .foregroundStyle(.blue)
                    Text("\(Int(dailyWeather.precipitationChance * 100))%")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(width: 50)
            } else {
                Spacer()
                    .frame(width: 50)
            }

            Spacer()

            HStack(spacing: 8) {
                Text("\(Int(dailyWeather.lowTemperature.converted(to: .fahrenheit).value))°")
                    .foregroundStyle(.secondary)

                Text("\(Int(dailyWeather.highTemperature.converted(to: .fahrenheit).value))°")
                    .bold()
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Previews

// Preview helper to load weather data
struct WeatherPreviewWrapper: View {
    @State private var weather: Weather?
    @State private var isLoading = true

    let location: WeatherLocation

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading weather data...")
            } else if let weather = weather {
                WeatherDetailView(weather: weather, location: location)
            } else {
                Text("Failed to load weather data")
                    .foregroundStyle(.secondary)
            }
        }
        .task {
            await loadWeather()
        }
    }

    private func loadWeather() async {
        do {
            weather = try await WeatherKitManager.shared.fetchWeather(
                latitude: location.latitude ?? 0.0,
                longitude: location.longitude ?? 0.0
            )
            isLoading = false
        } catch {
            print("Preview error: \(error)")
            isLoading = false
        }
    }
}

#Preview("Weather Detail View") {
    NavigationStack {
        WeatherPreviewWrapper(
            location: WeatherLocation(
                city: "San Francisco",
                state: "CA",
                latitude: 37.7749,
                longitude: -122.4194
            )
        )
    }
}

#Preview("Hourly Forecast Card") {
    HourlyForecastCardPreview()
}

#Preview("Weather Metric Card") {
    WeatherMetricCard(
        title: "Humidity",
        value: "65%",
        icon: "humidity"
    )
    .padding()
    .frame(width: 200)
}

#Preview("Daily Forecast Row") {
    DailyForecastRowPreview()
}

// MARK: - Component Preview Helpers
private struct HourlyForecastCardPreview: View {
    @State private var weather: Weather?

    var body: some View {
        Group {
            if let hourWeather = weather?.hourlyForecast.first {
                HourlyForecastCard(hourWeather: hourWeather)
                    .padding()
            } else {
                ProgressView()
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

private struct DailyForecastRowPreview: View {
    @State private var weather: Weather?

    var body: some View {
        Group {
            if let dailyWeather = weather?.dailyForecast.first {
                DailyForecastRow(dailyWeather: dailyWeather)
                    .padding()
            } else {
                ProgressView()
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
