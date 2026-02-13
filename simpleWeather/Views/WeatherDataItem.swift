//
//  DetailLineItem.swift
//  simpleWeather
//
//  Created by William Castellano on 2/8/25.
//

import SwiftUI
import WeatherKit

struct WeatherDataItem<T>: View {
    let title: String
    let dataItem: T
    var icon: String?
    var accentColor: Color?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Title with optional icon
            HStack(spacing: 4) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.caption2)
                        .foregroundColor(accentColor ?? .secondary)
                }
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            // Value
            Text(verbatim: String(describing: dataItem))
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(accentColor ?? .primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 20) {
        WeatherDataItem(title: "Temperature", dataItem: 72.5)
        WeatherDataItem(title: "Humidity", dataItem: "65%")
        WeatherDataItem(title: "Wind Speed", dataItem: 12)
        WeatherDataItem(title: "Condition", dataItem: "Partly Cloudy")
    }
    .padding()
}
