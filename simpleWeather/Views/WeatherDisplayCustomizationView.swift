//
//  WeatherDisplayCustomizationView.swift
//  simpleWeather
//
//  Created by William Castellano on 2/13/26.
//

import SwiftUI
import SwiftData

struct WeatherDisplayCustomizationView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let location: WeatherLocation
    @State private var preferences: WeatherDisplayPreferences

    init(location: WeatherLocation) {
        self.location = location
        self._preferences = State(initialValue: location.displayPreferences)
    }

    var body: some View {
        NavigationStack {
            List {
                // Presets Section
                Section("Quick Presets") {
                    PresetButton(title: "Minimal", description: "Temperature only", icon: "minus.circle") {
                        preferences = .minimal
                    }

                    PresetButton(title: "Essential", description: "Key metrics only", icon: "star.circle") {
                        preferences = .essential
                    }

                    PresetButton(title: "Detailed", description: "All information", icon: "circle.grid.3x3") {
                        preferences = .detailed
                    }

                    PresetButton(title: "Default", description: "Reset to default", icon: "arrow.counterclockwise") {
                        preferences = .default
                    }
                }

                // Display Style Section
                Section("Display Style") {
                    Picker("Row Style", selection: $preferences.rowStyle) {
                        ForEach(WeatherRowStyle.allCases, id: \.self) { style in
                            Text(style.rawValue).tag(style)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                // Main Row Options
                Section("Main Row Options") {
                    Toggle("Show Condition Icon", isOn: $preferences.showConditionIcon)
                    Toggle("Show High/Low", isOn: $preferences.showHighLow)
                    Toggle("Show Last Updated", isOn: $preferences.showLastUpdated)
                }

                // Grid Options
                Section("Weather Grid") {
                    Toggle("Show Weather Grid", isOn: $preferences.showGrid)

                    if preferences.showGrid {
                        NavigationLink {
                            MetricsCustomizationView(preferences: $preferences)
                        } label: {
                            HStack {
                                Text("Customize Metrics")
                                Spacer()
                                Text("\(preferences.visibleMetrics.count) visible")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }
                        }
                    }
                }

                // Preview Section
                Section("Preview") {
                    Text("Preview how your customization will look in the main list")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    // Note: In a real implementation, you'd show a preview of the weather row here
                    HStack {
                        Image(systemName: preferences.showConditionIcon ? "sun.max.fill" : "thermometer")
                            .foregroundColor(.orange)
                        VStack(alignment: .leading) {
                            Text(location.displayName)
                                .font(.headline)
                            if preferences.showLastUpdated {
                                Text("Updated just now")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text("72°")
                                .font(.title2)
                                .fontWeight(.medium)
                            if preferences.showHighLow {
                                Text("H:75° L:65°")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("Customize Display")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        savePreferences()
                    }
                }
            }
        }
    }

    // MARK: - Private Methods

    private func savePreferences() {
        location.displayPreferences = preferences
        do {
            try modelContext.save()
        } catch {
            print("Failed to save display preferences: \(error.localizedDescription)")
        }
        dismiss()
    }
}

// MARK: - Supporting Views

struct PresetButton: View {
    let title: String
    let description: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button {
            action()
        } label: {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                    .frame(width: 24)

                VStack(alignment: .leading) {
                    Text(title)
                        .foregroundColor(.primary)
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
        }
    }
}

struct MetricsCustomizationView: View {
    @Binding var preferences: WeatherDisplayPreferences

    var body: some View {
        List {
            Section("Select Metrics to Display") {
                ForEach(WeatherMetric.allCases) { metric in
                    Toggle(isOn: binding(for: metric)) {
                        HStack {
                            Image(systemName: metric.systemImage)
                                .frame(width: 24)
                                .foregroundColor(.blue)
                            Text(metric.rawValue)
                        }
                    }
                }
            }

            if !preferences.visibleMetrics.isEmpty {
                Section("Reorder Metrics") {
                    ForEach(preferences.metricsOrder.filter { preferences.visibleMetrics.contains($0) }) { metric in
                        HStack {
                            Image(systemName: metric.systemImage)
                                .frame(width: 24)
                                .foregroundColor(.blue)
                            Text(metric.rawValue)
                            Spacer()
                            Image(systemName: "line.3.horizontal")
                                .foregroundColor(.secondary)
                        }
                    }
                    .onMove { source, destination in
                        var visibleOrder = preferences.metricsOrder.filter { preferences.visibleMetrics.contains($0) }
                        visibleOrder.move(fromOffsets: source, toOffset: destination)

                        // Rebuild metricsOrder maintaining hidden items
                        var newOrder: [WeatherMetric] = []
                        for metric in WeatherMetric.allCases {
                            if preferences.visibleMetrics.contains(metric) {
                                if let visible = visibleOrder.first {
                                    newOrder.append(visible)
                                    visibleOrder.removeFirst()
                                }
                            }
                        }
                        preferences.metricsOrder = newOrder.isEmpty ? WeatherMetric.allCases : newOrder
                    }
                }
                .environment(\.editMode, .constant(.active))
            }

            Section {
                Button("Select All") {
                    preferences.visibleMetrics = WeatherMetric.allCases
                }

                Button("Clear All") {
                    preferences.visibleMetrics = []
                }
                .foregroundColor(.red)
            }
        }
        .navigationTitle("Customize Metrics")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func binding(for metric: WeatherMetric) -> Binding<Bool> {
        Binding(
            get: { preferences.isMetricVisible(metric) },
            set: { isVisible in
                if isVisible {
                    if !preferences.visibleMetrics.contains(metric) {
                        preferences.visibleMetrics.append(metric)
                    }
                } else {
                    preferences.visibleMetrics.removeAll { $0 == metric }
                }
            }
        )
    }
}

// MARK: - Preview

#Preview {
    WeatherDisplayCustomizationView(
        location: WeatherLocation(
            city: "San Francisco",
            state: "CA",
            latitude: 37.7749,
            longitude: -122.4194
        )
    )
    .modelContainer(for: WeatherLocation.self, inMemory: true)
}
