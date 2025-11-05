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
                Text("\(Date.now.formatted(date: .numeric, time: .shortened))")
                Text(weatherData.first?.value.currentWeather.date.formatted(date: .abbreviated, time: .shortened) ?? "\(Date.now.formatted(date: .abbreviated, time: .shortened))")
                
                List {
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
