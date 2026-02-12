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
    @State private var showingTimePicker: Bool = false
    @State private var selectedDay: Date = Date()
    @State private var selectedHourOfDay: Int = 0

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

                // Time Selector Button (only shown for hourly and daily)
                if selectedDataType != .current {
                    timePickerButton
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }

                List {
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
                    Task {
                        await WeatherKitManager.shared.fetchWeatherSummary(latitude: 0.0, longitude: 0.0)
                    }
                }
            }
            .navigationTitle("SimpleWeather")
            .sheet(isPresented: $showingTimePicker) {
                timePickerSheet
            }
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

    // MARK: - Time Picker Button

    private var timePickerButton: some View {
        Button {
            showingTimePicker = true
        } label: {
            HStack {
                Text(currentTimeLabel)
                    .font(.subheadline)
                Image(systemName: "chevron.down")
                    .font(.caption)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    // MARK: - Time Picker Sheet

    private var timePickerSheet: some View {
        NavigationStack {
            VStack {
                if selectedDataType == .hourly {
                    if let firstWeather = weatherData.values.first {
                        let uniqueDays = getUniqueDays(from: firstWeather)
                        let hoursInDay = getHoursForDay(selectedDay, from: firstWeather)

                        HStack(spacing: 0) {
                            // Day Picker
                            Picker("Day", selection: $selectedDay) {
                                ForEach(uniqueDays, id: \.self) { day in
                                    Text(day.formatted(.dateTime.weekday(.wide)))
                                        .tag(day)
                                }
                            }
                            .pickerStyle(.wheel)
                            .onChange(of: selectedDay) { oldValue, newValue in
                                // Reset to first hour of the new day
                                let hours = getHoursForDay(newValue, from: firstWeather)
                                if let firstHour = hours.first {
                                    selectedHourOfDay = Calendar.current.component(.hour, from: firstHour.date)
                                    updateHourlyIndex(from: firstWeather)
                                }
                            }

                            // Hour Picker
                            Picker("Hour", selection: $selectedHourOfDay) {
                                ForEach(hoursInDay, id: \.date) { hourWeather in
                                    let hour = Calendar.current.component(.hour, from: hourWeather.date)
                                    Text(hourWeather.date.formatted(.dateTime.hour()))
                                        .tag(hour)
                                }
                            }
                            .pickerStyle(.wheel)
                            .onChange(of: selectedHourOfDay) { oldValue, newValue in
                                updateHourlyIndex(from: firstWeather)
                            }
                        }
                        .onAppear {
                            initializeHourlyPicker(from: firstWeather)
                        }
                    }
                } else if selectedDataType == .daily {
                    if let firstWeather = weatherData.values.first {
                        Picker("Select Day", selection: $dailyIndex) {
                            ForEach(Array(firstWeather.dailyForecast.enumerated()), id: \.offset) { index, dayWeather in
                                Text(timeLabel(for: index, dataType: .daily, weather: firstWeather))
                                    .tag(index)
                            }
                        }
                        .pickerStyle(.wheel)
                    }
                }
            }
            .navigationTitle(selectedDataType == .hourly ? "Select Hour" : "Select Day")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        showingTimePicker = false
                    }
                }
            }
        }
        .presentationDetents([.height(300)])
    }

    // MARK: - Helper Properties

    private var currentTimeLabel: String {
        guard let firstWeather = weatherData.values.first else {
            return selectedDataType == .hourly ? "Select Hour" : "Select Day"
        }

        if selectedDataType == .hourly {
            guard hourlyIndex < firstWeather.hourlyForecast.count else {
                return "Select Hour"
            }
            let hourWeather = firstWeather.hourlyForecast[hourlyIndex]
            return formatButtonDate(hourWeather.date, isHourly: true)
        } else {
            guard dailyIndex < firstWeather.dailyForecast.count else {
                return "Select Day"
            }
            let dayWeather = firstWeather.dailyForecast[dailyIndex]
            return formatButtonDate(dayWeather.date, isHourly: false)
        }
    }

    // MARK: - Private Methods

    // MARK: Date Formatting Helpers

    /// Format date for the button display
    private func formatButtonDate(_ date: Date, isHourly: Bool) -> String {
        if isHourly {
            return date.formatted(.dateTime.hour())
        } else {
            return date.formatted(.dateTime.weekday(.wide))
        }
    }

    // MARK: Hourly Picker Helpers

    /// Get unique days from hourly forecast
    private func getUniqueDays(from weather: Weather) -> [Date] {
        let calendar = Calendar.current
        var uniqueDays: [Date] = []
        var seenDays: Set<DateComponents> = []

        for hourWeather in weather.hourlyForecast {
            let dayComponents = calendar.dateComponents([.year, .month, .day], from: hourWeather.date)
            if !seenDays.contains(dayComponents) {
                seenDays.insert(dayComponents)
                if let dayStart = calendar.date(from: dayComponents) {
                    uniqueDays.append(dayStart)
                }
            }
        }

        return uniqueDays
    }

    /// Get hours for a specific day
    private func getHoursForDay(_ day: Date, from weather: Weather) -> [WeatherKit.HourWeather] {
        let calendar = Calendar.current
        let targetDay = calendar.dateComponents([.year, .month, .day], from: day)

        return weather.hourlyForecast.filter { hourWeather in
            let hourDay = calendar.dateComponents([.year, .month, .day], from: hourWeather.date)
            return hourDay == targetDay
        }
    }

    /// Initialize hourly picker with current hourlyIndex
    private func initializeHourlyPicker(from weather: Weather) {
        guard hourlyIndex < weather.hourlyForecast.count else { return }

        let selectedHourWeather = weather.hourlyForecast[hourlyIndex]
        let calendar = Calendar.current

        // Set selected day to the day of the current hourlyIndex
        let dayComponents = calendar.dateComponents([.year, .month, .day], from: selectedHourWeather.date)
        if let dayStart = calendar.date(from: dayComponents) {
            selectedDay = dayStart
        }

        // Set selected hour
        selectedHourOfDay = calendar.component(.hour, from: selectedHourWeather.date)
    }

    /// Update hourlyIndex based on selected day and hour
    private func updateHourlyIndex(from weather: Weather) {
        let calendar = Calendar.current

        for (index, hourWeather) in weather.hourlyForecast.enumerated() {
            let hourDay = calendar.dateComponents([.year, .month, .day], from: hourWeather.date)
            let targetDay = calendar.dateComponents([.year, .month, .day], from: selectedDay)
            let hour = calendar.component(.hour, from: hourWeather.date)

            if hourDay == targetDay && hour == selectedHourOfDay {
                hourlyIndex = index
                break
            }
        }
    }

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
            return hourWeather.date.formatted(.dateTime.weekday(.wide).hour())
        case .daily:
            guard index < weather.dailyForecast.count else { return "" }
            let dayWeather = weather.dailyForecast[index]
            return dayWeather.date.formatted(.dateTime.weekday(.wide))
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
