//
//  StandaredRowDetailsViewPreviews.swift
//  simpleWeather
//
//  Created by William Castellano on 2/19/25.
//

import SwiftUI
import WeatherKit

/*
// MARK: - Standard Grid Preview
#Preview("Weather Grid - Standard") {
    StandaredRowDetailsPreviewHelper(
        city: "San Francisco",
        latitude: 37.7749,
        longitude: -122.4194
    )
    .padding()
}

// MARK: - Multiple Grids Preview
#Preview("Weather Grid - Multiple Cities") {
    ScrollView {
        VStack(spacing: 20) {
            Text("Weather Grids for Different Cities")
                .font(.title2)
                .bold()
                .padding(.top)

            VStack(alignment: .leading, spacing: 12) {
                Text("San Francisco, CA")
                    .font(.headline)
                StandaredRowDetailsPreviewHelper(
                    city: "San Francisco",
                    latitude: 37.7749,
                    longitude: -122.4194
                )
            }

            Divider()

            VStack(alignment: .leading, spacing: 12) {
                Text("New York, NY")
                    .font(.headline)
                StandaredRowDetailsPreviewHelper(
                    city: "New York",
                    latitude: 40.7128,
                    longitude: -74.0060
                )
            }

            Divider()

            VStack(alignment: .leading, spacing: 12) {
                Text("Miami, FL")
                    .font(.headline)
                StandaredRowDetailsPreviewHelper(
                    city: "Miami",
                    latitude: 25.7617,
                    longitude: -80.1918
                )
            }

            Divider()

            VStack(alignment: .leading, spacing: 12) {
                Text("Chicago, IL")
                    .font(.headline)
                StandaredRowDetailsPreviewHelper(
                    city: "Chicago",
                    latitude: 41.8781,
                    longitude: -87.6298
                )
            }
        }
        .padding()
    }
}

// MARK: - In List Context Preview
#Preview("Weather Grid - In List") {
    List {
        Section("San Francisco") {
            StandaredRowDetailsPreviewHelper(
                city: "San Francisco",
                latitude: 37.7749,
                longitude: -122.4194
            )
        }

        Section("Seattle") {
            StandaredRowDetailsPreviewHelper(
                city: "Seattle",
                latitude: 47.6062,
                longitude: -122.3321
            )
        }

        Section("Denver") {
            StandaredRowDetailsPreviewHelper(
                city: "Denver",
                latitude: 39.7392,
                longitude: -104.9903
            )
        }
    }
}

// MARK: - Extreme Weather Conditions Preview
#Preview("Weather Grid - Extreme Conditions") {
    ScrollView {
        VStack(spacing: 20) {
            Text("Extreme Weather Conditions")
                .font(.title2)
                .bold()
                .padding(.top)

            // Very hot
            VStack(alignment: .leading, spacing: 12) {
                Text("Phoenix, AZ (Hot)")
                    .font(.headline)
                StandaredRowDetailsPreviewHelper(
                    city: "Phoenix",
                    latitude: 33.4484,
                    longitude: -112.0740
                )
            }

            Divider()

            // Very cold
            VStack(alignment: .leading, spacing: 12) {
                Text("Anchorage, AK (Cold)")
                    .font(.headline)
                StandaredRowDetailsPreviewHelper(
                    city: "Anchorage",
                    latitude: 61.2181,
                    longitude: -149.9003
                )
            }

            Divider()

            // Humid/Tropical
            VStack(alignment: .leading, spacing: 12) {
                Text("Honolulu, HI (Tropical)")
                    .font(.headline)
                StandaredRowDetailsPreviewHelper(
                    city: "Honolulu",
                    latitude: 21.3099,
                    longitude: -157.8581
                )
            }
        }
        .padding()
    }
}

// MARK: - Loading State Preview
#Preview("Weather Grid - Loading") {
    VStack(spacing: 12) {
        Text("Loading Weather Grid")
            .font(.headline)
        ProgressView()
            .padding()
    }
}

// MARK: - Preview Helper
private struct StandaredRowDetailsPreviewHelper: View {
    let city: String
    let latitude: Double
    let longitude: Double

    @State private var weather: Weather?
    @State private var isLoading = true

    var body: some View {
        Group {
            if isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .padding()
            } else if let weather = weather {
                StandaredRowDetailsView(weather: weather)
            } else {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundStyle(.red)
                        Text("Failed to load data")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding()
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
