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
    
    var body: some View {
        
        VStack {
            Text(title)
                .padding(.bottom, 1)
            Text(verbatim: String(describing: dataItem))
        }
        .font(.caption)
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
