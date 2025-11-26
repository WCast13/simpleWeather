//
//  WindModuleView.swift
//  simpleWeather
//
//  Created by William Castellano on 2/19/25.
//

import SwiftUI
import WeatherKit

struct WindModuleView: View {
    let wind: Wind
    let size: CGFloat

    init(wind: Wind, size: CGFloat = 100) {
        self.wind = wind
        self.size = size
    }

    var body: some View {
        
        ZStack() {
            VStack {
                CompassBackground(size: size, wind: wind)
                    .padding(.bottom)
                Text("\(Int(wind.speed.converted(to: .milesPerHour).value)) mph")
                    .padding(.top)
            }
        }
        .frame(width: size * 1.2, height: size * 1.2)
    }
}

// MARK: - Compass Background
struct CompassBackground: View {
    let size: CGFloat
    let wind: Wind

    var body: some View {
        ZStack {
            // Outer circle
//            Circle()
//                .stroke(Color.secondary.opacity(0.3), lineWidth: 2)

            // Inner circle
            Circle()
                .stroke(Color.secondary.opacity(0.5), lineWidth: 1)
                .frame(width: size * 0.7, height: size * 0.7)

            // Cardinal direction markers
            ForEach(0..<1) { index in
                CardinalMarker(
                    direction: CardinalDirection.allCases[index],
                    size: size
                )
            }

            // Degree markers (every 30 degrees)
            ForEach(1..<12) { index in
                DegreeMarker(
                    angle: Double(index) * 30,
                    size: size,
                    isCardinal: index % 3 == 0
                )
                
                WindArrow(direction: wind.direction.value, size: size)
                    .opacity(0.75)
            }
        }
    }
}

// MARK: - Cardinal Direction Marker
struct CardinalMarker: View {
    let direction: CardinalDirection
    let size: CGFloat

    var body: some View {
        Text(direction.rawValue)
            .font(.system(size: size * 0.12, weight: .bold))
            .foregroundStyle(.secondary)
            .offset(y: -size * 0.42)
            .rotationEffect(.degrees(direction.angle))
//            .rotationEffect(.degrees(-direction.angle))
    }
}

enum CardinalDirection: String, CaseIterable {
    case north = "N"
    case east = "E"
    case south = "S"
    case west = "W"

    var angle: Double {
        switch self {
        case .north: return 0
        case .east: return 90
        case .south: return 180
        case .west: return 270
        }
    }
}

// MARK: - Degree Marker
struct DegreeMarker: View {
    let angle: Double
    let size: CGFloat
    let isCardinal: Bool

    var body: some View {
        Rectangle()
            .fill(Color.secondary.opacity(isCardinal ? 0.8 : 0.5))
            .frame(
                width: isCardinal ? 2 : 1.5,
                height: isCardinal ? size * 0.08 : size * 0.04
            )
            .offset(y: -size * 0.46)
            .rotationEffect(.degrees(angle))
    }
}

// MARK: - Wind Arrow
struct WindArrow: View {
    let direction: Double // in degrees
    let size: CGFloat

    var body: some View {
        
        Image(systemName: "location.north")
              .resizable()
              .scaledToFit()
              .frame(width: size / 2, height: size / 2)
              .fontWeight(.ultraLight)
              .rotationEffect(.degrees(direction))
    }
}

// MARK: - Wind Speed Overlay
struct WindSpeedOverlay: View {
    let speed: Double
    let compassDirection: String
    let size: CGFloat

    var body: some View {
        
        Text("\(Int(speed)) mph")
            .font(.headline)
            .bold()
            .frame(width: 100, height: 100)
    }
}

// MARK: - Preview
#Preview("Wind Module - Various Directions") {
    ScrollView {
        VStack(spacing: 30) {
            WindModulePreview()
            WindModulePreviewTwo()
        }
        .padding()
    }
}

#Preview("Wind Module - Different Sizes") {
    VStack(spacing: 20) {
        Text("Size Variations")
            .font(.title2)
            .bold()

        HStack(spacing: 20) {
            WindModulePreview(size: 150)
            WindModulePreview(size: 200)
            WindModulePreview(size: 250)
        }
    }
    .padding()
}

// MARK: - Preview Helper
private struct WindModulePreview: View {
    @State private var weather: Weather?
    let size: CGFloat

    init(size: CGFloat = 200) {
        self.size = size
    }

    var body: some View {
        Group {
            if let weather = weather {
                VStack(spacing: 20) {
                    // Real wind data
                    VStack {
                        WindModuleView(wind: weather.currentWeather.wind, size: size)
                    }
                }
            } else {
                ProgressView("Loading wind data...")
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

private struct WindModulePreviewTwo: View {
    @State private var weather: Weather?
    let size: CGFloat

    init(size: CGFloat = 200) {
        self.size = size
    }

    var body: some View {
        Group {
            if let weather = weather {
                VStack(spacing: 20) {
                    // Real wind data
                    VStack {
                        WindModuleView(wind: weather.currentWeather.wind, size: size)
                    }
                }
            } else {
                ProgressView("Loading wind data...")
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
