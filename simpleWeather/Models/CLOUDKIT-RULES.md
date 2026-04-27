# CloudKit + SwiftData rules of the road

These are the constraints SwiftData enforces when you back a `ModelConfiguration`
with `cloudKitDatabase: .private(...)`. Break one and you get an opaque error
like "missing inverse relationship" or — worse — silent sync failure where the
local store works but nothing reaches iCloud.

## The five rules

1. **Every stored property must have a default value.**
   `var city: String = ""`, `var dateAdded: Date = Date()`, etc.
   Optionals (`Date?`) are fine — the optional itself is the default.
   What's not allowed: `var city: String` with no `=` — CloudKit can't
   represent "required, no default."

2. **No `@Attribute(.unique)`.**
   CloudKit does not enforce uniqueness. SwiftData refuses to declare it.
   Enforce uniqueness in code (e.g. dedupe by lat/lon at insert time).

3. **All relationships need an inverse.**
   When you add `WidgetSpec` later:
   ```swift
   @Relationship(deleteRule: .cascade, inverse: \WidgetSpec.location)
   var widgets: [WidgetSpec] = []
   ```
   And on `WidgetSpec`: `var location: WeatherLocation?`. Both sides.
   The inverse is what lets CloudKit reconstruct the graph from a flat
   record stream.

4. **Ordered relationships aren't safe — use an Int.**
   CloudKit doesn't preserve ordering across devices reliably. So we don't
   ask it to. Each `WeatherLocation` has `displayOrder: Int`, and on every
   reorder we rewrite all of them. SwiftData syncs ints fine; arrays
   reordered in place don't.

5. **All relationships must be optional — both sides.**
   `var location: WeatherLocation?` on the owned (to-one) side.
   AND `var widgets: [WidgetSpec]?` on the owning (to-many) side. CoreData
   refuses to load the store otherwise with "CloudKit integration requires
   that all relationships be optional" — and this includes the to-many
   parent side, not just to-one inverses, even though `[X] = []` looks
   syntactically reasonable. Use a `…InOrder` computed accessor to fold
   the optional back to a stable non-optional array for callers
   (see `WeatherLocation.widgetsInOrder`).

## Operational gotchas

- **Test on device, not simulator.** The simulator's CloudKit support is
  flaky enough that you'll waste hours chasing bugs that don't exist.
  Use the `-disableCloudKit` launch arg for sim work.

- **Two devices, one Apple ID, both signed in.** Otherwise sync looks like
  it's broken. Settings → [your name] → iCloud → SimpleWeather → On.

- **First sync is slow.** Up to a minute for the schema to land on the
  server side. Pull-to-refresh in the CloudKit Console (developer.apple.com)
  to confirm the record types showed up.

- **Schema changes deploy to "Development" first.** When you add `WidgetSpec`,
  CloudKit Console → Schema → Deploy to Production is a manual step
  before TestFlight users can sync.

- **Migration runs once per device.** If you mess up the v1→v2 migration on
  your dev device, delete the app + reinstall to re-run it. There is no
  "redo migration" button.

## When sync silently breaks

Symptoms: writes work locally, never reach the other device.
Check, in order:
1. Capabilities tab — iCloud + CloudKit both checked, container name matches.
2. Background Modes — Remote notifications checked.
3. CloudKit Console — record types exist; check Logs for permission errors.
4. Both devices on the same Apple ID + iCloud Drive on.
5. `defaults write` to enable verbose CloudKit logging on device:
   `xcrun simctl spawn booted log config --mode 'level:debug' --subsystem com.apple.cloudkit`
   (only useful on macOS sim — on device, attach Console.app).
