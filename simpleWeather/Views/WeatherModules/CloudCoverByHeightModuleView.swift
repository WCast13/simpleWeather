//
//  CloudCoverByHeightModuleView.swift
//  simpleWeather
//
//  Created by William Castellano on 2/19/25.
//

import SwiftUI
import WeatherKit

struct CloudCoverByHeightModuleView: View {
    let cloudCover: Double // 0.0 to 1.0
    let size: CGFloat

    init(cloudCover: Double, size: CGFloat = 100) {
        self.cloudCover = cloudCover
        self.size = size
    }

    var cloudCoverPercentage: Int {
        Int(cloudCover * 100)
    }

    var cloudCategory: String {
        switch cloudCoverPercentage {
        case 0...10: return "Clear"
        case 11...25: return "Mostly Clear"
        case 26...50: return "Partly Cloudy"
        case 51...75: return "Mostly Cloudy"
        case 76...90: return "Cloudy"
        default: return "Overcast"
        }
    }

    var cloudColor: Color {
        switch cloudCoverPercentage {
        case 0...25: return .blue
        case 26...50: return .cyan
        case 51...75: return .gray
        default: return .secondary
        }
    }

    // Simulate cloud distribution across heights
    var highCloudCover: Double {
        // High clouds appear first with light coverage
        min(cloudCover * 1.5, 1.0)
    }

    var midCloudCover: Double {
        // Mid clouds appear with moderate coverage
        max(0, min((cloudCover - 0.2) * 1.4, 1.0))
    }

    var lowCloudCover: Double {
        // Low clouds appear with heavy coverage
        max(0, min((cloudCover - 0.5) * 1.8, 1.0))
    }

    var body: some View {
        ZStack {
            VStack(spacing: 8) {
                // Cloud layer visualization
                CloudLayerVisualization(
                    highClouds: highCloudCover,
                    midClouds: midCloudCover,
                    lowClouds: lowCloudCover,
                    size: size,
                    color: cloudColor
                )

                // Cloud cover percentage
                Text("\(cloudCoverPercentage)%")
                    .font(.system(size: size * 0.22, weight: .bold))

                // Category
                Text(cloudCategory)
                    .font(.system(size: size * 0.12, weight: .medium))
                    .foregroundStyle(cloudColor)

                // Cloud layer legend
                HStack(spacing: size * 0.08) {
                    CloudLegendItem(label: "Low", opacity: lowCloudCover, size: size)
                    CloudLegendItem(label: "Mid", opacity: midCloudCover, size: size)
                    CloudLegendItem(label: "High", opacity: highCloudCover, size: size)
                }
                .font(.system(size: size * 0.08))
                .foregroundStyle(.secondary)
            }
        }
        .frame(width: size * 1.3, height: size * 1.5)
    }
}

// MARK: - Cloud Layer Visualization
struct CloudLayerVisualization: View {
    let highClouds: Double
    let midClouds: Double
    let lowClouds: Double
    let size: CGFloat
    let color: Color

    var body: some View {
        ZStack {
            // Sky background
            RoundedRectangle(cornerRadius: size * 0.1)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            .blue.opacity(0.3),
                            .cyan.opacity(0.2),
                            .blue.opacity(0.1)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: size, height: size * 1.1)

            VStack(spacing: 0) {
                // High clouds (cirrus-like)
                CloudLayer(
                    coverage: highClouds,
                    size: size,
                    cloudType: .high,
                    color: color
                )
                .frame(height: size * 0.3)

                // Mid clouds (alto-like)
                CloudLayer(
                    coverage: midClouds,
                    size: size,
                    cloudType: .mid,
                    color: color
                )
                .frame(height: size * 0.35)

                // Low clouds (stratus/cumulus-like)
                CloudLayer(
                    coverage: lowClouds,
                    size: size,
                    cloudType: .low,
                    color: color
                )
                .frame(height: size * 0.35)
            }
            .frame(width: size, height: size * 1.0)
            .clipShape(RoundedRectangle(cornerRadius: size * 0.1))

            // Height markers
            VStack(alignment: .leading, spacing: 0) {
                HeightMarker(label: "25k ft", size: size)
                    .frame(height: size * 0.3)
                HeightMarker(label: "10k ft", size: size)
                    .frame(height: size * 0.35)
                HeightMarker(label: "2k ft", size: size)
                    .frame(height: size * 0.35)
            }
            .frame(width: size, height: size * 1.0, alignment: .leading)
        }
    }
}

