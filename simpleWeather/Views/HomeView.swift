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
        SortDescriptor(\WeatherLocation.displayOrder),
        SortDescriptor(\WeatherLocation.dateAdded)
    ]) private var locations: [WeatherLocation]

    @State private var weatherData: [UUID : Weather] = [:]
    @State private var viewModel: LocationViewModel?

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
                            .swipeActions(edge: .leading) {
                                Button {
                                    toggleFavorite(location)
                                } label: {
                                    Label(location.isFavorite ? "Unfavorite" : "Favorite",
                                          systemImage: location.isFavorite ? "star.slash" : "star.fill")
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
            .onAppear {
                if viewModel == nil {
                    let repository = LocationRepository(modelContext: modelContext)
                    viewModel = LocationViewModel(repository: repository)
                }
            }
        }
    }

    // MARK: - Private Methods

    /// Fetch weather for a location
    private func fetchWeather(for location: WeatherLocation) async {
        do {
            let weather = try await WeatherKitManager.shared.fetchWeather(
                latitude: location.latitude,
                longitude: location.longitude
            )
            weatherData[location.id] = weather

            // Update last updated timestamp
            viewModel?.updateLastUpdated(location)
        } catch {
            print("Failed to fetch weather: \(error.localizedDescription)")
        }
    }

    /// Delete saved locations
    private func deleteLocations(at offsets: IndexSet) {
        viewModel?.deleteLocations(at: offsets)
    }

    /// Move/reorder locations
    private func moveLocations(from source: IndexSet, to destination: Int) {
        viewModel?.moveLocations(from: source, to: destination)
    }

    /// Toggle favorite status
    private func toggleFavorite(_ location: WeatherLocation) {
        viewModel?.toggleFavorite(location)
    }
}

#Preview {
    HomeView()
}
