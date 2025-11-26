//
//  AppleWeatherRowViewPreviews.swift
//  simpleWeather
//
//  Created by William Castellano on 2/19/25.
//

import SwiftUI
import WeatherKit

/*
// MARK: - Multiple Scenarios Preview
#Preview("Apple Weather Row - Multiple Locations") {
    List {
        AppleWeatherRowPreviewHelper(
            city: "San Francisco",
            state: "CA",
            latitude: 37.7749,
            longitude: -122.4194
        )

        AppleWeatherRowPreviewHelper(
            city: "New York",
            state: "NY",
            latitude: 40.7128,
            longitude: -74.0060
        )

        AppleWeatherRowPreviewHelper(
            city: "Miami",
            state: "FL",
            latitude: 25.7617,
            longitude: -80.1918
        )

        AppleWeatherRowPreviewHelper(
            city: "Seattle",
            state: "WA",
            latitude: 47.6062,
            longitude: -122.3321
        )
    }
}

// MARK: - Single Location Preview
#Preview("Apple Weather Row - Single") {
    List {
        AppleWeatherRowPreviewHelper(
            city: "Chicago",
            state: "IL",
            latitude: 41.8781,
            longitude: -87.6298
        )
    }
}

// MARK: - Loading State Preview
#Preview("Apple Weather Row - Loading") {
    List {
        HStack {
            VStack(alignment: .leading) {
                Text("San Francisco")
                    .font(.headline)
                Text("Loading...")
                    .font(.caption)
            }
            Spacer()
            ProgressView()
        }
    }
}

// MARK: - Different Weather Conditions Preview
#Preview("Apple Weather Row - Various Conditions") {
    ScrollView {
        VStack(spacing: 20) {
            Text("Various Weather Conditions")
                .font(.title2)
                .bold()
                .padding(.top)

            // Sunny/Clear
            AppleWeatherRowPreviewHelper(
                city: "Phoenix",
                state: "AZ",
                latitude: 33.4484,
                longitude: -112.0740
            )

            // Rainy
            AppleWeatherRowPreviewHelper(
                city: "Portland",
                state: "OR",
                latitude: 45.5152,
                longitude: -122.6784
            )

            // Cold
            AppleWeatherRowPreviewHelper(
                city: "Anchorage",
                state: "AK",
                latitude: 61.2181,
                longitude: -149.9003
            )
        }
        .padding()
    }
}

// MARK: - Preview Helper
private struct AppleWeatherRowPreviewHelper: View {
    let city: String
    let state: String
    let latitude: Double
    let longitude: Double

    @State private var weather: Weather?
    @State private var isLoading = true

    var body: some View {
        Group {
            if isLoading {
                HStack {
                    VStack(alignment: .leading) {
                        Text(city)
                            .font(.headline)
                        Text("Loading...")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    ProgressView()
                }
                .padding(.vertical, 8)
            } else if let weather = weather {
                AppleWeatherRowView(
                    weather: weather,
                    location: WeatherLocation(
                        city: city,
                        state: state,
                        latitude: latitude,
                        longitude: longitude
                    )
                )
            } else {
                HStack {
                    VStack(alignment: .leading) {
                        Text(city)
                            .font(.headline)
                        Text("Failed to load")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                    Spacer()
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundStyle(.red)
                }
                .padding(.vertical, 8)
            }
        }
        .task {
            await loadWeather()
        }
    }

    private func loadWeather() async {
        do {
            weather = try await WeatherKitManager.shared.fetchWeather(
                latitude: latitude,
                longitude: longitude
            )
            isLoading = false
        } catch {
            print("Preview error for \(city): \(error)")
            isLoading = false
        }
    }
}
*/
