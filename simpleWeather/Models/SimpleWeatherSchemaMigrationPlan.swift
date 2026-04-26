//
//  SimpleWeatherSchemaMigrationPlan.swift
//  simpleWeather
//
//  Tells SwiftData how to walk users from v1 → v2 the first time the
//  new build launches. Custom stage so we can fill in the new fields with
//  sane defaults rather than letting SwiftData guess.
//

import Foundation
import SwiftData

enum SimpleWeatherMigrationPlan: SchemaMigrationPlan {

    static var schemas: [any VersionedSchema.Type] {
        [SchemaV1.self, SchemaV2.self]
    }

    static var stages: [MigrationStage] {
        [migrateV1toV2]
    }

    // MARK: - V1 → V2 ----------------------------------------------------------

    /// Custom (not lightweight) because we're collapsing optionals to
    /// defaulted values and seeding `cardSize` / `locationType`. Lightweight
    /// would lose intent (every old row would land as `.permanent` / `.compact`
    /// regardless — which is what we want, but being explicit is cheap and
    /// makes future migrations less scary to write).
    ///
    /// IMPORTANT: this runs ONCE per device, before the new app code touches
    /// the store. The closure is passed a `ModelContext` for the *new* schema.
    static let migrateV1toV2 = MigrationStage.custom(
        fromVersion: SchemaV1.self,
        toVersion: SchemaV2.self,

        willMigrate: { context in
            // Pre-flight: anything we want to read from the OLD schema before
            // the rows are rewritten. We have nothing to do here for v1→v2;
            // SwiftData hands us new rows already mapped from old data.
            // Leaving this hook in place + commented for future migrations.
            //
            // let oldRows = try context.fetch(FetchDescriptor<SchemaV1.WeatherLocationV1>())
            // print("Migrating \(oldRows.count) locations from v1 → v2")
        },

        didMigrate: { context in
            // Post-migration cleanup: walk every new row and patch any field
            // that wound up nil/zero because v1 stored it as Optional.
            let descriptor = FetchDescriptor<WeatherLocation>()
            guard let rows = try? context.fetch(descriptor) else { return }

            for row in rows {
                // v1 dateAdded was optional. If a user had a corrupt row with
                // no date, anchor it to "now" so sorting still works.
                if row.dateAdded.timeIntervalSince1970 == 0 {
                    row.dateAdded = Date()
                }
                // displayOrder was optional. Anything ≤ 0 from v1 is fine
                // to leave; we just sort on it. No change needed.

                // Brand-new fields all picked up their `= default` values
                // from the @Model declaration. Nothing to backfill.
                _ = row
            }

            try? context.save()
        }
    )
}
