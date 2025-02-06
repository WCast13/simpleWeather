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
        VStack(alignment: .leading) {
            
            HStack {
                Text(location.city ?? "Unknown Location")
                    .font(.subheadline)
                
                Spacer()
                
                Text("\(String(format: "%.0f", weather.currentWeather.temperature.converted(to: .fahrenheit).value))°F")
                    .font(.subheadline)
                
            }
            .padding(.bottom, 4)
            
            HStack {
                Text("\(String(format: "%.0f", weather.currentWeather.cloudCover * 100))%")
                    .font(.caption)
                
                Text("\(String(format: "%.0f", weather.currentWeather.humidity * 100))%")
                    .font(.caption)
                    .padding(.leading, 8)
                
                Text("\(String(format: "%.0f", weather.currentWeather.wind.speed.converted(to: .milesPerHour).value)) mph")
                    .font(.caption)
                    .padding(.leading, 8)
            }
        }
    }
}

//#Preview {
//    StandardRowView()
//}
