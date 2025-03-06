//
//  WeatherDetailView.swift
//  simpleWeather
//
//  Created by William Castellano on 2/7/25.
//

import SwiftUI
import WeatherKit

struct WeatherDetailView: View {
    let weather: Weather
    let location: WeatherLocation
    
    var body: some View {
        VStack(alignment: .leading) {
            VStack(alignment: .leading) {
                Text(location.city ?? "")
                Text(location.state ?? "")
                Text(location.zipCode ?? "")
                Text("\(location.latitude)")
                Text("\(location.longitude)")
            }
            Divider()
            VStack(alignment: .leading) {
                DetailLineItem(title: "Date", dataItem: weather.currentWeather.date)
                DetailLineItem(title: "Temperature", dataItem: "\(String(format: "%.0f", weather.currentWeather.temperature.converted(to: .fahrenheit).value))°F")
                DetailLineItem(title: "Feels Like", dataItem: "\(String(format: "%.0f", weather.currentWeather.apparentTemperature.converted(to: .fahrenheit).value))°F")
                DetailLineItem(title: "Humidity", dataItem: "\(String(format: "%.0f", weather.currentWeather.humidity * 100))%")
                DetailLineItem(title: "Cloud Cover", dataItem: "\(String(format: "%.0f", weather.currentWeather.cloudCover * 100))%")
                DetailLineItem(title: "Wind Speed", dataItem: "\(String(format: "%.0f", weather.currentWeather.wind.speed.converted(to: .milesPerHour).value)) mph")
                DetailLineItem(title: "Wind Direction", dataItem: weather.currentWeather.wind.direction)
                DetailLineItem(title: "Wind Direction", dataItem: weather.currentWeather.wind.compassDirection.abbreviation)
                
                DetailLineItem(title: "Condition", dataItem: weather.currentWeather.condition.description)
                DetailLineItem(title: "Dew Point", dataItem: "\(String(format: "%.0f", weather.currentWeather.dewPoint.converted(to: .fahrenheit).value))°F")
                DetailLineItem(title: "Dew Point", dataItem: weather.currentWeather.dewPoint.converted(to: .fahrenheit).description)
                DetailLineItem(title: "Is Daylight", dataItem: weather.currentWeather.isDaylight)
                DetailLineItem(title: "Precipitation Intensity", dataItem: weather.currentWeather.precipitationIntensity.converted(to: .milesPerHour).description)
                DetailLineItem(title: "Pressure", dataItem: weather.currentWeather.pressure.converted(to: .millibars))
                DetailLineItem(title: "", dataItem: weather.currentWeather.pressureTrend)
                HStack {
                    Text("Image")
                    Spacer()
                    Image(systemName: weather.currentWeather.symbolName)
                }
                .padding(.horizontal)
                DetailLineItem(title: "Visibility", dataItem: weather.currentWeather.visibility.converted(to: .miles))
                DetailLineItem(title: "", dataItem: weather.currentWeather.uvIndex.category)
                DetailLineItem(title: "", dataItem: weather.currentWeather.uvIndex.value)
                DetailLineItem(title: "", dataItem: weather.currentWeather.cloudCoverByAltitude)
            }
            Divider()
            
            VStack {
                DetailLineItem(title: "", dataItem: weather.dailyForecast.first?.wind.speed)
                DetailLineItem(title: "", dataItem: weather.dailyForecast.first?.highTemperature)
                DetailLineItem(title: "", dataItem: weather.dailyForecast.first?.lowTemperature)
                DetailLineItem(title: "", dataItem: weather.dailyForecast.forecast)
            }
            
            
        }
    }
}

// Preview
//struct WeatherDetailView_Previews: PreviewProvider {
//    static var previews: some View {
//        WeatherDetailView(weatherManager: WeatherKitManager(), locationName: "New York, NY")
//    }
//}
