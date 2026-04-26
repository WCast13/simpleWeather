//
//  AppleWeatherRowView.swift
//  simpleWeather
//
//  Created by William Castellano on 2/10/25.
//

import SwiftUI
import Foundation
import WeatherKit

struct AppleWeatherRowView: View {
    var weather: Weather
    var location: WeatherLocation
    
    var columns = [GridItem(.adaptive(minimum: 40, maximum: .infinity))]
    
    var body: some View {
        
        
        HStack {
            VStack(alignment: .leading) {
                Text(location.city)
                    .font(.headline)
                Text("\(weather.currentWeather.date.formatted(date: .omitted, time: .shortened))")
                    .font(.caption)
            }
            
            Spacer()
            
            Text("\(weather.currentWeather.condition.description)")
                .font(.caption)
            
            Spacer()
            
            VStack(alignment: .center) {
                Text("\(String(format: "%.0f", weather.currentWeather.temperature.converted(to: .fahrenheit).value))°")
                    .font(.largeTitle)
                
                Text("H: \(String(format: "%.0f", weather.dailyForecast.first?.highTemperature.converted(to: .fahrenheit).value ?? 0))° L: \(String(format: "%.0f", weather.dailyForecast.first?.lowTemperature.converted(to: .fahrenheit).value ?? 0))°")
                    .font(.caption)
            }
        }
    }
}

// MARK: - Preview
#Preview {
    AppleWeatherRowViewPreview()
}

private struct AppleWeatherRowViewPreview: View {
    @State private var weather: Weather?

    var body: some View {
        Group {
            if let weather = weather {
                List {
                    AppleWeatherRowView(
                        weather: weather,
                        location: WeatherLocation(
                            city: "San Francisco",
                            state: "CA",
                            latitude: 37.7749,
                            longitude: -122.4194
                        )
                    )
                }
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
