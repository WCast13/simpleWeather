//
//  AddLocationView.swift
//  simpleWeather
//
//  Created by William Castellano on 2/3/25.
//

import SwiftUI
import SwiftData
import CoreLocation


struct AddLocationView: View {
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var locationInput: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            VStack {
                TextField("Enter City or Zip Code", text: $locationInput)
                    .textFieldStyle(.roundedBorder)
                    .padding()
                
                if isLoading {
                    ProgressView()
                } else if let errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                }
                
                Button("Add Location") {
                    Task {
                        await addLocation()
                    }
                }
                .buttonStyle(.borderedProminent)
                .padding()
                
                Spacer()
            }
            .padding()
            .navigationTitle("Add Location")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func addLocation() async {
        guard !locationInput.isEmpty else {
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let (latitude, longitude, city, state) = try await geocodeLocation(locationInput)
            let newLocation = WeatherLocation(city: city, state: state, zipCode: locationInput, latitude: latitude, longitude: longitude)
            modelContext.insert(newLocation)
            dismiss()
        } catch {
            errorMessage = "Could not find location. Please try again."
        }
        
        isLoading = false
    }
}

/// Converts a city/state or ZIP code into coordinates.
func geocodeLocation(_ address: String) async throws -> (Double, Double, String?, String?) {
    let geocoder = CLGeocoder()
    
    return try await withCheckedThrowingContinuation { continuation in
        geocoder.geocodeAddressString(address) { placemarks, error in
            if let error = error {
                continuation.resume(throwing: error)
                return
            }
            
            guard let placemark = placemarks?.first,
                  let location = placemark.location else {
                continuation.resume(throwing: NSError(domain: "Geocoding", code: 1, userInfo: nil))
                return
            }
            
            let latitude = location.coordinate.latitude
            let longitude = location.coordinate.longitude
            let city = placemark.locality
            let state = placemark.administrativeArea
            
            continuation.resume(returning: (latitude, longitude, city, state))
        }
    }
}

#Preview {
    AddLocationView()
}
