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
    // Dual sort: post-v1-migration rows all share displayOrder = 0 because the
    // migration plan doesn't backfill it; dateAdded breaks ties deterministically.
    @Query(sort: [
        SortDescriptor(\WeatherLocation.displayOrder),
        SortDescriptor(\WeatherLocation.dateAdded)
    ]) var locations: [WeatherLocation]

    @State private var weatherViewModel = WeatherViewModel()
    @State private var showingErrorAlert: Bool = false
    @State private var activeErrorMessage: String = ""
    @State private var activeErrorLocationId: UUID?
    @State private var showingAnalytics: Bool = false
    @State private var networkMonitor = NetworkMonitor.shared
    @State private var customizingLocation: WeatherLocation?
    @State private var navTarget: WeatherLocation?

    private var repo: LocationRepository {
        LocationRepository(modelContext: modelContext)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if networkMonitor.isOffline {
                    HStack {
                        Image(systemName: "wifi.slash")
                        Text("Offline Mode - Showing Cached Data")
                            .font(.caption)
                    }
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                    .background(Color.orange.opacity(0.2))
                }

                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(locations) { location in
                            LocationCardView(
                                location: location,
                                snapshot: weatherViewModel.snapshot(for: location.id),
                                onTap: { navTarget = location }
                            )
                            .overlay(alignment: .topTrailing) {
                                if weatherViewModel.errorMessage(for: location.id) != nil {
                                    Button {
                                        if let msg = weatherViewModel.errorMessage(for: location.id) {
                                            showError(message: msg, for: location.id)
                                        }
                                    } label: {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .font(.caption)
                                            .foregroundStyle(.orange)
                                            .padding(8)
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityLabel("Show weather error")
                                }
                            }
                            .contextMenu {
                                Button {
                                    toggleFavorite(location)
                                } label: {
                                    Label(
                                        location.isFavorite ? "Unfavorite" : "Favorite",
                                        systemImage: location.isFavorite ? "star.slash.fill" : "star.fill"
                                    )
                                }

                                Button {
                                    customizingLocation = location
                                } label: {
                                    Label("Customize", systemImage: "slider.horizontal.3")
                                }

                                Divider()

                                Button(role: .destructive) {
                                    deleteLocation(location)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                            .task {
                                guard weatherViewModel.weather(for: location.id) == nil,
                                      weatherViewModel.errorMessage(for: location.id) == nil
                                else { return }
                                await weatherViewModel.fetchWeather(for: location)
                                if weatherViewModel.errorMessage(for: location.id) == nil {
                                    updateLastUpdated(location)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }
                .background(Color(.systemGroupedBackground))
                .refreshable {
                    await weatherViewModel.refreshAllWeather(for: locations)
                    for location in locations where weatherViewModel.weather(for: location.id) != nil {
                        updateLastUpdated(location)
                    }
                }
            }
            .navigationTitle("SimpleWeather")
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        showingAnalytics = true
                    } label: {
                        Image(systemName: "chart.bar.fill")
                    }

                    NavigationLink(destination: AddLocationView()) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAnalytics) {
                CacheAnalyticsView(cache: .shared, networkMonitor: networkMonitor)
            }
            .sheet(item: $customizingLocation) { location in
                WeatherDisplayCustomizationView(location: location)
            }
            .navigationDestination(item: $navTarget) { location in
                if let weather = weatherViewModel.weather(for: location.id) {
                    WeatherDetailView(weather: weather, location: location)
                } else {
                    ProgressView("Loading weather…")
                        .task { await weatherViewModel.fetchWeather(for: location) }
                }
            }
            .alert("Weather Error", isPresented: $showingErrorAlert) {
                Button("OK") {
                    showingErrorAlert = false
                    if let locationId = activeErrorLocationId {
                        weatherViewModel.clearError(for: locationId)
                    }
                }
                if let locationId = activeErrorLocationId {
                    Button("Retry") {
                        Task {
                            if let location = locations.first(where: { $0.id == locationId }) {
                                await weatherViewModel.fetchWeather(for: location, forceRefresh: true)
                            }
                        }
                        showingErrorAlert = false
                    }
                }
            } message: {
                Text(activeErrorMessage)
            }
            .task {
                let purged = (try? repo.purgeExpired()) ?? 0
                if purged > 0 {
                    print("[SimpleWeather] Auto-removed \(purged) expired location(s).")
                }
            }
        }
    }

    // MARK: - Private Methods

    private func deleteLocation(_ location: WeatherLocation) {
        weatherViewModel.clearWeather(for: location.id)
        do {
            try repo.delete(location)
        } catch {
            showError(message: "Failed to delete location: \(error.localizedDescription)", for: location.id)
        }
    }

    private func toggleFavorite(_ location: WeatherLocation) {
        location.isFavorite.toggle()
        do {
            try modelContext.save()
        } catch {
            showError(message: "Failed to update favorite status: \(error.localizedDescription)", for: location.id)
        }
    }

    private func updateLastUpdated(_ location: WeatherLocation) {
        location.lastUpdated = Date()
        do {
            try modelContext.save()
        } catch {
            print("Failed to save last updated timestamp: \(error.localizedDescription)")
        }
    }

    private func showError(message: String, for locationId: UUID) {
        activeErrorMessage = message
        activeErrorLocationId = locationId
        showingErrorAlert = true
    }
}

#Preview {
    HomeView()
        .modelContainer(for: WeatherLocation.self, inMemory: true) { result in
            guard case .success(let container) = result else {
                fatalError("Failed to create model container for preview")
            }

            let context = container.mainContext

            let sanFrancisco = WeatherLocation(
                city: "San Francisco",
                state: "CA",
                latitude: 37.7749,
                longitude: -122.4194,
                displayOrder: 0,
                isFavorite: true
            )
            context.insert(sanFrancisco)

            let newYork = WeatherLocation(
                city: "New York",
                state: "NY",
                latitude: 40.7128,
                longitude: -74.0060,
                displayOrder: 1
            )
            context.insert(newYork)

            try? context.save()
        }
}
