//
//  HomeView.swift
//  simpleWeather
//
//  Created by William Castellano on 2/3/25.
//

import SwiftUI
import SwiftData
import WeatherKit
import CoreLocation

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [
        SortDescriptor(\WeatherLocation.dateAdded)
    ])  var locations: [WeatherLocation]

    @State private var weatherData: [UUID : Weather] = [:]

    var body: some View {
        NavigationStack {
            VStack { // TODO: Add Segmented Control- List View/MapView
                List {
                    
                    Button("Data Params") {
                        printData()
                    }
                    
                    ForEach(locations) { location in
                        if let weather = weatherData[location.id] {
                            NavigationLink(destination: WeatherDetailView(weather: weather, location: location)) {
                                VStack(alignment: .leading) {
                                    AppleWeatherRowView(weather: weather, location: location)
                                    ScrollView(.horizontal) {
                                        StandaredRowDetailsView(weather: weather)
                                    }
                                }
                            }
                            .swipeActions(edge: .leading) {
                                Button {
                                    toggleFavorite(location)
                                } label: {
                                    Label(location.isFavorite ?? false ? "Unfavorite" : "Favorite",
                                          systemImage: location.isFavorite ?? false ? "star.slash" : "star.fill")
                                }
                                .tint(.yellow)
                            }
                        }
                        else {
                            ProgressView()
                                .task {
                                    await fetchWeather(for: location)
                                }
                        }
                    }
                    .onDelete(perform: deleteLocations)
                    .onMove(perform: moveLocations)
                }
            }
            .navigationTitle("SimpleWeather")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(destination: AddLocationView()) {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    EditButton()
                }
            }
        }
    }
    
    func printData() {
        guard let location = locations.first else { return }
        guard let locationData = weatherData[location.id] else { return }

        // WeatherKit properties here are non-optional; access them directly
        let currentData = locationData.currentWeather
        
        let hourlyData = locationData.hourlyForecast
        guard let hourlyFirst = hourlyData.first else { return }
        
        let dailyData = locationData.dailyForecast
        guard let dailyFirst = dailyData.first else { return }
    
        let minuteData = locationData.minuteForecast
        guard let minuteFirst = minuteData?.first else { return }
        
        let alertsData = locationData.weatherAlerts
        
        print("****************************************************************\n*******************************\n**************\n")
        print("Weather for \(location.city ?? "Unknown Location"):\n")
        
        print(
"""
******************** CURRENT ********************

Date: \(currentData.date.formatted(date: .numeric, time: .shortened))
Expiration Date: \(currentData.metadata.expirationDate.formatted(date: .numeric, time: .shortened))

Condition: \(currentData.condition.description)
SFSymbol Name: \(currentData.symbolName)
Is Daylight: \(currentData.isDaylight)

Tempeture: \(String(format: "%.0f", currentData.temperature.converted(to: .fahrenheit).value))
Temp in C: \(String(format: "%.0f", currentData.temperature.value))
Temp in C: \(currentData.temperature.description)

Feels Like: \(String(format: "%.0f", currentData.temperature.converted(to: .fahrenheit).value))

Wind: \(String(format: "%.0f", currentData.wind.speed.converted(to: .milesPerHour).value))
    \(currentData.wind.compassDirection.description)
    \(currentData.wind.compassDirection.abbreviation)
    \(String(format: "%.0f", currentData.wind.direction.value))
    \(String(format: "%.0f", currentData.wind.gust?.converted(to: .milesPerHour).value ?? "No data"))

Precipitation: \(currentData.precipitationIntensity.value)
            \(currentData.precipitationIntensity.value)

Humidity: \(String(format: "%.0f", currentData.humidity * 100))% 

Cloud Cover: \(String(format: "%.0f", currentData.cloudCover * 100))%
Cloud Cover by Altitude: 
    High: \(String(format: "%.0f", currentData.cloudCoverByAltitude.high * 100))% 
    Medium: \(String(format: "%.0f", currentData.cloudCoverByAltitude.medium * 100))%
    Low: \(String(format: "%.0f", currentData.cloudCoverByAltitude.low * 100))%


Pressure: \(currentData.pressure.value), \(currentData.pressure.description)
Pressure Trend: \(currentData.pressureTrend.description)

UV Index: \(currentData.uvIndex.value)
    Category: \(currentData.uvIndex.category.description) 
    Range: \(currentData.uvIndex.category.rangeValue)
    \(currentData.uvIndex.category.rangeValue.lowerBound)
    \(currentData.uvIndex.category.rangeValue.upperBound)

Visibility: \(currentData.visibility.converted(to: .miles).value) 
\(currentData.visibility.converted(to: .miles).description)

Dew Point: \(String(format: "%.0f", currentData.dewPoint.converted(to: .fahrenheit).value))
        \(currentData.dewPoint.converted(to: .fahrenheit).description)


******************** HOURLY ********************

\(hourlyData.count)                    
\(hourlyData.startIndex)
\(hourlyData.endIndex)

\(hourlyData.metadata.date.formatted(date: .numeric, time: .shortened))
\(hourlyData.metadata.expirationDate.formatted(date: .numeric, time: .shortened))

\(hourlyFirst.precipitationChance.description)

\(hourlyFirst.date.formatted(date: .numeric, time: .shortened))
\(hourlyFirst.symbolName)

\(hourlyFirst.temperature.converted(to: .fahrenheit))

\(hourlyFirst.apparentTemperature)
\(hourlyFirst.cloudCover)
\(hourlyFirst.cloudCoverByAltitude)
\(hourlyFirst.condition.description)
\(hourlyFirst.pressure)
\(hourlyFirst.pressureTrend)
\(hourlyFirst.precipitation)
\(hourlyFirst.precipitationAmount)
\(hourlyFirst.snowfallAmount)
\(hourlyFirst.uvIndex)
\(hourlyFirst.visibility)
\(hourlyFirst.wind)

******************** DAILY ********************

\(dailyData.count)                    
\(dailyData.startIndex)
\(dailyData.endIndex)

\(dailyData.metadata.date.formatted(date: .numeric, time: .shortened))
\(dailyData.metadata.expirationDate.formatted(date: .numeric, time: .shortened))


\(dailyFirst.date.formatted(date: .numeric, time: .shortened))
\(dailyFirst.highTemperature)
\(dailyFirst.lowTemperature)
\(dailyFirst.symbolName)
\(dailyFirst.condition)

\(dailyFirst.daytimeForecast)


\(dailyFirst.highTemperatureTime?.formatted(date: .numeric, time: .shortened) ?? "")
\(dailyFirst.highWindSpeed?.description ?? "")

\(dailyFirst.lowTemperatureTime?.formatted(date: .numeric, time: .shortened) ?? "")
\(dailyFirst.maximumHumidity)
\(dailyFirst.maximumVisibility)
\(dailyFirst.minimumHumidity)
\(dailyFirst.minimumVisibility)
\(dailyFirst.moon.moonrise?.formatted(date: .numeric, time: .shortened) ?? "")
\(dailyFirst.moon.moonset?.formatted(date: .numeric, time: .shortened) ?? "")
\(dailyFirst.moon.phase.description)
\(dailyFirst.moon)     
\(dailyFirst.overnightForecast)

\(dailyFirst.precipitation) 
\(dailyFirst.precipitationAmountByType)

\(dailyFirst.sun)

\(dailyFirst.sun.astronomicalDawn?.formatted(date: .numeric, time: .shortened) ?? "")
\(dailyFirst.sun.nauticalDawn?.formatted(date: .numeric, time: .shortened) ?? "")
\(dailyFirst.sun.civilDawn?.formatted(date: .numeric, time: .shortened) ?? "")
\(dailyFirst.sun.sunrise?.formatted(date: .numeric, time: .shortened) ?? "")

\(dailyFirst.sun.solarNoon?.formatted(date: .numeric, time: .shortened) ?? "")

\(dailyFirst.sun.sunset?.formatted(date: .numeric, time: .shortened) ?? "")
\(dailyFirst.sun.civilDusk?.formatted(date: .numeric, time: .shortened) ?? "")
\(dailyFirst.sun.nauticalDusk?.formatted(date: .numeric, time: .shortened) ?? "")
\(dailyFirst.sun.astronomicalDusk?.formatted(date: .numeric, time: .shortened) ?? "")

\(dailyFirst.sun.solarMidnight?.formatted(date: .numeric, time: .shortened) ?? "")
"""
)
        
    }

    // MARK: - Private Methods

    /// Fetch weather for a location
    private func fetchWeather(for location: WeatherLocation) async {
        do {
            let weather = try await WeatherKitManager.shared.fetchWeather(
                latitude: location.latitude ?? 0.0,
                longitude: location.longitude ?? 0.0
            )
            weatherData[location.id] = weather

            // Update last updated timestamp
            location.lastUpdated = Date()
            try? modelContext.save()
        } catch {
            print("Failed to fetch weather: \(error.localizedDescription)")
        }
    }

    /// Delete saved locations
    private func deleteLocations(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(locations[index])
        }
        try? modelContext.save()
    }

    /// Move/reorder locations
    private func moveLocations(from source: IndexSet, to destination: Int) {
        var updatedLocations = locations
        updatedLocations.move(fromOffsets: source, toOffset: destination)

        // Update display order for all locations
        for (index, location) in updatedLocations.enumerated() {
            location.displayOrder = index
        }
        try? modelContext.save()
    }

    /// Toggle favorite status
    private func toggleFavorite(_ location: WeatherLocation) {
        location.isFavorite = !(location.isFavorite ?? false)
        try? modelContext.save()
    }
}

#Preview {
    HomeView()
}
