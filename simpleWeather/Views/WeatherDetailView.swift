//
//  WeatherDetailView.swift  (Phase 4c — read-only widget grid)
//  simpleWeather
//
//  v2 keystone: each location has a per-location grid of widgets that the
//  user customizes. Phase 4c lays out the grid read-only with placeholder
//  cells; Phase 4d ports per-widget renderers from the design refs;
//  Phase 4e adds drag-reorder / resize / + add edit mode.
//
//  The `weather` argument stays in the signature even though Phase 4c's
//  placeholder cells don't consume it — Phase 4d's real renderers will.
//

import SwiftUI
import WeatherKit
import SwiftData

struct WeatherDetailView: View {
    let weather: Weather
    @Bindable var location: WeatherLocation

    @Environment(\.modelContext) private var modelContext
    @State private var showingLibrary = false

    private var repo: LocationRepository {
        LocationRepository(modelContext: modelContext)
    }

    private var widgets: [WidgetSpec] { location.widgetsInOrder }

    var body: some View {
        ZStack {
            DetailSkyBackground()

            if widgets.isEmpty {
                emptyState
            } else {
                widgetGrid
            }
        }
        .navigationTitle(location.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Menu {
                    Section("Apply layout preset") {
                        ForEach(LayoutPresets.all) { preset in
                            Button {
                                withAnimation(.snappy) {
                                    repo.applyPreset(preset, to: location)
                                }
                            } label: {
                                Label(preset.displayName, systemImage: preset.symbolName)
                            }
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }

                Button {
                    showingLibrary = true
                } label: {
                    Image(systemName: "plus")
                }

                // Placeholder Edit affordance — Phase 4e wires it.
                Button("Edit") {}
                    .disabled(true)
            }
        }
        .sheet(isPresented: $showingLibrary) {
            WidgetLibrarySheet { kind in
                withAnimation(.snappy) {
                    _ = repo.addWidget(kind, to: location)
                }
            }
        }
    }

    // MARK: - Empty state

    private var emptyState: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Image(systemName: "rectangle.3.group")
                        .font(.system(size: 48, weight: .light))
                        .foregroundStyle(.tertiary)
                    Text("Customize \(location.displayName)")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(Color(red: 0x0E/255, green: 0x1A/255, blue: 0x2B/255))
                    Text("Pick a starting layout to fill this screen with the weather data you care about. You can rearrange and swap widgets later from the Edit menu.")
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Color(red: 0x0E/255, green: 0x1A/255, blue: 0x2B/255).opacity(0.55))
                        .padding(.horizontal)
                }
                .padding(.top, 60)

                VStack(spacing: 12) {
                    ForEach(LayoutPresets.all) { preset in
                        Button {
                            withAnimation(.snappy) {
                                repo.applyPreset(preset, to: location)
                            }
                        } label: {
                            PresetRow(preset: preset)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Widget grid (4-column, read-only)
    //
    // For now packed greedily by width. Heights are visual only (no row-spanning
    // widgets in SwiftUI's `Grid` — `gridCellRows` doesn't exist). 4x2 / 2x2
    // widgets render visually taller via fixed cell minHeight, but neighbors
    // in the same Grid row size to the tallest cell. Phase 4e will move to a
    // proper 2D-packing custom Layout when drag/resize gestures need it.

    private var widgetGrid: some View {
        ScrollView {
            Grid(horizontalSpacing: 8, verticalSpacing: 8) {
                ForEach(packedRows.indices, id: \.self) { rowIdx in
                    GridRow {
                        ForEach(packedRows[rowIdx]) { widget in
                            WidgetCellPlaceholder(widget: widget)
                                .gridCellColumns(widget.size.width)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }

    /// Greedy width-only packing into 4-column rows. Works perfectly for the
    /// just-weather and boating presets (they're designed to tile cleanly);
    /// photography leaves a 2-column gap on one row, which is faithful to its
    /// preset definition.
    private var packedRows: [[WidgetSpec]] {
        let columnCount = 4
        var rows: [[WidgetSpec]] = []
        var current: [WidgetSpec] = []
        var used = 0
        for widget in widgets {
            let w = widget.size.width
            if used + w > columnCount {
                rows.append(current)
                current = [widget]
                used = w
            } else {
                current.append(widget)
                used += w
                if used == columnCount {
                    rows.append(current)
                    current = []
                    used = 0
                }
            }
        }
        if !current.isEmpty { rows.append(current) }
        return rows
    }
}

// MARK: - Sky-to-haze gradient ------------------------------------------------

/// Detail-view background per the proto spec:
/// `linear-gradient(180deg, #B8DDF5 0%, #DCEDF8 35%, #F4F6F8 100%)`
private struct DetailSkyBackground: View {
    var body: some View {
        LinearGradient(
            stops: [
                .init(color: Color(red: 0xB8/255, green: 0xDD/255, blue: 0xF5/255), location: 0.00),
                .init(color: Color(red: 0xDC/255, green: 0xED/255, blue: 0xF8/255), location: 0.35),
                .init(color: Color(red: 0xF4/255, green: 0xF6/255, blue: 0xF8/255), location: 1.00),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}

// MARK: - Widget cell placeholder --------------------------------------------

/// Phase 4c stand-in cell. Each catalog kind uses the same generic visual
/// (label + size badge + "Phase 4d" tag). Phase 4d replaces this with a
/// switch over `widget.kind` rendering each widget's real content.
struct WidgetCellPlaceholder: View {
    let widget: WidgetSpec

    private static let primary = Color(red: 0x0E/255, green: 0x1A/255, blue: 0x2B/255)
    private static let dim     = Color(red: 0x0E/255, green: 0x1A/255, blue: 0x2B/255).opacity(0.55)
    private static let faint   = Color(red: 0x0E/255, green: 0x1A/255, blue: 0x2B/255).opacity(0.30)

    var body: some View {
        let entry = widget.catalogEntry

        VStack(alignment: .leading, spacing: 6) {
            HStack {
                if let entry {
                    Image(systemName: entry.symbolName)
                        .font(.caption)
                        .foregroundStyle(Self.dim)
                    Text(entry.displayName.uppercased())
                        .font(.caption2.weight(.semibold))
                        .tracking(0.6)
                        .foregroundStyle(Self.faint)
                        .lineLimit(1)
                }
                Spacer()
                Text(widget.sizeRaw)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(Self.faint)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Self.faint.opacity(0.15), in: .capsule)
            }

            Spacer()

            HStack {
                Spacer()
                Text("Phase 4d")
                    .font(.caption2)
                    .foregroundStyle(Self.faint)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: cellHeight, alignment: .topLeading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(Color.white.opacity(0.5), lineWidth: 0.5)
        }
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }

    /// Approximate the proto's row-height grid: 84pt per row unit.
    private var cellHeight: CGFloat {
        CGFloat(widget.size.height) * 84
    }
}

// MARK: - Preset row (empty state) -------------------------------------------

private struct PresetRow: View {
    let preset: LayoutPreset

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: preset.symbolName)
                .font(.title2)
                .foregroundStyle(.tint)
                .frame(width: 44, height: 44)
                .background(.tint.opacity(0.12), in: .circle)

            VStack(alignment: .leading, spacing: 2) {
                Text(preset.displayName)
                    .font(.headline)
                    .foregroundStyle(Color(red: 0x0E/255, green: 0x1A/255, blue: 0x2B/255))
                Text(preset.summary)
                    .font(.caption)
                    .foregroundStyle(Color(red: 0x0E/255, green: 0x1A/255, blue: 0x2B/255).opacity(0.55))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color(red: 0x0E/255, green: 0x1A/255, blue: 0x2B/255).opacity(0.30))
        }
        .padding(14)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.white.opacity(0.5), lineWidth: 0.5)
        }
    }
}
