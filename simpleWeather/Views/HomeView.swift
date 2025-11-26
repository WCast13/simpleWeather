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

enum WeatherDataType: String, CaseIterable {
    case current = "Current"
    case hourly = "Hourly"
    case daily = "Daily"
}

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [
        SortDescriptor(\WeatherLocation.dateAdded)
    ])  var locations: [WeatherLocation]

    @State private var weatherData: [UUID : Weather] = [:]
    @AppStorage("showWeatherGrid") private var showWeatherGrid: Bool = true
    @State private var selectedDataType: WeatherDataType = .current
    @State private var hourlyIndex: Int = 0
    @State private var dailyIndex: Int = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Segmented Control
                Picker("Weather Data Type", selection: $selectedDataType) {
                    ForEach(WeatherDataType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.top, 8)
                .onChange(of: selectedDataType) { oldValue, newValue in
                    // Reset indices when switching data types
                    hourlyIndex = 0
                    dailyIndex = 0
                }

                // Time Slider (only shown for hourly and daily)
                if selectedDataType != .current {
                    timeSliderView
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }

                List {
                    
//                    Button("Data Params") {
//                        printData()
//                    }
                    
                    ForEach(locations) { location in
                        if let weather = weatherData[location.id] {
                            NavigationLink(destination: WeatherDetailView(weather: weather, location: location)) {
                                VStack(alignment: .leading) {
                                    let displayData = weatherForDisplay(weather)
                                    let dateLabel = selectedDataType != .current ? timeLabel(for: selectedDataType == .hourly ? hourlyIndex : dailyIndex, dataType: selectedDataType, weather: weather) : nil

                                    AdaptiveWeatherRowView(
                                        location: location,
                                        temperature: displayData.temperature,
                                        condition: displayData.condition,
                                        high: displayData.high,
                                        low: displayData.low,
                                        symbolName: displayData.symbolName,
                                        date: dateLabel
                                    )

                                    if showWeatherGrid {
                                        let gridData = gridWeatherData(weather)
                                        AdaptiveWeatherGridView(
                                            wind: gridData.wind,
                                            humidity: gridData.humidity,
                                            cloudCover: gridData.cloudCover,
                                            uvIndex: gridData.uvIndex,
                                            visibility: gridData.visibility,
                                            pressure: gridData.pressure,
                                            apparentTemperature: gridData.currentWeather.apparentTemperature
                                        )
                                        .transition(.asymmetric(
                                            insertion: .opacity.combined(with: .move(edge: .top)),
                                            removal: .opacity.combined(with: .move(edge: .top))
                                        ))
                                    }
                                }
                                .animation(.easeInOut(duration: 0.3), value: showWeatherGrid)
                                .animation(.easeInOut(duration: 0.3), value: selectedDataType)
                                .animation(.easeInOut(duration: 0.2), value: hourlyIndex)
                                .animation(.easeInOut(duration: 0.2), value: dailyIndex)
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
                .onAppear {
                    print("Started")
                    Task {
                        await WeatherKitManager.shared.fetchWeatherSummary(latitude: 0.0, longitude: 0.0)
                        await WeatherKitManager.shared.fetchWeatherSumary(latitude: 0.0, longitude: 0.0)
                    }
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
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showWeatherGrid.toggle()
                        }
                    } label: {
                        Image(systemName: showWeatherGrid ? "square.grid.3x3.fill" : "square.grid.3x3")
                            .contentTransition(.symbolEffect(.replace))
                    }
                }
            }
        }
    }

    // MARK: - Time Slider View

    private var timeSliderView: some View {
        VStack(spacing: 8) {
            if selectedDataType == .hourly {
                if let firstWeather = weatherData.values.first {
                    let maxIndex = max(0, firstWeather.hourlyForecast.count - 1)
                    VStack(spacing: 4) {
                        Text(timeLabel(for: hourlyIndex, dataType: .hourly, weather: firstWeather))
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Slider(value: Binding(
                            get: { Double(hourlyIndex) },
                            set: { hourlyIndex = Int($0) }
                        ), in: 0...Double(maxIndex), step: 1)
                        .padding(.horizontal)
                    }
                }
            } else if selectedDataType == .daily {
                if let firstWeather = weatherData.values.first {
                    let maxIndex = max(0, firstWeather.dailyForecast.count - 1)
                    VStack(spacing: 4) {
                        Text(timeLabel(for: dailyIndex, dataType: .daily, weather: firstWeather))
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Slider(value: Binding(
                            get: { Double(dailyIndex) },
                            set: { dailyIndex = Int($0) }
                        ), in: 0...Double(maxIndex), step: 1)
                        .padding(.horizontal)
                    }
                }
            }
        }
        .padding(.vertical, 8)
        .animation(.easeInOut(duration: 0.3), value: selectedDataType)
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

    /// Get time label for slider
    private func timeLabel(for index: Int, dataType: WeatherDataType, weather: Weather) -> String {
        switch dataType {
        case .hourly:
            guard index < weather.hourlyForecast.count else { return "" }
            let hourWeather = weather.hourlyForecast[index]
            let formatter = DateFormatter()
            formatter.dateFormat = "E, MMM d 'at' h:mm a"
            return formatter.string(from: hourWeather.date)
        case .daily:
            guard index < weather.dailyForecast.count else { return "" }
            let dayWeather = weather.dailyForecast[index]
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE, MMM d"
            return formatter.string(from: dayWeather.date)
        case .current:
            return "Current"
        }
    }

    /// Get weather data for display based on selected type
    private func weatherForDisplay(_ weather: Weather) -> (temperature: String, condition: String, high: String, low: String, symbolName: String) {
        switch selectedDataType {
        case .current:
            let current = weather.currentWeather
            let high = weather.dailyForecast.first?.highTemperature.converted(to: .fahrenheit).value ?? 0
            let low = weather.dailyForecast.first?.lowTemperature.converted(to: .fahrenheit).value ?? 0
            return (
                temperature: "\(Int(current.temperature.converted(to: .fahrenheit).value))°",
                condition: current.condition.description,
                high: "H: \(Int(high))°",
                low: "L: \(Int(low))°",
                symbolName: current.symbolName
            )
        case .hourly:
            guard hourlyIndex < weather.hourlyForecast.count else {
                return ("--°", "No data", "H: --°", "L: --°", "questionmark")
            }
            let hourWeather = weather.hourlyForecast[hourlyIndex]
            return (
                temperature: "\(Int(hourWeather.temperature.converted(to: .fahrenheit).value))°",
                condition: hourWeather.condition.description,
                high: "Precip: \(Int(hourWeather.precipitationChance * 100))%",
                low: "",
                symbolName: hourWeather.symbolName
            )
        case .daily:
            guard dailyIndex < weather.dailyForecast.count else {
                return ("--°", "No data", "H: --°", "L: --°", "questionmark")
            }
            let dayWeather = weather.dailyForecast[dailyIndex]
            return (
                temperature: "\(Int(dayWeather.highTemperature.converted(to: .fahrenheit).value))°",
                condition: dayWeather.condition.description,
                high: "H: \(Int(dayWeather.highTemperature.converted(to: .fahrenheit).value))°",
                low: "L: \(Int(dayWeather.lowTemperature.converted(to: .fahrenheit).value))°",
                symbolName: dayWeather.symbolName
            )
        }
    }

    /// Get grid weather data based on selected type
    private func gridWeatherData(_ weather: Weather) -> (currentWeather: CurrentWeather, wind: Wind, humidity: Double, cloudCover: Double, uvIndex: UVIndex, visibility: Measurement<UnitLength>, pressure: Measurement<UnitPressure>) {
        switch selectedDataType {
        case .current:
            let current = weather.currentWeather
            return (current, current.wind, current.humidity, current.cloudCover, current.uvIndex, current.visibility, current.pressure)
        case .hourly:
            guard hourlyIndex < weather.hourlyForecast.count else {
                let current = weather.currentWeather
                return (current, current.wind, current.humidity, current.cloudCover, current.uvIndex, current.visibility, current.pressure)
            }
            let hourWeather = weather.hourlyForecast[hourlyIndex]
            // HourWeather doesn't have all properties, so we return a mix
            return (weather.currentWeather, hourWeather.wind, hourWeather.humidity, hourWeather.cloudCover, hourWeather.uvIndex, hourWeather.visibility, hourWeather.pressure)
        case .daily:
            // Daily doesn't have detailed current conditions, use current weather
            let current = weather.currentWeather
            return (current, current.wind, current.humidity, current.cloudCover, current.uvIndex, current.visibility, current.pressure)
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
}

#Preview {
    HomeView()
        .modelContainer(for: WeatherLocation.self, inMemory: true) { result in
            guard case .success(let container) = result else {
                fatalError("Failed to create model container for preview")
            }

            let context = container.mainContext

            // Add San Francisco
            let sanFrancisco = WeatherLocation(
                city: "San Francisco",
                state: "CA",
                latitude: 37.7749,
                longitude: -122.4194
            )
            sanFrancisco.displayOrder = 0
            sanFrancisco.isFavorite = true
            context.insert(sanFrancisco)

            // Add New York
            let newYork = WeatherLocation(
                city: "New York",
                state: "NY",
                latitude: 40.7128,
                longitude: -74.0060
            )
            newYork.displayOrder = 1
            newYork.isFavorite = false
            context.insert(newYork)

            try? context.save()
        }
}
