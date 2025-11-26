//
//  PressureTrendModuleView.swift
//  simpleWeather
//
//  Created by William Castellano on 2/19/25.
//

import SwiftUI
import WeatherKit

struct PressureTrendModuleView: View {
    let pressure: Measurement<UnitPressure>
    let pressureTrend: PressureTrend
    let size: CGFloat

    init(pressure: Measurement<UnitPressure>, pressureTrend: PressureTrend, size: CGFloat = 100) {
        self.pressure = pressure
        self.pressureTrend = pressureTrend
        self.size = size
    }

    var pressureInHPa: Int {
        Int(pressure.converted(to: .hectopascals).value)
    }

    var pressureInInHg: String {
        String(format: "%.2f", pressure.converted(to: .inchesOfMercury).value)
    }

    var trendColor: Color {
        switch pressureTrend {
        case .rising: return .green
        case .falling: return .orange
        case .steady: return .blue
        }
    }

    var trendIcon: String {
        switch pressureTrend {
        case .rising: return "arrow.up.right"
        case .falling: return "arrow.down.right"
        case .steady: return "arrow.right"
        }
    }

    var trendText: String {
        switch pressureTrend {
        case .rising: return "Rising"
        case .falling: return "Falling"
        case .steady: return "Steady"
        }
    }

    var body: some View {
        ZStack {
            VStack(spacing: 8) {
                // Pressure gauge
                PressureGauge(
                    pressureHPa: Double(pressureInHPa),
                    size: size,
                    trend: pressureTrend,
                    trendColor: trendColor
                )

                // Pressure value
                VStack(spacing: 2) {
                    Text("\(pressureInHPa) hPa")
                        .font(.system(size: size * 0.16, weight: .bold))
                    Text("\(pressureInInHg) inHg")
                        .font(.system(size: size * 0.10))
                        .foregroundStyle(.secondary)
                }

                // Trend indicator
                HStack(spacing: 4) {
                    Image(systemName: trendIcon)
                        .font(.system(size: size * 0.10))
                    Text(trendText)
                        .font(.system(size: size * 0.12))
                }
                .foregroundStyle(trendColor)
            }
        }
        .frame(width: size * 1.2, height: size * 1.4)
    }
}

// MARK: - Pressure Gauge
struct PressureGauge: View {
    let pressureHPa: Double
    let size: CGFloat
    let trend: PressureTrend
    let trendColor: Color

    // Pressure range: 980-1040 hPa (typical range)
    var normalizedPressure: Double {
        let minPressure = 980.0
        let maxPressure = 1040.0
        return min(max((pressureHPa - minPressure) / (maxPressure - minPressure), 0), 1)
    }

    var body: some View {
        ZStack {
            // Background arc
            Circle()
                .trim(from: 0, to: 0.75)
                .stroke(Color.secondary.opacity(0.2), lineWidth: size * 0.08)
                .frame(width: size, height: size)
                .rotationEffect(.degrees(135))

            // Pressure arc (color-coded)
            Circle()
                .trim(from: 0, to: 0.75 * normalizedPressure)
                .stroke(
                    pressureGradient,
                    style: StrokeStyle(
                        lineWidth: size * 0.08,
                        lineCap: .round
                    )
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(135))
                .animation(.easeInOut(duration: 0.5), value: normalizedPressure)

            // Gauge icon
            Image(systemName: "gauge.with.dots.needle.67percent")
                .resizable()
                .scaledToFit()
                .frame(width: size * 0.4, height: size * 0.4)
                .foregroundStyle(trendColor.opacity(0.6))

            // Range markers
            VStack {
                Text("High")
                    .font(.system(size: size * 0.08))
                    .foregroundStyle(.secondary)
                    .offset(x: size * 0.35, y: -size * 0.15)

                Spacer()

                HStack {
                    Text("Low")
                        .font(.system(size: size * 0.08))
                        .foregroundStyle(.secondary)
                        .offset(x: -size * 0.25, y: size * 0.20)

                    Spacer()

                    Text("High")
                        .font(.system(size: size * 0.08))
                        .foregroundStyle(.secondary)
                        .offset(x: size * 0.25, y: size * 0.20)
                }
            }
            .frame(width: size, height: size)
        }
    }

    var pressureGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [.orange, .green, .blue]),
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}

// MARK: - Previews
#Preview("Pressure Module - Various Trends") {
    ScrollView {
        VStack(spacing: 30) {
            PressureModulePreview()
            PressureModulePreviewTwo()
        }
        .padding()
    }
}

#Preview("Pressure Module - Different Sizes") {
    VStack(spacing: 20) {
        Text("Size Variations")
            .font(.title2)
            .bold()

        HStack(spacing: 20) {
            PressureModulePreview(size: 150)
            PressureModulePreview(size: 200)
            PressureModulePreview(size: 250)
        }
    }
    .padding()
}

// MARK: - Preview Helpers
private struct PressureModulePreview: View {
    @State private var weather: Weather?
    let size: CGFloat

    init(size: CGFloat = 200) {
        self.size = size
    }

    var body: some View {
        Group {
            if let weather = weather {
                VStack(spacing: 20) {
                    PressureTrendModuleView(
                        pressure: weather.currentWeather.pressure,
                        pressureTrend: weather.currentWeather.pressureTrend,
                        size: size
                    )
                }
            } else {
                ProgressView("Loading pressure data...")
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

private struct PressureModulePreviewTwo: View {
    @State private var weather: Weather?
    let size: CGFloat

    init(size: CGFloat = 200) {
        self.size = size
    }

    var body: some View {
        Group {
            if let weather = weather {
                VStack(spacing: 20) {
                    PressureTrendModuleView(
                        pressure: weather.currentWeather.pressure,
                        pressureTrend: weather.currentWeather.pressureTrend,
                        size: size
                    )
                }
            } else {
                ProgressView("Loading pressure data...")
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
