//
//  HumidityModuleView.swift
//  simpleWeather
//
//  Created by William Castellano on 2/19/25.
//

import SwiftUI
import WeatherKit

struct HumidityModuleView: View {
    let humidity: Double // 0.0 to 1.0
    let size: CGFloat

    init(humidity: Double, size: CGFloat = 100) {
        self.humidity = humidity
        self.size = size
    }

    var humidityPercentage: Int {
        Int(humidity * 100)
    }

    var humidityLevel: String {
        switch humidityPercentage {
        case 0..<30: return "Low"
        case 30..<60: return "Moderate"
        case 60..<80: return "High"
        default: return "Very High"
        }
    }

    var humidityColor: Color {
        switch humidityPercentage {
        case 0..<30: return .orange
        case 30..<60: return .green
        case 60..<80: return .blue
        default: return .indigo
        }
    }

    var body: some View {
        ZStack {
            VStack(spacing: 8) {
                // Humidity gauge
                HumidityGauge(percentage: humidity, size: size, color: humidityColor)

                // Percentage text
                Text("\(humidityPercentage)%")
                    .font(.system(size: size * 0.22, weight: .bold))

                // Level indicator
                Text(humidityLevel)
                    .font(.system(size: size * 0.12))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: size * 1.2, height: size * 1.2)
    }
}

// MARK: - Humidity Gauge
struct HumidityGauge: View {
    let percentage: Double
    let size: CGFloat
    let color: Color

    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(Color.secondary.opacity(0.2), lineWidth: size * 0.08)
                .frame(width: size, height: size)

            // Progress arc
            Circle()
                .trim(from: 0, to: percentage)
                .stroke(
                    color.gradient,
                    style: StrokeStyle(
                        lineWidth: size * 0.08,
                        lineCap: .round
                    )
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: percentage)

            // Water droplet icon
            Image(systemName: "drop.fill")
                .resizable()
                .scaledToFit()
                .frame(width: size * 0.3, height: size * 0.3)
                .foregroundStyle(color.opacity(0.6))
        }
    }
}

// MARK: - Previews
#Preview("Humidity Module - Various Levels") {
    ScrollView {
        VStack(spacing: 30) {
            HumidityModulePreview()
            HumidityModulePreviewTwo()
        }
        .padding()
    }
}

#Preview("Humidity Module - Different Sizes") {
    VStack(spacing: 20) {
        Text("Size Variations")
            .font(.title2)
            .bold()

        HStack(spacing: 20) {
            HumidityModulePreview(size: 150)
            HumidityModulePreview(size: 200)
            HumidityModulePreview(size: 250)
        }
    }
    .padding()
}

// MARK: - Preview Helpers
private struct HumidityModulePreview: View {
    @State private var weather: Weather?
    let size: CGFloat

    init(size: CGFloat = 200) {
        self.size = size
    }

    var body: some View {
        Group {
            if let weather = weather {
                VStack(spacing: 20) {
                    HumidityModuleView(
                        humidity: weather.currentWeather.humidity,
                        size: size
                    )
                }
            } else {
                ProgressView("Loading humidity data...")
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

private struct HumidityModulePreviewTwo: View {
    @State private var weather: Weather?
    let size: CGFloat

    init(size: CGFloat = 200) {
        self.size = size
    }

    var body: some View {
        Group {
            if let weather = weather {
                VStack(spacing: 20) {
                    HumidityModuleView(
                        humidity: weather.currentWeather.humidity,
                        size: size
                    )
                }
            } else {
                ProgressView("Loading humidity data...")
            }
        }
        .task {
            do {
                weather = try await WeatherKitManager.shared.fetchWeather(
                    latitude: 41.891849,
                    longitude: -87.599495
                )
            } catch {
                print("Preview error: \(error)")
            }
        }
    }
}
