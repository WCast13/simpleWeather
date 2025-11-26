//
//  HomeViewPreviews.swift
//  simpleWeather
//
//  Created by William Castellano on 2/19/25.
//

import SwiftUI
import SwiftData

/*
// MARK: - Empty State Preview
#Preview("HomeView - Empty State") {
    HomeView()
        .modelContainer(for: WeatherLocation.self, inMemory: true)
}

// MARK: - Single Location Preview
#Preview("HomeView - Single Location") {
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
                longitude: -122.4194
            )
            sanFrancisco.displayOrder = 0
            sanFrancisco.isFavorite = true
            context.insert(sanFrancisco)

            try? context.save()
        }
}

// MARK: - Multiple Locations Preview
#Preview("HomeView - Multiple Locations") {
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

            // Add Chicago
            let chicago = WeatherLocation(
                city: "Chicago",
                state: "IL",
                latitude: 41.8781,
                longitude: -87.6298
            )
            chicago.displayOrder = 2
            chicago.isFavorite = true
            context.insert(chicago)

            // Add Miami
            let miami = WeatherLocation(
                city: "Miami",
                state: "FL",
                latitude: 25.7617,
                longitude: -80.1918
            )
            miami.displayOrder = 3
            miami.isFavorite = false
            context.insert(miami)

            try? context.save()
        }
}

// MARK: - Many Locations Preview
#Preview("HomeView - Many Locations") {
    HomeView()
        .modelContainer(for: WeatherLocation.self, inMemory: true) { result in
            guard case .success(let container) = result else {
                fatalError("Failed to create model container for preview")
            }

            let context = container.mainContext

            let locations = [
                ("San Francisco", "CA", 37.7749, -122.4194, true),
                ("New York", "NY", 40.7128, -74.0060, true),
                ("Chicago", "IL", 41.8781, -87.6298, false),
                ("Miami", "FL", 25.7617, -80.1918, false),
                ("Seattle", "WA", 47.6062, -122.3321, true),
                ("Denver", "CO", 39.7392, -104.9903, false),
                ("Boston", "MA", 42.3601, -71.0589, false),
                ("Los Angeles", "CA", 34.0522, -118.2437, false),
                ("Phoenix", "AZ", 33.4484, -112.0740, false),
                ("Portland", "OR", 45.5152, -122.6784, false)
            ]

            for (index, locationData) in locations.enumerated() {
                let location = WeatherLocation(
                    city: locationData.0,
                    state: locationData.1,
                    latitude: locationData.2,
                    longitude: locationData.3
                )
                location.displayOrder = index
                location.isFavorite = locationData.4
                context.insert(location)
            }

            try? context.save()
        }
}

// MARK: - With Favorites Preview
#Preview("HomeView - Only Favorites") {
    HomeView()
        .modelContainer(for: WeatherLocation.self, inMemory: true) { result in
            guard case .success(let container) = result else {
                fatalError("Failed to create model container for preview")
            }

            let context = container.mainContext

            let favorites = [
                ("San Francisco", "CA", 37.7749, -122.4194),
                ("New York", "NY", 40.7128, -74.0060),
                ("Chicago", "IL", 41.8781, -87.6298)
            ]

            for (index, locationData) in favorites.enumerated() {
                let location = WeatherLocation(
                    city: locationData.0,
                    state: locationData.1,
                    latitude: locationData.2,
                    longitude: locationData.3
                )
                location.displayOrder = index
                location.isFavorite = true
                context.insert(location)
            }

            try? context.save()
        }
}

// MARK: - Diverse Weather Conditions Preview
#Preview("HomeView - Diverse Weather") {
    HomeView()
        .modelContainer(for: WeatherLocation.self, inMemory: true) { result in
            guard case .success(let container) = result else {
                fatalError("Failed to create model container for preview")
            }

            let context = container.mainContext

            // Hot, Cold, Moderate, Rainy, etc.
            let locations = [
                ("Phoenix", "AZ", 33.4484, -112.0740, false),      // Hot
                ("Anchorage", "AK", 61.2181, -149.9003, false),    // Cold
                ("Seattle", "WA", 47.6062, -122.3321, true),       // Rainy
                ("Honolulu", "HI", 21.3099, -157.8581, false),     // Tropical
                ("Denver", "CO", 39.7392, -104.9903, false)        // High altitude
            ]

            for (index, locationData) in locations.enumerated() {
                let location = WeatherLocation(
                    city: locationData.0,
                    state: locationData.1,
                    latitude: locationData.2,
                    longitude: locationData.3
                )
                location.displayOrder = index
                location.isFavorite = locationData.4
                context.insert(location)
            }

            try? context.save()
        }
}

// MARK: - Dark Mode Preview
#Preview("HomeView - Dark Mode") {
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
                longitude: -122.4194
            )
            sanFrancisco.displayOrder = 0
            sanFrancisco.isFavorite = true
            context.insert(sanFrancisco)

            let newYork = WeatherLocation(
                city: "New York",
                state: "NY",
                latitude: 40.7128,
                longitude: -74.0060
            )
            newYork.displayOrder = 1
            context.insert(newYork)

            try? context.save()
        }
        .preferredColorScheme(.dark)
}
*/
