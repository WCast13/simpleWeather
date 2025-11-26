//
//  UVIndexModuleView.swift
//  simpleWeather
//
//  Created by William Castellano on 2/19/25.
//

import SwiftUI
import WeatherKit

struct UVIndexModuleView: View {
    let uvIndex: Int
    let size: CGFloat

    init(uvIndex: Int, size: CGFloat = 100) {
        self.uvIndex = uvIndex
        self.size = size
    }

    var uvCategory: String {
        switch uvIndex {
        case 0...2: return "Low"
        case 3...5: return "Moderate"
        case 6...7: return "High"
        case 8...10: return "Very High"
        default: return "Extreme"
        }
    }

    var uvColor: Color {
        switch uvIndex {
        case 0...2: return .green
        case 3...5: return .yellow
        case 6...7: return .orange
        case 8...10: return .red
        default: return .purple
        }
    }

    var protectionAdvice: String {
        switch uvIndex {
        case 0...2: return "No protection needed"
        case 3...5: return "Wear sunscreen"
        case 6...7: return "Seek shade midday"
        case 8...10: return "Extra protection required"
        default: return "Avoid sun exposure"
        }
    }

    var body: some View {
        ZStack {
            VStack(spacing: 8) {
                // UV Index visualization
                UVIndexGauge(uvIndex: uvIndex, size: size, color: uvColor)

                // UV Index value
                Text("\(uvIndex)")
                    .font(.system(size: size * 0.28, weight: .bold))

                // Category
                Text(uvCategory)
                    .font(.system(size: size * 0.14, weight: .semibold))
                    .foregroundStyle(uvColor)

                // Protection advice
                Text(protectionAdvice)
                    .font(.system(size: size * 0.09))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(width: size * 1.1)
            }
        }
        .frame(width: size * 1.2, height: size * 1.5)
    }
}

// MARK: - UV Index Gauge
struct UVIndexGauge: View {
    let uvIndex: Int
    let size: CGFloat
    let color: Color

    var normalizedUV: Double {
        // UV Index typically ranges from 0-11+
        min(Double(uvIndex) / 11.0, 1.0)
    }

    var body: some View {
        ZStack {
            // Background gradient scale
            Circle()
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            .green,
                            .yellow,
                            .orange,
                            .red,
                            .purple
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    lineWidth: size * 0.08
                )
                .opacity(0.3)
                .frame(width: size, height: size)

            // Progress ring
            Circle()
                .trim(from: 0, to: normalizedUV)
                .stroke(
                    color.gradient,
                    style: StrokeStyle(
                        lineWidth: size * 0.08,
                        lineCap: .round
                    )
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: normalizedUV)

            // Sun icon
            ZStack {
                // Sun rays
                ForEach(0..<8) { index in
                    Rectangle()
                        .fill(color.opacity(0.4))
                        .frame(width: 2, height: size * 0.15)
                        .offset(y: -size * 0.28)
                        .rotationEffect(.degrees(Double(index) * 45))
                }

                // Sun circle
                Circle()
                    .fill(color.gradient)
                    .frame(width: size * 0.35, height: size * 0.35)
                    .shadow(color: color.opacity(0.3), radius: 8)
            }
        }
    }
}

// MARK: - Previews
#Preview("UV Index Module - Various Levels") {
    ScrollView {
        VStack(spacing: 30) {
            UVIndexModulePreview()
            UVIndexModulePreviewTwo()
        }
        .padding()
    }
}

#Preview("UV Index Module - Different Sizes") {
    VStack(spacing: 20) {
        Text("Size Variations")
            .font(.title2)
            .bold()

        HStack(spacing: 20) {
            UVIndexModulePreview(size: 150)
            UVIndexModulePreview(size: 200)
            UVIndexModulePreview(size: 250)
        }
    }
    .padding()
}

#Preview("UV Index Module - All Categories") {
    ScrollView {
        VStack(spacing: 20) {
            Text("UV Index Categories")
                .font(.title2)
                .bold()

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 180))], spacing: 20) {
                ForEach([0, 2, 4, 6, 8, 11], id: \.self) { index in
                    UVIndexModuleView(uvIndex: index, size: 150)
                }
            }
        }
        .padding()
    }
}

// MARK: - Preview Helpers
private struct UVIndexModulePreview: View {
    @State private var weather: Weather?
    let size: CGFloat

    init(size: CGFloat = 200) {
        self.size = size
    }

    var body: some View {
        Group {
            if let weather = weather {
                VStack(spacing: 20) {
                    UVIndexModuleView(
                        uvIndex: weather.currentWeather.uvIndex.value,
                        size: size
                    )
                }
            } else {
                ProgressView("Loading UV index data...")
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

private struct UVIndexModulePreviewTwo: View {
    @State private var weather: Weather?
    let size: CGFloat

    init(size: CGFloat = 200) {
        self.size = size
    }

    var body: some View {
        Group {
            if let weather = weather {
                VStack(spacing: 20) {
                    UVIndexModuleView(
                        uvIndex: weather.currentWeather.uvIndex.value,
                        size: size
                    )
                }
            } else {
                ProgressView("Loading UV index data...")
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
