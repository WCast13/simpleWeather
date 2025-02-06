//
//  simpleWeatherApp.swift
//  simpleWeather
//
//  Created by William Castellano on 2/3/25.
//

import SwiftUI
import SwiftData

@main
struct SimpleWeatherApp: App {
    var sharedModelContainer: ModelContainer?

    init() {
        do {
            let schema = Schema([WeatherLocation.self])
            sharedModelContainer = try ModelContainer(for: schema)
        } catch {
            print("⚠️ Error initializing SwiftData ModelContainer: \(error.localizedDescription)")
        }
    }

    var body: some Scene {
        WindowGroup {
            if let container = sharedModelContainer {
                HomeView()
                    .modelContainer(container)
            } else {
                Text("Failed to load data. Please restart the app.")
            }
        }
    }
}
