//
//  CacheAnalyticsView.swift
//  simpleWeather
//
//  Created by William Castellano on 2/12/26.
//

import SwiftUI
import Network

struct CacheAnalyticsView: View {
    @Environment(\.dismiss) private var dismiss
    let cache: WeatherCache
    let networkMonitor: NetworkMonitor

    var body: some View {
        NavigationStack {
            List {
                // Network Status Section
                Section("Network Status") {
                    HStack {
                        Image(systemName: networkMonitor.isOnline ? "wifi" : "wifi.slash")
                            .foregroundColor(networkMonitor.isOnline ? .green : .red)
                        Text(networkMonitor.isOnline ? "Online" : "Offline")
                            .foregroundColor(networkMonitor.isOnline ? .green : .red)
                        Spacer()
                        if let connectionType = networkMonitor.connectionType {
                            Text(connectionTypeName(connectionType))
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                }

                // Cache Performance Section
                Section("Cache Performance") {
                    MetricRow(
                        title: "Hit Rate",
                        value: String(format: "%.1f%%", cache.analytics.hitRate),
                        systemImage: "gauge.high",
                        color: hitRateColor(cache.analytics.hitRate)
                    )

                    MetricRow(
                        title: "Total Hits",
                        value: "\(cache.analytics.totalHits)",
                        systemImage: "checkmark.circle.fill",
                        color: .green
                    )

                    MetricRow(
                        title: "Total Misses",
                        value: "\(cache.analytics.totalMisses)",
                        systemImage: "xmark.circle.fill",
                        color: .orange
                    )

                    MetricRow(
                        title: "Cache Writes",
                        value: "\(cache.analytics.totalWrites)",
                        systemImage: "arrow.down.circle.fill",
                        color: .blue
                    )

                    MetricRow(
                        title: "Evictions",
                        value: "\(cache.analytics.totalEvictions)",
                        systemImage: "trash.circle.fill",
                        color: .red
                    )
                }

                // Cache Size Section
                Section("Cache Status") {
                    HStack {
                        Text("Current Size")
                        Spacer()
                        Text("\(cache.currentSize) / 50")
                            .foregroundColor(.secondary)
                    }

                    ProgressView(value: Double(cache.currentSize), total: 50.0)
                        .tint(cacheSizeColor(cache.currentSize))

                    if let lastReset = cache.analytics.lastReset as Date? {
                        HStack {
                            Text("Last Reset")
                            Spacer()
                            Text(lastReset, format: .relative(presentation: .named))
                                .foregroundColor(.secondary)
                        }
                    }
                }

                // Actions Section
                Section {
                    Button(role: .destructive) {
                        cache.clearAll()
                    } label: {
                        Label("Clear All Cache", systemImage: "trash")
                    }

                    Button {
                        cache.resetAnalytics()
                    } label: {
                        Label("Reset Analytics", systemImage: "arrow.counterclockwise")
                    }
                }
            }
            .navigationTitle("Cache Analytics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Helper Functions

    private func hitRateColor(_ hitRate: Double) -> Color {
        switch hitRate {
        case 80...:
            return .green
        case 50..<80:
            return .orange
        default:
            return .red
        }
    }

    private func cacheSizeColor(_ size: Int) -> Color {
        let percentage = Double(size) / 50.0
        switch percentage {
        case 0..<0.5:
            return .green
        case 0.5..<0.8:
            return .orange
        default:
            return .red
        }
    }

    private func connectionTypeName(_ type: NWInterface.InterfaceType) -> String {
        switch type {
        case .wifi:
            return "Wi-Fi"
        case .cellular:
            return "Cellular"
        case .wiredEthernet:
            return "Ethernet"
        case .loopback:
            return "Loopback"
        case .other:
            return "Other"
        @unknown default:
            return "Unknown"
        }
    }
}

// MARK: - Supporting Views

struct MetricRow: View {
    let title: String
    let value: String
    let systemImage: String
    let color: Color

    var body: some View {
        HStack {
            Image(systemName: systemImage)
                .foregroundColor(color)
                .frame(width: 24)

            Text(title)

            Spacer()

            Text(value)
                .foregroundColor(.secondary)
                .fontWeight(.medium)
        }
    }
}

// MARK: - Preview

#Preview {
    CacheAnalyticsView(
        cache: .shared,
        networkMonitor: .shared
    )
}
