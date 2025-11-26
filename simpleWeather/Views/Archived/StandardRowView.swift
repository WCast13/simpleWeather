//
//  StandardRowView.swift
//  simpleWeather
//
//  Created by William Castellano on 2/6/25.
//

import SwiftUI
import WeatherKit

struct StandardRowView: View {
    
    var weather: Weather
    var location: WeatherLocation
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                
                Text(location.city ?? "Unknown Location")
                    .font(.headline)
                
                HStack {
                    VStack(alignment: .leading) {
                        Text("\(String(format: "%.0f", weather.currentWeather.cloudCover * 100))%")
                            .font(.caption)
                        Text("Cloud Cover")
                            .font(.caption2)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("\(String(format: "%.0f", weather.currentWeather.humidity * 100))%")
                            .font(.caption)
                        Text("Humidity")
                            .font(.caption2)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("\(String(format: "%.0f", weather.currentWeather.wind.speed.converted(to: .milesPerHour).value)) mph")
                            .font(.caption)
                        Text("Wind")
                            .font(.caption2)
                        
                    }
                    
                    VStack(alignment: .leading) {
                        Text("\(String(format: "%.0f", weather.currentWeather.cloudCover * 100))%")
                            .font(.caption)
                        Text("Cloud Cover")
                            .font(.caption2)
                        
                    }
                }
            }
            
            Spacer()
            
            VStack(alignment: .center) {
                Text("\(String(format: "%.0f", weather.currentWeather.temperature.converted(to: .fahrenheit).description))")
                    .font(.body)
                Spacer()
                Image(systemName: weather.currentWeather.symbolName)
            }
            .padding(.vertical)
        }
    }
}
