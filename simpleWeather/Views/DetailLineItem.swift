//
//  DetailLineItem.swift
//  simpleWeather
//
//  Created by William Castellano on 2/8/25.
//

import SwiftUI
import WeatherKit

struct DetailLineItem<T>: View {
    let title: String
    let dataItem: T
    
    var body: some View {
        
        VStack {
            Text(title)
                .padding(.bottom, 1)
            Text("\(dataItem)")
        }
        .font(.caption)
    }
}
