//
//  LocationCardView.swift  (NEW — wires hybrid Home cards)
//  simpleWeather
//
//  This is the per-row view in the Locations list. It reads
//  `location.cardSize` and switches between a single-row compact
//  layout and an expanded layout with a 4-column data digest.
//
//  The set of datapoints shown in the expanded grid is intentionally
//  HARDCODED right now (temp, wind, UV, sunset). When WidgetSpec lands
//  in SchemaV3, replace `expandedRow` with one that reads
//  `location.homeWidgets` (a separate relationship from the Detail-view
//  widgets — Home and Detail customizations are independent surfaces).
//

import SwiftUI
import WeatherKit
import Playgrounds

struct LocationCardView: View {
    @Bindable var location: WeatherLocation
    /// Latest WeatherKit `Weather` for this location. Pass nil while loading.
    /// The card derives its existing UI from a snapshot adapter; future
    /// home-widgets can read fields off `weather` directly.
    let weather: Weather?
    /// Tap to navigate to the Detail view.
    let onTap: () -> Void

    private var snapshot: WeatherSnapshot? {
        guard let weather else { return nil }
        return WeatherSnapshot(from: weather)
    }
    
    private var currentWeather: CurrentWeather? {
        guard let weather else { return nil }
        return weather.currentWeather
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            
            
//            Text(weather?.hourlyForecast[6].p)
            
            
            
            headerRow
                .contentShape(Rectangle())
                .onTapGesture { onTap() }

            if location.cardSize == .expanded {
                Divider().padding(.vertical, 8)
                expandedRow
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, location.cardSize == .expanded ? 12 : 10)
        .background(.background.secondary, in: .rect(cornerRadius: 16))
        .overlay(alignment: .bottomTrailing) {
            // Chevron — flips card size in place
            Button {
                withAnimation(.snappy) {
                    location.cardSize = location.cardSize == .compact ? .expanded : .compact
                }
            } label: {
                Image(systemName: location.cardSize == .expanded
                      ? "chevron.up" : "chevron.down")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.tertiary)
                    .padding(8)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(location.cardSize == .expanded
                                ? "Collapse card" : "Expand card")
        }
    }

    // MARK: - Subviews

    private var headerRow: some View {
        HStack(spacing: 12) {
        
            Image(systemName: snapshot?.symbolName ?? "cloud.fill")
                .font(.system(size: location.cardSize == .expanded ? 28 : 24))
                .symbolRenderingMode(.multicolor)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(location.displayName)
                        .font(.headline)
                        .lineLimit(1)
                    typeBadge
                }
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Text(snapshot.map { "\(Int($0.tempF))°" } ?? "—")
                .font(.system(
                    size: location.cardSize == .expanded ? 30 : 26,
                    weight: .light,
                    design: .rounded
                ))
                .monospacedDigit()
        }
    }

    @ViewBuilder
    private var typeBadge: some View {
        switch location.locationType {
        case .permanent:
            EmptyView()
        case .temporary:
            HStack(spacing: 2) {
                Image(systemName: "calendar.badge.clock")
                Text("Ends \(location.removeAt ?? .now, format: .dateTime.month().day())")
            }
            .font(.caption2.weight(.medium))
            .padding(.horizontal, 6).padding(.vertical, 1)
            .foregroundStyle(.orange)
            .background(.orange.opacity(0.12), in: .capsule)
        case .calendarEvent:
            Text("Event")
                .font(.caption2.weight(.medium))
                .padding(.horizontal, 6).padding(.vertical, 1)
                .foregroundStyle(.teal)
                .background(.teal.opacity(0.12), in: .capsule)
        }
    }

    private var subtitle: String {
        let role: String = {
            if location.isFavorite                             { return "Home" }
            if location.locationType == .temporary             { return "Trip" }
            if location.locationType == .calendarEvent         { return "Event" }
            return "Saved"
        }()
        if let snap = snapshot {
            return "\(role) · \(snap.condition)"
        }
        return role
    }

    // MARK: - Expanded row (4-col digest)
    //
    // For v1: hardcode the four cells. When you add WidgetSpec for the
    // Home surface, swap this for a ForEach over a `homeWidgets` relationship.
    private var expandedRow: some View {
        HStack(alignment: .top, spacing: 8) {
            DigestCell(label: "Wind",
                       value: snapshot.map { "\(Int($0.windMph))" } ?? "—",
                       sub: snapshot?.windDirAbbr ?? "")
            DigestCell(label: "UV",
                       value: snapshot.map { "\(Int($0.uvIndex))" } ?? "—",
                       sub: snapshot?.uvCategory ?? "")
            DigestCell(label: "Feels",
                       value: snapshot.map { "\(Int($0.feelsLikeF))°" } ?? "—",
                       sub: "")
            DigestCell(label: "Sunset",
                       value: snapshot.map { Self.timeFmt.string(from: $0.sunsetDate) } ?? "—",
                       sub: "")
        }
    }

    private static let timeFmt: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "h:mma"
        f.amSymbol = "a"; f.pmSymbol = "p"
        return f
    }()
}

// MARK: - Digest cell --------------------------------------------------------

private struct DigestCell: View {
    let label: String
    let value: String
    let sub: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label.uppercased())
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.tertiary)
                .tracking(0.6)
            Text(value)
                .font(.system(.title3, design: .rounded).weight(.regular))
                .monospacedDigit()
            if !sub.isEmpty {
                Text(sub)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - WeatherSnapshot ----------------------------------------------------
//
// Minimal shape this view consumes. Adapter from WeatherKit's `Weather`
// lives in WeatherViewModel.swift to keep the WeatherKit dependency out
// of this view file.
//
// Kept as a value type because it lives in @State / a fetch cache, not in
// SwiftData. WeatherKit data is ephemeral; we don't store it across launches.

struct WeatherSnapshot: Equatable, Sendable {
    var tempF: Double
    var feelsLikeF: Double
    var condition: String
    var symbolName: String
    var windMph: Double
    var windDirAbbr: String
    var uvIndex: Int
    var uvCategory: String
    var sunsetDate: Date
}
