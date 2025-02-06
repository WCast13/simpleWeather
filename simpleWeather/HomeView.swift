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
            List {
                ForEach(locations) { location in
                    if let weather = weatherData[location.id] {
                        StandardRowView(weather: weather, location: location)
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
            .navigationTitle("SimpleWeather")
            .toolbar {
                NavigationLink(destination: AddLocationView()) {
                    Image(systemName: "plus")
                }
                
                Button("Test") {
                    print("\n\n\n*******************\n\n START HERE \n\n*******************\n\n\n\n\n")
                    for location in weatherData.values {
                        print("\(String(format: "%.0f", location.currentWeather.temperature.converted(to: .fahrenheit).value))°F")
                        print("\(String(format: "%.0f", location.currentWeather.humidity * 100))%")
                        print(location.currentWeather.cloudCoverByAltitude)
                    }
                    
                    
                    
                    
                    
//                    print("\n\n\n\n\n\n\n\n\n\n\n\n")
////                    print(weatherData.first!.value.minuteForecast.first)
//                    print("\n")
//                    print(weatherData.first!.value.hourlyForecast.first!)
//                    print("\n")
//                    print(weatherData.first!.value.dailyForecast.first!)
//                    
//                    if let hourlyForecast = weatherData.first?.value.hourlyForecast {
//                    
//                        for hour in hourlyForecast {
////                            print("Time: \(hour.date), Temp: \(hour.temperature), Wind: \(hour.wind.speed), Wind Dir: \(hour.wind.compassDirection.abbreviation)")
//                            print("\n\n\(hour)\n\n")
//                            
//                        }
//                    }
                }
            }
        }
    }
    
    /// Fetch weather for a location
    private func fetchWeather(for location: WeatherLocation) async {
        do {
            let weather = try await WeatherManager.shared.fetchWeather(
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
