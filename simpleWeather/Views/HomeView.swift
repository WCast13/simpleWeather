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
    @Query private var locations: [WeatherLocation]
    @State private var weatherData: [UUID : Weather] = [:]
    
    var body: some View {
        NavigationStack {
            
            VStack {
                Text("\(Date.now.formatted(date: .abbreviated, time: .complete))")
                Text(weatherData.first?.value.currentWeather.date.formatted(date: .abbreviated, time: .complete) ?? "\(Date.now)")
//                Text("\(weatherData.first?.value.dailyForecast.first?.restOfDayForecast)" ?? "")
                
                List {
                    ForEach(locations) { location in
                        if let weather = weatherData[location.id] {
                            NavigationLink(destination: WeatherDetailView(weather: weather, location: location)) {
                                VStack(alignment: .leading) {
                                    AppleWeatherRowView(weather: weather, location: location)
                                    ScrollView(.horizontal) {
                                        DetailsScrollView(weather: weather)
                                    }
                                }
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
                }
            }
            .navigationTitle("SimpleWeather")
            .toolbar {
                NavigationLink(destination: AddLocationView()) {
                    Image(systemName: "plus")
                }
                
                Button("Test") {
                    print("\n\n\n*******************\n\n START HERE \n\n*******************\n\n\n")
                    print(weatherData.first?.value.dailyForecast ?? "")
                    print("\n\n")
                    print(weatherData.first?.value.dailyForecast.count ?? 0)
                    print("\n\n")
                    print(weatherData.first?.value.minuteForecast?.first?.date.formatted(date: .abbreviated, time: .complete) ?? Date.now)
                    print(weatherData.first?.value.minuteForecast?[1].date.formatted(date: .abbreviated, time: .complete) ?? Date.now)
                    print(weatherData.first?.value.minuteForecast?[4].date.formatted(date: .abbreviated, time: .complete) ?? Date.now)
                    print(weatherData.first?.value.minuteForecast?[30].date.formatted(date: .abbreviated, time: .complete) ?? Date.now)
                    print(weatherData.first?.value.minuteForecast?[60].date.formatted(date: .abbreviated, time: .complete) ?? Date.now)
                    print("\n\n\n*******************\n\n END HERE \n\n*******************\n\n\n")
                }
            }
        }
    }
    
    /// Fetch weather for a location
    private func fetchWeather(for location: WeatherLocation) async {
        do {
            let weather = try await WeatherKitManager.shared.fetchWeather(
                latitude: location.latitude,
                longitude: location.longitude
            )
            weatherData[location.id] = weather
        } catch {
            print("Failed to fetch weather: \(error.localizedDescription)")
        }
    }
    
    /// Delete a saved location
    private func deleteLocations(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(locations[index])
        }
    }
}

#Preview {
    HomeView()
}
