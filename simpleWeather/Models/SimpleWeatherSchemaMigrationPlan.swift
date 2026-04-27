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
        [SchemaV1.self, SchemaV2.self, SchemaV3.self]
    }

    static var stages: [MigrationStage] {
        [migrateV1toV2, migrateV2toV3]
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
            // Post-migration cleanup: walk every new v2 row and patch any field
            // that wound up nil/zero because v1 stored it as Optional. The
            // context speaks v2 at this stage, so we fetch the v2-frozen
            // class (`SchemaV2.WeatherLocation`).
            let descriptor = FetchDescriptor<SchemaV2.WeatherLocation>()
            guard let rows = try? context.fetch(descriptor) else { return }

            for row in rows {
                // v1 dateAdded was optional. If a user had a corrupt row with
                // no date, anchor it to "now" so sorting still works.
                if row.dateAdded.timeIntervalSince1970 == 0 {
                    row.dateAdded = Date()
                }
                // displayOrder was optional. Anything ≤ 0 from v1 is fine
                // to leave; we just sort on it. No change needed.

                // Brand-new v2 fields all picked up their `= default` values
                // from the @Model declaration. Nothing to backfill.
                _ = row
            }

            try? context.save()
        }
    )

    // MARK: - V2 → V3 ----------------------------------------------------------

    /// Custom (with empty hooks) rather than lightweight. Lightweight refuses
    /// to handle the implicit class rename across versions
    /// (`WeatherLocation` on the v2 disk → `SchemaV2.WeatherLocationV2` in
    /// declarations → top-level `WeatherLocation` in v3). Custom lets
    /// SwiftData treat the rename as an explicit version transition.
    ///
    /// Structurally v3 only adds the `widgets` relationship (default empty)
    /// and introduces `WidgetSpec`. No row work needed.
    static let migrateV2toV3 = MigrationStage.custom(
        fromVersion: SchemaV2.self,
        toVersion: SchemaV3.self,
        willMigrate: { _ in
            // Pre-flight: nothing to read from v2.
        },
        didMigrate: { _ in
            // Post-flight: nothing to backfill on v3.
        }
    )
}
