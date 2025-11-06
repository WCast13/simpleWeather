//
//  DetailsScrollView.swift
//  simpleWeather
//
//  Created by William Castellano on 2/11/25.
//

import SwiftUI
import WeatherKit

struct StandaredRowDetailsView: View {
    var weather: Weather
    
    var body: some View {
        VStack(alignment: .center) {
            HStack {
                WeatherDataItem(title: "Feels Like", dataItem: "\(String(format: "%.0f", weather.currentWeather.apparentTemperature.converted(to: .fahrenheit).value))°")
                WeatherDataItem(title: "Clouds", dataItem: "\(String(format: "%.0f", weather.currentWeather.cloudCover * 100))%")
                WeatherDataItem(title: "Wind Speed", dataItem: "\(String(format: "%.0f", weather.currentWeather.wind.speed.converted(to: .milesPerHour).value)) mph")
                WeatherDataItem(title: "Direction", dataItem: weather.currentWeather.wind.compassDirection.abbreviation)
                WeatherDataItem(title: "Humidity", dataItem: "\(String(format: "%.0f", weather.currentWeather.humidity * 100))%")
            }
            .padding(.bottom, 4)
        }
    }
}

#Preview {
//    DetailsScrollView()
}