// MARK: - Cloud Layer
struct CloudLayer: View {
    let coverage: Double
    let size: CGFloat
    let cloudType: CloudType
    let color: Color

    enum CloudType {
        case high, mid, low

        var opacity: Double {
            switch self {
            case .high: return 0.3
            case .mid: return 0.5
            case .low: return 0.7
            }
        }

        var cloudSize: CGFloat {
            switch self {
            case .high: return 0.15
            case .mid: return 0.22
            case .low: return 0.30
            }
        }
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Generate cloud shapes based on coverage
                ForEach(0..<Int(coverage * 8), id: \.self) { index in
                    CloudShape()
                        .fill(
                            Color.white.opacity(cloudType.opacity * coverage)
                        )
                        .frame(
                            width: size * cloudType.cloudSize * (0.8 + Double(index % 3) * 0.2),
                            height: size * cloudType.cloudSize * 0.6
                        )
                        .offset(
                            x: CGFloat(index % 4) * size * 0.25 - size * 0.4,
                            y: CGFloat(index / 4) * geometry.size.height * 0.4 - geometry.size.height * 0.2
                        )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

// MARK: - Cloud Shape
struct CloudShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        // Create a simple cloud shape using ellipses
        let width = rect.width
        let height = rect.height

        path.addEllipse(in: CGRect(x: width * 0.1, y: height * 0.3, width: width * 0.3, height: height * 0.5))
        path.addEllipse(in: CGRect(x: width * 0.3, y: height * 0.1, width: width * 0.4, height: height * 0.6))
        path.addEllipse(in: CGRect(x: width * 0.5, y: height * 0.2, width: width * 0.35, height: height * 0.55))

        return path
    }
}

// MARK: - Height Marker
struct HeightMarker: View {
    let label: String
    let size: CGFloat

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: size * 0.08))
                .foregroundStyle(.secondary.opacity(0.6))
                .padding(.leading, 4)
            Spacer()
        }
    }
}

// MARK: - Cloud Legend Item
struct CloudLegendItem: View {
    let label: String
    let opacity: Double
    let size: CGFloat

    var body: some View {
        HStack(spacing: 3) {
            Circle()
                .fill(Color.white.opacity(min(opacity * 0.8, 0.8)))
                .overlay(
                    Circle()
                        .stroke(Color.secondary.opacity(0.3), lineWidth: 0.5)
                )
                .frame(width: size * 0.08, height: size * 0.08)
            Text(label)
        }
    }
}

// MARK: - Previews
#Preview("Cloud Cover Module - Various Coverages") {
    ScrollView {
        VStack(spacing: 30) {
            CloudCoverModulePreview()
            CloudCoverModulePreviewTwo()
        }
        .padding()
    }
}

#Preview("Cloud Cover Module - Different Sizes") {
    VStack(spacing: 20) {
        Text("Size Variations")
            .font(.title2)
            .bold()

        HStack(spacing: 20) {
            CloudCoverModulePreview(size: 150)
            CloudCoverModulePreview(size: 200)
            CloudCoverModulePreview(size: 250)
        }
    }
    .padding()
}

#Preview("Cloud Cover Module - All Categories") {
    ScrollView {
        VStack(spacing: 20) {
            Text("Cloud Cover Categories")
                .font(.title2)
                .bold()

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 200))], spacing: 20) {
                ForEach([0.0, 0.2, 0.4, 0.6, 0.8, 1.0], id: \.self) { coverage in
                    CloudCoverByHeightModuleView(cloudCover: coverage, size: 160)
                }
            }
        }
        .padding()
    }
}

// MARK: - Preview Helpers
private struct CloudCoverModulePreview: View {
    @State private var weather: Weather?
    let size: CGFloat

    init(size: CGFloat = 200) {
        self.size = size
    }

    var body: some View {
        Group {
            if let weather = weather {
                VStack(spacing: 20) {
                    CloudCoverByHeightModuleView(
                        cloudCover: weather.currentWeather.cloudCover,
                        size: size
                    )
                }
            } else {
                ProgressView("Loading cloud cover data...")
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

private struct CloudCoverModulePreviewTwo: View {
    @State private var weather: Weather?
    let size: CGFloat

    init(size: CGFloat = 200) {
        self.size = size
    }

    var body: some View {
        Group {
            if let weather = weather {
                VStack(spacing: 20) {
                    CloudCoverByHeightModuleView(
                        cloudCover: weather.currentWeather.cloudCover,
                        size: size
                    )
                }
            } else {
                ProgressView("Loading cloud cover data...")
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
