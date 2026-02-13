//
//  TimePickerView.swift
//  simpleWeather
//
//  Created by William Castellano on 2/12/26.
//

import SwiftUI
import WeatherKit

/// Button to show time picker
struct TimePickerButton: View {
    let currentTimeLabel: String
    let action: () -> Void

    var body: some View {
        Button {
            action()
        } label: {
            HStack {
                Text(currentTimeLabel)
                    .font(.subheadline)
                Image(systemName: "chevron.down")
                    .font(.caption)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

/// Sheet view for picking time (hourly or daily)
struct TimePickerSheet: View {
    @Binding var selectedDataType: WeatherDataType
    @Binding var hourlyIndex: Int
    @Binding var dailyIndex: Int
    @Binding var selectedDay: Date
    @Binding var selectedHourOfDay: Int

    let weather: Weather
    let onDismiss: () -> Void

    var body: some View {
        NavigationStack {
            VStack {
                if selectedDataType == .hourly {
                    HourlyPickerView(
                        selectedDay: $selectedDay,
                        selectedHourOfDay: $selectedHourOfDay,
                        hourlyIndex: $hourlyIndex,
                        weather: weather
                    )
                } else if selectedDataType == .daily {
                    DailyPickerView(
                        dailyIndex: $dailyIndex,
                        weather: weather
                    )
                }
            }
            .navigationTitle(selectedDataType == .hourly ? "Select Hour" : "Select Day")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        onDismiss()
                    }
                }
            }
        }
        .presentationDetents([.height(300)])
    }
}

/// Hourly picker with day and hour columns
struct HourlyPickerView: View {
    @Binding var selectedDay: Date
    @Binding var selectedHourOfDay: Int
    @Binding var hourlyIndex: Int

    let weather: Weather

    var body: some View {
        let uniqueDays = WeatherDataTransformer.getUniqueDays(from: weather)
        let hoursInDay = WeatherDataTransformer.getHoursForDay(selectedDay, from: weather)

        HStack(spacing: 0) {
            // Day Picker
            Picker("Day", selection: $selectedDay) {
                ForEach(uniqueDays, id: \.self) { day in
                    Text(day.formatted(.dateTime.weekday(.wide)))
                        .tag(day)
                }
            }
            .pickerStyle(.wheel)
            .onChange(of: selectedDay) { oldValue, newValue in
                // Reset to first hour of the new day
                let hours = WeatherDataTransformer.getHoursForDay(newValue, from: weather)
                if let firstHour = hours.first {
                    selectedHourOfDay = Calendar.current.component(.hour, from: firstHour.date)
                    updateHourlyIndex()
                }
            }

            // Hour Picker
            Picker("Hour", selection: $selectedHourOfDay) {
                ForEach(hoursInDay, id: \.date) { hourWeather in
                    let hour = Calendar.current.component(.hour, from: hourWeather.date)
                    Text(hourWeather.date.formatted(.dateTime.hour()))
                        .tag(hour)
                }
            }
            .pickerStyle(.wheel)
            .onChange(of: selectedHourOfDay) { oldValue, newValue in
                updateHourlyIndex()
            }
        }
        .onAppear {
            initializeHourlyPicker()
        }
    }

    /// Initialize hourly picker with current hourlyIndex
    private func initializeHourlyPicker() {
        guard hourlyIndex < weather.hourlyForecast.count else { return }

        let selectedHourWeather = weather.hourlyForecast[hourlyIndex]
        let calendar = Calendar.current

        // Set selected day to the day of the current hourlyIndex
        let dayComponents = calendar.dateComponents([.year, .month, .day], from: selectedHourWeather.date)
        if let dayStart = calendar.date(from: dayComponents) {
            selectedDay = dayStart
        }

        // Set selected hour
        selectedHourOfDay = calendar.component(.hour, from: selectedHourWeather.date)
    }

    /// Update hourlyIndex based on selected day and hour
    private func updateHourlyIndex() {
        let calendar = Calendar.current

        for (index, hourWeather) in weather.hourlyForecast.enumerated() {
            let hourDay = calendar.dateComponents([.year, .month, .day], from: hourWeather.date)
            let targetDay = calendar.dateComponents([.year, .month, .day], from: selectedDay)
            let hour = calendar.component(.hour, from: hourWeather.date)

            if hourDay == targetDay && hour == selectedHourOfDay {
                hourlyIndex = index
                break
            }
        }
    }
}

/// Daily picker view
struct DailyPickerView: View {
    @Binding var dailyIndex: Int

    let weather: Weather

    var body: some View {
        Picker("Select Day", selection: $dailyIndex) {
            ForEach(Array(weather.dailyForecast.enumerated()), id: \.offset) { index, dayWeather in
                Text(WeatherDataTransformer.timeLabel(for: index, dataType: .daily, weather: weather))
                    .tag(index)
            }
        }
        .pickerStyle(.wheel)
    }
}

// MARK: - Previews

#Preview("Time Picker Button") {
    TimePickerButton(currentTimeLabel: "12 PM") {
        print("Tapped")
    }
}
