//
//  AdaptiveWeatherRowViewPreviews.swift
//  simpleWeather
//
//  Created by William Castellano on 2/19/25.
//

import SwiftUI
import WeatherKit

/*
 // MARK: - Row View Preview - Single Location
 #Preview("Adaptive Row - Single") {
     List {
         AdaptiveWeatherRowPreviewHelper(
             city: "San Francisco",
             state: "CA",
             latitude: 37.7749,
             longitude: -122.4194
         )
     }
 }

 // MARK: - Row View Preview - Multiple Locations
 #Preview("Adaptive Row - Multiple") {
     List {
         AdaptiveWeatherRowPreviewHelper(
             city: "San Francisco",
             state: "CA",
             latitude: 37.7749,
             longitude: -122.4194
         )

         AdaptiveWeatherRowPreviewHelper(
             city: "New York",
             state: "NY",
             latitude: 40.7128,
             longitude: -74.0060
         )

         AdaptiveWeatherRowPreviewHelper(
             city: "Miami",
             state: "FL",
             latitude: 25.7617,
             longitude: -80.1918
         )

         AdaptiveWeatherRowPreviewHelper(
             city: "Seattle",
             state: "WA",
             latitude: 47.6062,
             longitude: -122.3321
         )
     }
 }

 // MARK: - Row View Preview - With Date
 #Preview("Adaptive Row - With Date") {
     List {
         AdaptiveWeatherRowPreviewHelper(
             city: "Chicago",
             state: "IL",
             latitude: 41.8781,
             longitude: -87.6298,
             showDate: true
         )
     }
 }

 // MARK: - Grid View Preview - Single
 #Preview("Adaptive Grid - Single") {
     AdaptiveWeatherGridPreviewHelper(
         city: "San Francisco",
         state: "CA",
         latitude: 37.7749,
         longitude: -122.4194
     )
     .padding()
 }

 // MARK: - Grid View Preview - With Container
 #Preview("Adaptive Grid - In ScrollView") {
     ScrollView {
         VStack(spacing: 16) {
             Text("Weather Details")
                 .font(.title2)
                 .bold()

             AdaptiveWeatherGridPreviewHelper(
                 city: "San Francisco",
                 state: "CA",
                 latitude: 37.7749,
                 longitude: -122.4194
             )
         }
         .padding()
     }
 }

 // MARK: - Combined Preview - Row + Grid
 #Preview("Adaptive Row + Grid") {
     CombinedPreviewHelper(
         city: "San Francisco",
         state: "CA",
         latitude: 37.7749,
         longitude: -122.4194
     )
 }

 // MARK: - Loading State Preview
 #Preview("Adaptive Row - Loading") {
     List {
         HStack {
             VStack(alignment: .leading, spacing: 4) {
                 Text("San Francisco")
                     .font(.headline)
                 Text("Loading...")
                     .font(.caption2)
                     .foregroundStyle(.secondary)
             }
             Spacer()
             ProgressView()
         }
     }
 }

 // MARK: - Various Weather Conditions
 #Preview("Adaptive Row - Various Conditions") {
     ScrollView {
         VStack(spacing: 0) {
             Text("Various Weather Conditions")
                 .font(.title2)
                 .bold()
                 .padding()

             List {
                 // Sunny/Clear - Phoenix
                 AdaptiveWeatherRowPreviewHelper(
                     city: "Phoenix",
                     state: "AZ",
                     latitude: 33.4484,
                     longitude: -112.0740
                 )

                 // Rainy - Portland
                 AdaptiveWeatherRowPreviewHelper(
                     city: "Portland",
                     state: "OR",
                     latitude: 45.5152,
                     longitude: -122.6784
                 )

                 // Cold - Anchorage
                 AdaptiveWeatherRowPreviewHelper(
                     city: "Anchorage",
                     state: "AK",
                     latitude: 61.2181,
                     longitude: -149.9003
                 )

                 // Hot/Humid - Houston
                 AdaptiveWeatherRowPreviewHelper(
                     city: "Houston",
                     state: "TX",
                     latitude: 29.7604,
                     longitude: -95.3698
                 )
             }
             .frame(height: 400)
         }
     }
 }

 */

 // MARK: - Preview Helpers

 struct AdaptiveWeatherRowPreviewHelper: View {
     let city: String
     let state: String
     let latitude: Double
     let longitude: Double
     var showDate: Bool = false

     @State    var weather: Weather?
     @State    var isLoading = true

     var body: some View {
         Group {
             if isLoading {
                 HStack {
                     VStack(alignment: .leading, spacing: 4) {
                         Text(city)
                             .font(.headline)
                         Text("Loading...")
                             .font(.caption2)
                             .foregroundStyle(.secondary)
                     }
                     Spacer()
                     ProgressView()
                 }
                 .padding(.vertical, 8)
             } else if let weather = weather {
                 let current = weather.currentWeather
                 let dailyForecast = weather.dailyForecast.forecast.first

                 AdaptiveWeatherRowView(
                     location: WeatherLocation(
                         city: city,
                         state: state,
                         latitude: latitude,
                         longitude: longitude
                     ),
                     temperature: "\(String(format: "%.0f", current.temperature.converted(to: .fahrenheit).value))°",
                     condition: current.condition.description,
                     high: "H: \(String(format: "%.0f", dailyForecast?.highTemperature.converted(to: .fahrenheit).value ?? 0))°",
                     low: "L: \(String(format: "%.0f", dailyForecast?.lowTemperature.converted(to: .fahrenheit).value ?? 0))°",
                     symbolName: current.symbolName,
                     date: showDate ? formatDate(current.date) : nil
                 )
             } else {
                 HStack {
                     VStack(alignment: .leading, spacing: 4) {
                         Text(city)
                             .font(.headline)
                         Text("Failed to load")
                             .font(.caption2)
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

        func loadWeather() async {
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

        func formatDate(_ date: Date) -> String {
         let formatter = DateFormatter()
         formatter.dateFormat = "MMM d, h:mm a"
         return formatter.string(from: date)
     }
 }

 struct AdaptiveWeatherGridPreviewHelper: View {
     let city: String
     let state: String
     let latitude: Double
     let longitude: Double

     @State    var weather: Weather?
     @State    var isLoading = true

     var body: some View {
         Group {
             if isLoading {
                 VStack {
                     ProgressView("Loading weather data...")
                     Text(city)
                         .font(.caption)
                         .foregroundStyle(.secondary)
                 }
                 .frame(maxWidth: .infinity)
                 .padding()
             } else if let weather = weather {
                 let current = weather.currentWeather

                 AdaptiveWeatherGridView(
                     wind: current.wind,
                     humidity: current.humidity,
                     cloudCover: current.cloudCover,
                     uvIndex: current.uvIndex,
                     visibility: current.visibility,
                     pressure: current.pressure,
                     apparentTemperature: current.apparentTemperature
                 )
             } else {
                 VStack {
                     Image(systemName: "exclamationmark.triangle")
                         .font(.largeTitle)
                         .foregroundStyle(.red)
                     Text("Failed to load weather data")
                         .font(.caption)
                         .foregroundStyle(.red)
                 }
                 .frame(maxWidth: .infinity)
                 .padding()
             }
         }
         .task {
             await loadWeather()
         }
     }

        func loadWeather() async {
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

    struct CombinedPreviewHelper: View {
     let city: String
     let state: String
     let latitude: Double
     let longitude: Double

     @State    var weather: Weather?
     @State    var isLoading = true

     var body: some View {
         ScrollView {
             VStack(spacing: 16) {
                 if isLoading {
                     ProgressView("Loading weather data...")
                         .padding()
                 } else if let weather = weather {
                     let current = weather.currentWeather
                     let dailyForecast = weather.dailyForecast.forecast.first

                     // Row View
                     AdaptiveWeatherRowView(
                         location: WeatherLocation(
                             city: city,
                             state: state,
                             latitude: latitude,
                             longitude: longitude
                         ),
                         temperature: "\(String(format: "%.0f", current.temperature.converted(to: .fahrenheit).value))°",
                         condition: current.condition.description,
                         high: "H: \(String(format: "%.0f", dailyForecast?.highTemperature.converted(to: .fahrenheit).value ?? 0))°",
                         low: "L: \(String(format: "%.0f", dailyForecast?.lowTemperature.converted(to: .fahrenheit).value ?? 0))°",
                         symbolName: current.symbolName,
                         date: formatDate(current.date)
                     )
                     .padding()

                     Divider()

                     // Grid View
                     AdaptiveWeatherGridView(
                         wind: current.wind,
                         humidity: current.humidity,
                         cloudCover: current.cloudCover,
                         uvIndex: current.uvIndex,
                         visibility: current.visibility,
                         pressure: current.pressure,
                         apparentTemperature: current.apparentTemperature
                     )
                 } else {
                     VStack {
                         Image(systemName: "exclamationmark.triangle")
                             .font(.largeTitle)
                             .foregroundStyle(.red)
                         Text("Failed to load weather data")
                             .font(.caption)
                             .foregroundStyle(.red)
                     }
                     .padding()
                 }
             }
         }
         .task {
             await loadWeather()
         }
     }

        func loadWeather() async {
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

        func formatDate(_ date: Date) -> String {
         let formatter = DateFormatter()
         formatter.dateFormat = "MMM d, h:mm a"
         return formatter.string(from: date)
     }
 }
