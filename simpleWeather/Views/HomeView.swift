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

    @State private var weatherViewModel = WeatherViewModel()
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
                    TimePickerButton(currentTimeLabel: currentTimeLabel) {
                        showingTimePicker = true
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }

                List {
                    ForEach(locations) { location in
                        if let weather = weatherViewModel.weather(for: location.id) {
                            NavigationLink(destination: WeatherDetailView(weather: weather, location: location)) {
                                WeatherRowContainer(
                                    location: location,
                                    weather: weather,
                                    dataType: selectedDataType,
                                    hourlyIndex: hourlyIndex,
                                    dailyIndex: dailyIndex,
                                    showGrid: showWeatherGrid
                                )
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
                                    await weatherViewModel.fetchWeather(for: location)
                                    updateLastUpdated(location)
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
                if let firstWeather = weatherViewModel.weatherData.values.first {
                    TimePickerSheet(
                        selectedDataType: $selectedDataType,
                        hourlyIndex: $hourlyIndex,
                        dailyIndex: $dailyIndex,
                        selectedDay: $selectedDay,
                        selectedHourOfDay: $selectedHourOfDay,
                        weather: firstWeather
                    ) {
                        showingTimePicker = false
                    }
                }
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

    // MARK: - Helper Properties

    private var currentTimeLabel: String {
        guard let firstWeather = weatherViewModel.weatherData.values.first else {
            return selectedDataType == .hourly ? "Select Hour" : "Select Day"
        }

        if selectedDataType == .hourly {
            guard hourlyIndex < firstWeather.hourlyForecast.count else {
                return "Select Hour"
            }
            let hourWeather = firstWeather.hourlyForecast[hourlyIndex]
            return WeatherDataTransformer.formatButtonDate(hourWeather.date, isHourly: true)
        } else {
            guard dailyIndex < firstWeather.dailyForecast.count else {
                return "Select Day"
            }
            let dayWeather = firstWeather.dailyForecast[dailyIndex]
            return WeatherDataTransformer.formatButtonDate(dayWeather.date, isHourly: false)
        }
    }

    // MARK: - Private Methods

    /// Delete saved locations
    private func deleteLocations(at offsets: IndexSet) {
        for index in offsets {
            let location = locations[index]
            weatherViewModel.clearWeather(for: location.id)
            modelContext.delete(location)
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

    /// Update last updated timestamp
    private func updateLastUpdated(_ location: WeatherLocation) {
        location.lastUpdated = Date()
        try? modelContext.save()
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
