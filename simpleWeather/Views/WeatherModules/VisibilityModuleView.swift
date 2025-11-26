//
//  VisibilityModuleView.swift
//  simpleWeather
//
//  Created by William Castellano on 2/19/25.
//

import SwiftUI
import WeatherKit

struct VisibilityModuleView: View {
    let visibility: Measurement<UnitLength>
    let size: CGFloat

    init(visibility: Measurement<UnitLength>, size: CGFloat = 100) {
        self.visibility = visibility
        self.size = size
    }

    var visibilityMiles: Double {
        visibility.converted(to: .miles).value
    }

    var visibilityKilometers: Double {
        visibility.converted(to: .kilometers).value
    }

    var visibilityCategory: String {
        switch visibilityMiles {
        case 0..<1: return "Very Poor"
        case 1..<3: return "Poor"
        case 3..<6: return "Moderate"
        case 6..<10: return "Good"
        default: return "Excellent"
        }
    }

    var visibilityColor: Color {
        switch visibilityMiles {
        case 0..<1: return .red
        case 1..<3: return .orange
        case 3..<6: return .yellow
        case 6..<10: return .green
        default: return .blue
        }
    }

    var displayDistance: String {
        if visibilityMiles >= 10 {
            return "\(Int(visibilityMiles)) mi"
        } else {
            return String(format: "%.1f mi", visibilityMiles)
        }
    }

    var body: some View {
        ZStack {
            VStack(spacing: 8) {
                // Visibility visualization
                VisibilityVisualization(
                    visibilityMiles: visibilityMiles,
                    size: size,
                    color: visibilityColor
                )

                // Distance value
                Text(displayDistance)
                    .font(.system(size: size * 0.20, weight: .bold))

                // Secondary unit
                Text(String(format: "%.1f km", visibilityKilometers))
                    .font(.system(size: size * 0.11))
                    .foregroundStyle(.secondary)

                // Category
                Text(visibilityCategory)
                    .font(.system(size: size * 0.13, weight: .medium))
                    .foregroundStyle(visibilityColor)
            }
        }
        .frame(width: size * 1.2, height: size * 1.4)
    }
}

// MARK: - Visibility Visualization
struct VisibilityVisualization: View {
    let visibilityMiles: Double
    let size: CGFloat
    let color: Color

    var normalizedVisibility: Double {
        // Normalize visibility to 0-1 range (max at 10 miles)
        min(visibilityMiles / 10.0, 1.0)
    }

    var body: some View {
        ZStack {
            // Background layers showing distance
            ForEach(0..<5) { index in
                Circle()
                    .stroke(
                        Color.secondary.opacity(0.1 - Double(index) * 0.02),
                        lineWidth: 1
                    )
                    .frame(
                        width: size * 0.2 + CGFloat(index) * size * 0.16,
                        height: size * 0.2 + CGFloat(index) * size * 0.16
                    )
            }

            // Visibility gradient overlay
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            color.opacity(0.6),
                            color.opacity(0.2),
                            color.opacity(0.05)
                        ]),
                        center: .center,
                        startRadius: 0,
                        endRadius: size * 0.5 * normalizedVisibility
                    )
                )
                .frame(width: size, height: size)
                .animation(.easeInOut(duration: 0.5), value: normalizedVisibility)

            // Eye icon in center
            ZStack {
                Circle()
                    .fill(Color(uiColor: .systemBackground))
                    .frame(width: size * 0.25, height: size * 0.25)

                Image(systemName: "eye.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: size * 0.18, height: size * 0.18)
                    .foregroundStyle(color)
            }

            // Distance markers
            ForEach([0.25, 0.5, 0.75, 1.0], id: \.self) { fraction in
                Circle()
                    .stroke(color.opacity(0.3), lineWidth: 1.5)
                    .frame(
                        width: size * fraction,
                        height: size * fraction
                    )
            }
        }
    }
}

// MARK: - Previews
#Preview("Visibility Module - Various Conditions") {
    ScrollView {
        VStack(spacing: 30) {
            VisibilityModulePreview()
            VisibilityModulePreviewTwo()
        }
        .padding()
    }
}

#Preview("Visibility Module - Different Sizes") {
    VStack(spacing: 20) {
        Text("Size Variations")
            .font(.title2)
            .bold()

        HStack(spacing: 20) {
            VisibilityModulePreview(size: 150)
            VisibilityModulePreview(size: 200)
            VisibilityModulePreview(size: 250)
        }
    }
    .padding()
}

#Preview("Visibility Module - All Categories") {
    ScrollView {
        VStack(spacing: 20) {
            Text("Visibility Categories")
                .font(.title2)
                .bold()

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 180))], spacing: 20) {
                // Simulated visibility values in meters
                ForEach([500, 2000, 5000, 10000, 20000], id: \.self) { meters in
                    VisibilityModuleView(
                        visibility: Measurement(value: Double(meters), unit: .meters),
                        size: 150
                    )
                }
            }
        }
        .padding()
    }
}

// MARK: - Preview Helpers
private struct VisibilityModulePreview: View {
    @State private var weather: Weather?
    let size: CGFloat

    init(size: CGFloat = 200) {
        self.size = size
    }

    var body: some View {
        Group {
            if let weather = weather {
                VStack(spacing: 20) {
                    VisibilityModuleView(
                        visibility: weather.currentWeather.visibility,
                        size: size
                    )
                }
            } else {
                ProgressView("Loading visibility data...")
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

private struct VisibilityModulePreviewTwo: View {
    @State private var weather: Weather?
    let size: CGFloat

    init(size: CGFloat = 200) {
        self.size = size
    }

    var body: some View {
        Group {
            if let weather = weather {
                VStack(spacing: 20) {
                    VisibilityModuleView(
                        visibility: weather.currentWeather.visibility,
                        size: size
                    )
                }
            } else {
                ProgressView("Loading visibility data...")
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
