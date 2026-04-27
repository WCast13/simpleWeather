//
//  simpleWeatherApp.swift  (drop-in replacement)
//  simpleWeather
//
//  Wires the v2 schema, the migration plan, and CloudKit-backed persistence.
//
//  Before this works:
//  1. Target → Signing & Capabilities → add **iCloud** capability.
//  2. Check **CloudKit**, then ensure the container `iCloud.wctech.simpleWeather`
//     is selected (matches `simpleWeather.entitlements` and the bundle ID
//     `wctech.simpleWeather`). Must match the constant below.
//  3. Capabilities → **Background Modes** → check **Remote notifications**
//     (CloudKit needs this for push-driven sync).
//  4. First run on a real device with iCloud signed in. The simulator has
//     flaky CloudKit support — don't waste time debugging there.
//

import SwiftUI
import SwiftData

@main
struct SimpleWeatherApp: App {

    /// Single source of truth for the configured container.
    /// Built once and held for the lifetime of the app.
    let sharedModelContainer: ModelContainer

    init() {
        do {
            let schema = Schema(versionedSchema: SchemaV3.self)

            // CloudKit-backed config. Pass `cloudKitDatabase: .private(...)`
            // so SwiftData knows to mirror the store into the user's
            // private CloudKit DB. Do NOT enable for the simulator — use the
            // launch-arg gate below if you need a local-only run.
            let config = ModelConfiguration(
                "SimpleWeather",
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: Self.useCloudKit
                    ? .private("iCloud.wctech.simpleWeather")
                    : .none
            )

            sharedModelContainer = try ModelContainer(
                for: schema,
                migrationPlan: SimpleWeatherMigrationPlan.self,
                configurations: [config]
            )
        } catch {
            // Fail loud. A failed migration silently falling back to
            // an in-memory store would be the worst possible outcome —
            // the user thinks the app works, then their data vanishes.
            fatalError("ModelContainer init failed: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            HomeView()
        }
        .modelContainer(sharedModelContainer)
    }

    // MARK: - Helpers

    /// Toggle CloudKit off for sim runs / unit tests.
    /// Run with `-disableCloudKit` in your scheme's launch arguments.
    /// Static so it's reachable from `init()` before stored properties land.
    private static var useCloudKit: Bool {
        !CommandLine.arguments.contains("-disableCloudKit")
    }
}
