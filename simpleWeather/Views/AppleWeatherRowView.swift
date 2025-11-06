//
//  AppleWeatherRowView.swift
//  simpleWeather
//
//  Created by William Castellano on 2/10/25.
//

import SwiftUI
import Foundation
import WeatherKit

struct AppleWeatherRowView: View {
    var weather: Weather
    var location: WeatherLocation
    
    var columns = [GridItem(.adaptive(minimum: 40, maximum: .infinity))]
    
    var body: some View {
        
        
        HStack {
            VStack(alignment: .leading) {
                Text("\(location.city ?? "")")
                    .font(.headline)
                Text("\(weather.currentWeather.date.formatted(date: .omitted, time: .shortened))")
                    .font(.caption)
            }
            
            Spacer()
            
            Text("\(weather.currentWeather.condition.description)")
                .font(.caption)
            
            Spacer()
            
            VStack(alignment: .center) {
                Text("\(String(format: "%.0f", weather.currentWeather.temperature.converted(to: .fahrenheit).value))°")
                    .font(.largeTitle)
                
                Text("H: \(String(format: "%.0f", weather.dailyForecast.first?.highTemperature.converted(to: .fahrenheit).value ?? 0))° L: \(String(format: "%.0f", weather.dailyForecast.first?.lowTemperature.converted(to: .fahrenheit).value ?? 0))°")
                    .font(.caption)
            }
        }
    }
}
