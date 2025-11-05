//
//  GeocodeManager.swift
//  simpleWeather
//
//  Created by William Castellano on 11/5/25.
//

import Foundation
import MapKit

class GeocodeManager: ObservableObject {
    @Published var coordinates: CLLocation?
    @Published var address: String = ""
    @Published var placemark: CLPlacemark?
    @Published var errorMessage: String?
    
    init(coordinates: CLLocation? = nil, address: String, placemark: CLPlacemark? = nil, errorMessage: String? = nil) {
        self.coordinates = coordinates
        self.address = address
        self.placemark = placemark
        self.errorMessage = errorMessage
    }
    
    func reverseGeocode(coordinates: CLLocation) async -> MKMapItem? {
        var location: MKMapItem? = nil
        if let request = MKReverseGeocodingRequest(location: coordinates) {
            do {
                let mapItems = try await request.mapItems
                location = mapItems.first

            } catch {
                print("Error reverse geocoding location \(coordinates): \(error.localizedDescription)")
            }
        } else {
            print("Error creating reverse geocoding request")
        }
        return location
    }
    
    func forwardGeocode(address: String) async -> MKMapItem? {
        var location: MKMapItem? = nil
        
        if let request = MKGeocodingRequest(addressString: address) {
            do {
                let mapItems = try await request.mapItems
                location = mapItems.first
            } catch {
                print("Error geocoding location \(address): \(error.localizedDescription)")
            }
        } else {
            print("Error creating geocoding request")
        }
        return location
    }

    
}


